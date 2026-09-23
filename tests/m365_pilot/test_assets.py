"""Test generated native source. This is not an execution of Microsoft's engines."""
import csv
import io
import json
import runpy
import tempfile
import unittest
from itertools import product
from pathlib import Path
from typing import cast
from unittest.mock import patch

from scripts.build_m365_pilot import (
    AMBER,
    FIELDS,
    GREEN,
    LABELS,
    RED,
    UNAVAILABLE,
    assets,
    expression,
    fixtures,
    flow_expression,
    synchronize,
)


def evaluate(node: object, row: dict[str, str | int]) -> object:
    if isinstance(node, str) and node.startswith("[$"):
        return row.get(node[2:-1])
    if not isinstance(node, dict):
        return node
    data = cast(dict[str, object], node)
    args = cast(list[object], data["operands"])
    operator = data["operator"]
    if operator == "?":
        return evaluate(args[1] if evaluate(args[0], row) else args[2], row)
    values = [evaluate(arg, row) for arg in args]
    if operator == "&&":
        return all(values)
    if operator == "==":
        return values[0] == values[1]
    if operator == "!=":
        return values[0] != values[1]
    if operator == "<=":
        return cast(int, values[0]) <= cast(int, values[1])
    raise ValueError("Unsupported test expression")


class AssetTests(unittest.TestCase):
    def test_all_fixed_scenarios_have_independent_expected_results(self) -> None:
        tree = expression(dict(zip(LABELS, LABELS, strict=True)))
        for key, row in fixtures().items():
            with self.subTest(key=key):
                self.assertEqual(evaluate(tree, row), row["Assessment"])

    def test_exhaustive_preparation_states(self) -> None:
        tree = expression(dict(zip(LABELS, LABELS, strict=True)))
        for evidence, agent, human in product(
            ("complete", "missing", "unavailable", "unexpected"),
            ("clear", "not-enabled", "concern", "unavailable", "unexpected"),
            ("reviewed", "pending", "unexpected"),
        ):
            row = dict(fixtures()["SYNTHETIC-001"], EvidenceState=evidence,
                       AgentState=agent, HumanReview=human)
            result = evaluate(tree, row)
            if evidence == "missing":
                expected = RED
            elif agent == "concern":
                expected = AMBER
            elif evidence != "complete" or agent not in ("clear", "not-enabled"):
                expected = UNAVAILABLE
            elif human != "reviewed":
                expected = AMBER
            else:
                expected = GREEN
            self.assertEqual(result, expected)

    def test_stale_and_wrong_data_class_override_green(self) -> None:
        tree = expression(dict(zip(LABELS, LABELS, strict=True)))
        changes_to_test: tuple[dict[str, str | int], ...] = ({"DataClass": "LIVE"}, {"DataClass": ""}, {"CaseRevision": 0},
                        {"CaseRevision": -1}, {"CheckedRevision": 0}, {"CheckedRevision": 2})
        for changes in changes_to_test:
            row = dict(fixtures()["SYNTHETIC-001"], **changes)
            self.assertEqual(evaluate(tree, row), UNAVAILABLE)

    def test_missing_check_value_cannot_be_green(self) -> None:
        tree = expression(dict(zip(LABELS, LABELS, strict=True)))
        for field in ("DataClass", "CheckedRevision", "EvidenceState", "AgentState", "HumanReview"):
            row = dict(fixtures()["SYNTHETIC-001"])
            del row[field]
            self.assertNotEqual(evaluate(tree, row), GREEN)

    def test_csv_is_fixed_synthetic_data(self) -> None:
        rows = list(csv.DictReader(io.StringIO(assets()["cases.csv"])))
        self.assertEqual(len(rows), 8)
        self.assertEqual(tuple(rows[0]), FIELDS)
        self.assertTrue(all(row["DataClass"] == "SYNTHETIC" for row in rows))
        self.assertTrue(all(row["Title"].startswith("SYNTHETIC-") for row in rows))
        self.assertEqual(len({row["Profession"] for row in rows}), 5)
        self.assertTrue(all(row["Assessment"] == "SYNTHETIC - DISPLAY ONLY" for row in rows))

    def test_colour_and_text_have_same_semantics(self) -> None:
        formatting = json.loads(assets()["assessment.column.json"])
        expected = {UNAVAILABLE: "sp-field-severity--low", RED: "sp-field-severity--blocked",
                    AMBER: "sp-field-severity--warning", GREEN: "sp-field-severity--good"}
        for row in fixtures().values():
            self.assertEqual(evaluate(formatting["attributes"]["class"], row), expected[str(row["Assessment"])])
        self.assertIn("NOT VALID FOR PRACTICE", formatting["children"][1]["txtContent"])

    def test_flow_has_only_builtin_actions_and_known_fixture_input(self) -> None:
        flow = json.loads(assets()["preparation.definition.json"])
        self.assertEqual(flow["triggers"]["manual"]["kind"], "Button")
        self.assertEqual(flow["parameters"], {})
        self.assertEqual(flow["triggers"]["manual"]["inputs"]["schema"]["properties"]["text"]["enum"], list(fixtures()))
        blob = json.dumps(flow)
        for forbidden in ("OpenApiConnection", "HttpWebhook", "servicePrincipal", "shared_commondataserviceforapps"):
            self.assertNotIn(forbidden, blob)
        check = flow["actions"]["Check_fixture"]
        self.assertEqual(check["actions"]["Stop"]["type"], "Terminate")
        inner = check["else"]["actions"]
        self.assertEqual(inner["Preparation"]["inputs"], flow_expression())
        self.assertEqual(inner["Receipt"]["inputs"]["decisionAuthority"], "none")
        self.assertEqual(inner["Receipt"]["inputs"]["externalActions"], "none")
        self.assertIn("not-enabled", flow_expression())
        self.assertIn("not(equals(", flow_expression())
        self.assertIn("lessOrEquals(", flow_expression())

    def test_build_and_check_are_reproducible(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            synchronize(root, check=False)
            synchronize(root, check=True)
            synchronize(root, check=False)
            synchronize(root, check=True)

    def test_missing_and_modified_sources_fail(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaises(ValueError):
                synchronize(root, check=True)
            synchronize(root, check=False)
            (root / "pilot/m365/cases.csv").write_text("changed", encoding="utf-8")
            with self.assertRaises(ValueError):
                synchronize(root, check=True)

    def test_cli_checks_actual_tracked_assets(self) -> None:
        script = Path(__file__).resolve().parents[2] / "scripts/build_m365_pilot.py"
        with patch("sys.argv", [str(script)]):
            runpy.run_path(str(script), run_name="__main__")

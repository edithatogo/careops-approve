"""Build native synthetic Lists/Flow assets, not a tenant installer or decision engine."""
import csv
import io
import json
from pathlib import Path

# Every rule here is a synthetic rehearsal rule, not CHHHS clinical policy.
UNAVAILABLE = "Unavailable - verify inputs or check service"
RED = "Red - draft information request"
AMBER = "Amber - human review required"
GREEN = "Green - prepared, NOT approved"
LABELS = (UNAVAILABLE, RED, AMBER, GREEN)
FIELDS = ("Title", "DataClass", "Profession", "Facility", "CaseRevision", "CheckedRevision",
          "EvidenceState", "AgentState", "HumanReview", "Assessment")
# Earlier rules take precedence; other findings remain visible in their own columns.
RULES = (
    ("DataClass", "!=", "SYNTHETIC", UNAVAILABLE),
    ("CaseRevision", "<=", 0, UNAVAILABLE),
    ("CheckedRevision", "!=", "[$CaseRevision]", UNAVAILABLE),
    ("EvidenceState", "==", "missing", RED),
    ("AgentState", "==", "concern", AMBER),
    ("EvidenceState", "!=", "complete", UNAVAILABLE),
    ("AgentState", "outside", ("clear", "not-enabled"), UNAVAILABLE),
    ("HumanReview", "!=", "reviewed", AMBER),
)
# AgentState=clear is an explicitly SIMULATED result, never an actual agent run.
CASES = (
    ("SYNTHETIC-001", "Medical", "complete", "not-enabled", "reviewed", 1, 1, GREEN),
    ("SYNTHETIC-002", "Dental", "missing", "clear", "pending", 1, 1, RED),
    ("SYNTHETIC-003", "Nursing", "complete", "concern", "pending", 1, 1, AMBER),
    ("SYNTHETIC-004", "Midwifery", "unavailable", "clear", "pending", 1, 1, UNAVAILABLE),
    ("SYNTHETIC-005", "Allied health", "complete", "unavailable", "pending", 1, 1, UNAVAILABLE),
    ("SYNTHETIC-006", "Medical", "complete", "not-enabled", "pending", 1, 1, AMBER),
    ("SYNTHETIC-007", "Dental", "complete", "clear", "reviewed", 2, 1, UNAVAILABLE),
    ("SYNTHETIC-008", "Nursing", "missing", "concern", "pending", 1, 1, RED),
)


def fixtures() -> dict[str, dict[str, str | int]]:
    return {
        key: dict(zip(FIELDS, (key, "SYNTHETIC", profession, "SYNTHETIC-SITE",
                              revision, checked, evidence, agent, human, expected), strict=True))
        for key, profession, evidence, agent, human, revision, checked, expected in CASES
    }


def expression(mapping: dict[str, str]) -> object:
    """Native SharePoint AST; unknown values never fall through to green."""
    result: object = mapping[GREEN]
    for field, operator, value, label in reversed(RULES):
        predicate = ({"operator": "&&", "operands": [
            {"operator": "!=", "operands": [f"[${field}]", item]} for item in value
        ]} if isinstance(value, tuple) else {"operator": operator, "operands": [f"[${field}]", value]})
        result = {"operator": "?", "operands": [predicate, mapping[label], result]}
    return result


def flow_expression() -> str:
    """The same predicates expressed as native Workflow Definition Language."""
    result = f"'{GREEN}'"
    for field, operator, value, label in reversed(RULES):
        left = f"outputs('Fixture')?['{field}']"
        if isinstance(value, tuple):
            predicate = "and(" + ",".join(f"not(equals({left},'{item}'))" for item in value) + ")"
            result = f"if({predicate},'{label}',{result})"
            continue
        right = (f"outputs('Fixture')?['{value[2:-1]}']" if isinstance(value, str)
                 and value.startswith("[$") else json.dumps(value) if isinstance(value, int)
                 else "'" + value + "'")
        predicate = f"lessOrEquals({left},{right})" if operator == "<=" else f"equals({left},{right})"
        if operator == "!=":
            predicate = f"not({predicate})"
        result = f"if({predicate},'{label}',{result})"
    return "@" + result


def assets() -> dict[str, str]:
    cases = fixtures()
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=FIELDS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(dict(row, Assessment="SYNTHETIC - DISPLAY ONLY") for row in cases.values())
    formatting = {
        "$schema": "https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json",
        "elmType": "div", "style": {"display": "flex", "flex-direction": "column", "padding": "4px"},
        "attributes": {"class": expression({
            UNAVAILABLE: "sp-field-severity--low", RED: "sp-field-severity--blocked",
            AMBER: "sp-field-severity--warning", GREEN: "sp-field-severity--good",
        })},
        "children": [
            {"elmType": "span", "txtContent": expression(dict(zip(LABELS, LABELS, strict=True)))},
            {"elmType": "span", "txtContent": "SYNTHETIC PILOT | NOT VALID FOR PRACTICE"},
        ],
    }
    flow = {
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "contentVersion": "1.0.0.0", "parameters": {},
        "triggers": {"manual": {"type": "Request", "kind": "Button", "inputs": {"schema": {
            "type": "object", "properties": {"text": {"title": "Synthetic fixture", "type": "string",
                                                         "enum": list(cases)}}, "required": ["text"],
        }}}},
        "actions": {
            "Cases": {"type": "Compose", "inputs": cases, "runAfter": {}},
            "Fixture": {"type": "Compose", "inputs": "@outputs('Cases')?[triggerBody()?['text']]",
                        "runAfter": {"Cases": ["Succeeded"]}},
            "Check_fixture": {"type": "If", "expression": {"equals": ["@empty(outputs('Fixture'))", True]},
                              "runAfter": {"Fixture": ["Succeeded"]},
                              "actions": {"Stop": {"type": "Terminate", "inputs": {"runStatus": "Failed",
                                          "runError": {"code": "UnsupportedSyntheticFixture", "message": "Select a supplied synthetic fixture."}}}},
                              "else": {"actions": {
                                  "Preparation": {"type": "Compose", "inputs": flow_expression(), "runAfter": {}},
                                  "Receipt": {"type": "Compose", "runAfter": {"Preparation": ["Succeeded"]},
                                              "inputs": {"preparation": "@outputs('Preparation')",
                                                         "decisionAuthority": "none", "agentExecution": "simulated-or-disabled",
                                                         "externalActions": "none", "dataClass": "SYNTHETIC"}},
                              }}},
        }, "outputs": {},
    }
    return {"cases.csv": stream.getvalue(),
            "assessment.column.json": json.dumps(formatting, separators=(",", ":")) + "\n",
            "preparation.definition.json": json.dumps(flow, separators=(",", ":")) + "\n"}


def synchronize(root: Path, *, check: bool) -> None:
    """Generate source assets or reject drift; never call a tenant or use case data."""
    target = root / "pilot" / "m365"
    for name, content in assets().items():
        path = target / name
        if check:
            if not path.is_file() or path.read_text(encoding="utf-8") != content:
                raise ValueError(f"Pilot source drift: {name}")
        else:
            target.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true", help="Regenerate synthetic assets; default checks")
    args = parser.parse_args()
    synchronize(Path(__file__).resolve().parents[1], check=not args.build)

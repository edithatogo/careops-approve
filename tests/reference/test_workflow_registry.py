"""Behavioural tests for the workflow registry lifecycle."""
import unittest
from dataclasses import replace

from reference.workflow_compiler import definition_hash
from reference.workflow_registry import (
    PublicationRequest,
    VersionState,
    WorkflowRegistry,
    WorkflowVersionRecord,
)


def definition(version: str = "1.0.0", *, status: str = "draft") -> dict[str, object]:
    return {
        "workflowId": "generic.review",
        "version": version,
        "status": status,
        "displayName": "Generic review",
        "entryNodeId": "intake",
        "nodes": [
            {
                "id": "intake",
                "type": "input",
                "displayName": "Intake",
                "config": {"inputContract": "request.v1"},
            },
            {
                "id": "review",
                "type": "human_review",
                "displayName": "Review",
                "config": {"assignedRole": "reviewer"},
            },
            {
                "id": "done",
                "type": "end",
                "displayName": "Done",
                "config": {"outcome": "complete"},
            },
        ],
        "transitions": [
            {"from": "intake", "to": "review"},
            {"from": "review", "to": "done"},
        ],
    }


def request(
    stored_definition: dict[str, object],
    *,
    action: str = "publish",
    supersedes: str = "",
    governance: str = "approved",
    validation: str = "passed",
    tests: str = "passed",
    migration: str = "no-running-case-migration",
) -> PublicationRequest:
    return PublicationRequest(
        workflow_id="generic.review",
        version=str(stored_definition["version"]),
        definition_hash=definition_hash(stored_definition),
        requested_by_role="workflow-admin",
        validation_status=validation,
        test_status=tests,
        governance_status=governance,
        requested_action=action,
        migration_policy=migration,
        supersedes_version=supersedes,
    )


class WorkflowRegistryTest(unittest.TestCase):
    def test_create_update_and_read_draft_with_optimistic_concurrency(self) -> None:
        registry = WorkflowRegistry()
        first = registry.save_draft(definition())
        self.assertEqual(first.state, VersionState.DRAFT)
        self.assertEqual(first.revision, 1)
        self.assertTrue(first.etag.startswith('"1-'))

        changed = definition()
        changed["displayName"] = "Changed"
        second = registry.save_draft(changed, expected_etag=first.etag)
        self.assertEqual(second.revision, 2)
        self.assertNotEqual(second.etag, first.etag)
        self.assertEqual(registry.get("generic.review", "1.0.0").definition["displayName"], "Changed")

        with self.assertRaisesRegex(ValueError, "ETag"):
            registry.save_draft(definition(), expected_etag=first.etag)

    def test_new_draft_rejects_etag_and_non_draft_status(self) -> None:
        registry = WorkflowRegistry()
        with self.assertRaisesRegex(ValueError, "new draft"):
            registry.save_draft(definition(), expected_etag='"stale"')
        with self.assertRaisesRegex(ValueError, "Only draft"):
            registry.save_draft(definition(status="active"))

    def test_definition_identity_is_required(self) -> None:
        registry = WorkflowRegistry()
        for field, value in [("workflowId", ""), ("workflowId", 1), ("version", ""), ("version", None)]:
            candidate = definition()
            candidate[field] = value
            with self.subTest(field=field, value=value):
                with self.assertRaises(ValueError):
                    registry.save_draft(candidate)

    def test_missing_record_and_list_validation(self) -> None:
        registry = WorkflowRegistry()
        with self.assertRaises(KeyError):
            registry.get("generic.review", "1.0.0")
        with self.assertRaisesRegex(ValueError, "workflowId"):
            registry.list_versions(" ")

    def test_list_versions_is_sorted_and_returns_copies(self) -> None:
        registry = WorkflowRegistry()
        registry.save_draft(definition("2.0.0"))
        registry.save_draft(definition("1.0.0"))
        values = registry.list_versions("generic.review")
        self.assertEqual([value.version for value in values], ["1.0.0", "2.0.0"])
        values[0].definition["displayName"] = "mutated outside"
        self.assertEqual(
            registry.get("generic.review", "1.0.0").definition["displayName"],
            "Generic review",
        )

    def test_publish_activates_immutable_version(self) -> None:
        registry = WorkflowRegistry()
        draft = registry.save_draft(definition())
        published = registry.publish(request(draft.definition))
        self.assertEqual(published.state, VersionState.ACTIVE)
        self.assertEqual(published.definition["status"], "active")
        self.assertEqual(published.revision, 2)
        self.assertNotEqual(published.definition_hash, draft.definition_hash)

        with self.assertRaisesRegex(ValueError, "immutable"):
            registry.save_draft(definition(), expected_etag=published.etag)
        with self.assertRaisesRegex(ValueError, "Only a draft"):
            registry.publish(request(published.definition))

    def test_publication_hash_must_match_stored_draft(self) -> None:
        registry = WorkflowRegistry()
        draft = registry.save_draft(definition())
        mismatched = replace(request(draft.definition), definition_hash="sha256:" + ("0" * 64))
        with self.assertRaisesRegex(ValueError, "hash"):
            registry.publish(mismatched)

    def test_publication_semantics_must_compile(self) -> None:
        registry = WorkflowRegistry()
        reserved = definition()
        nodes = list(reserved["nodes"])  # type: ignore[call-overload]
        nodes[1] = {
            "id": "review",
            "type": "handoff",
            "displayName": "Handoff",
            "config": {"target": "external"},
        }
        reserved["nodes"] = nodes
        draft = registry.save_draft(reserved)
        with self.assertRaisesRegex(ValueError, "reserved"):
            registry.publish(request(draft.definition))

    def test_replacement_requires_explicit_supersedes_and_retires_prior(self) -> None:
        registry = WorkflowRegistry()
        first = registry.save_draft(definition("1.0.0"))
        registry.publish(request(first.definition))

        second = registry.save_draft(definition("2.0.0"))
        with self.assertRaisesRegex(ValueError, "supersedesVersion"):
            registry.publish(request(second.definition))

        wrong = request(second.definition, supersedes="0.9.0")
        with self.assertRaisesRegex(ValueError, "supersedesVersion"):
            registry.publish(wrong)

        published = registry.publish(request(second.definition, supersedes="1.0.0"))
        self.assertEqual(published.state, VersionState.ACTIVE)
        prior = registry.get("generic.review", "1.0.0")
        self.assertEqual(prior.state, VersionState.RETIRED)
        self.assertEqual(prior.definition["status"], "retired")

    def test_supersedes_without_active_version_is_rejected(self) -> None:
        registry = WorkflowRegistry()
        draft = registry.save_draft(definition("2.0.0"))
        with self.assertRaisesRegex(ValueError, "no active"):
            registry.publish(request(draft.definition, supersedes="1.0.0"))

    def test_retire_active_version(self) -> None:
        registry = WorkflowRegistry()
        draft = registry.save_draft(definition())
        active = registry.publish(request(draft.definition))
        retired = registry.retire(request(active.definition, action="retire"))
        self.assertEqual(retired.state, VersionState.RETIRED)
        self.assertEqual(retired.definition["status"], "retired")

        with self.assertRaisesRegex(ValueError, "Only an active"):
            registry.retire(request(retired.definition, action="retire"))

    def test_retirement_guards(self) -> None:
        registry = WorkflowRegistry()
        with self.assertRaises(KeyError):
            registry.retire(request(definition(), action="retire"))

        draft = registry.save_draft(definition())
        with self.assertRaisesRegex(ValueError, "Only an active"):
            registry.retire(request(draft.definition, action="retire"))

        active = registry.publish(request(draft.definition))
        bad_hash = replace(
            request(active.definition, action="retire"),
            definition_hash="sha256:" + ("f" * 64),
        )
        with self.assertRaisesRegex(ValueError, "hash"):
            registry.retire(bad_hash)

        with self.assertRaisesRegex(ValueError, "cannot supersede"):
            registry.retire(
                request(active.definition, action="retire", supersedes="0.9.0")
            )

    def test_publication_request_evidence_is_fail_closed(self) -> None:
        registry = WorkflowRegistry()
        draft = registry.save_draft(definition())
        base = request(draft.definition)
        invalid = [
            replace(base, requested_action="retire"),
            replace(base, workflow_id=""),
            replace(base, version=""),
            replace(base, definition_hash="bad"),
            replace(base, requested_by_role=""),
            replace(base, validation_status="failed"),
            replace(base, test_status="failed"),
            replace(base, governance_status="pending"),
            replace(base, migration_policy="implicit"),
        ]
        for item in invalid:
            with self.subTest(item=item):
                with self.assertRaises(ValueError):
                    registry.publish(item)

        retire_base = replace(base, requested_action="publish")
        with self.assertRaisesRegex(ValueError, "retire"):
            registry._validate_request(retire_base, action="retire")

    def test_not_required_governance_is_accepted_by_registry_contract(self) -> None:
        registry = WorkflowRegistry()
        draft = registry.save_draft(definition())
        published = registry.publish(request(draft.definition, governance="not-required"))
        self.assertEqual(published.state, VersionState.ACTIVE)

    def test_multiple_active_versions_trip_registry_invariant(self) -> None:
        registry = WorkflowRegistry()
        first = registry.save_draft(definition("1.0.0"))
        active = registry.publish(request(first.definition))
        second_definition = definition("2.0.0", status="active")
        digest = definition_hash(second_definition)
        registry._records[("generic.review", "2.0.0")] = WorkflowVersionRecord(
            "generic.review",
            "2.0.0",
            VersionState.ACTIVE,
            digest,
            '"1-0123456789abcdef"',
            1,
            second_definition,
        )
        third = registry.save_draft(definition("3.0.0"))
        with self.assertRaisesRegex(RuntimeError, "multiple active"):
            registry.publish(request(third.definition))
        self.assertEqual(active.state, VersionState.ACTIVE)

    def test_etag_helper_is_reached_through_valid_and_invalid_paths(self) -> None:
        registry = WorkflowRegistry()
        first = registry.save_draft(definition())
        self.assertIn("-", first.etag)


if __name__ == "__main__":
    unittest.main()

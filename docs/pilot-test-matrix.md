# Pilot test matrix

| ID | Scenario | Expected result | Repo evidence |
| --- | --- | --- | --- |
| P-01 | Valid submission | One request ID, one immutable approver assignment | workflow scenarios |
| P-02 | Invalid request | No approval created; actionable validation state | request contract |
| P-03 | Empty/duplicate approver configuration | Submission preserved; owner alert; no approval | approver-resolution contract |
| P-04 | Approve | Immutable approved outcome; Teams/SharePoint status update | decision scenarios |
| P-05 | Reject without comment | Finalization refused | decision scenarios |
| P-06 | Reject with comment | Immutable rejected outcome | decision scenarios |
| P-07 | Duplicate response | First final outcome retained | decision scenarios |
| P-08 | Pending for 14 days | EDMS approval created without email | TESL blueprint |
| P-09 | Urgent verbal delegation | Delegation record and owner notification | role/template contracts |
| P-10 | Approver changed after submission | Existing assignment unchanged | administration scenarios |
| P-11 | Approved intranet execution | Desktop stage invoked only after approval | desktop boundary contract |

P-01 through P-10 require tenant execution for live evidence. P-11 additionally
requires an approved desktop machine or gateway.

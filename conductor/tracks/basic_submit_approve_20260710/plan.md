# Implementation Plan: Configurable Basic Submit and Approve Workflow

## Phase 1: Tenant Fit and Solution Contract

- [~] Task: Confirm the permitted Microsoft 365 environment and governance envelope
    - [ ] Verify Teams Approvals availability, standard connector licensing, DLP policy, and Dataverse provisioning state
    - [ ] Confirm the pilot data classification, retention expectation, and authorised workflow owners
    - [x] Record external blockers without embedding tenant identifiers or credentials
- [ ] Task: Define the solution contract and configuration schema
    - [ ] Write validation fixtures for request, outcome, and approver configuration records
    - [ ] Define required fields, statuses, immutable audit fields, and owner permissions
    - [ ] Define prospective approver-change behaviour and failure handling
- [ ] Task: Evaluate Microsoft kits and frontier capabilities
    - [ ] Assess Business Approvals Kit dependencies, licensing, DLP compatibility, and proportionality for the basic workflow
    - [ ] Assess Microsoft Graph Approvals APIs and Power Apps Test Engine preview in an isolated environment
    - [ ] Record adopt, trial, watch, or reject decisions with stable fallbacks and review dates
- [ ] Task: Conductor - User Manual Verification 'Tenant Fit and Solution Contract' (Protocol in workflow.md)

## Phase 2: Source-Controlled Power Platform Foundation

- [ ] Task: Establish solution-aware source artifacts
    - [ ] Write checks for expected solution structure, connection references, and environment variables
    - [ ] Create or import the unpacked CareOps Approve solution structure
    - [ ] Document export, unpack, pack, and validation commands
- [ ] Task: Establish GitHub and GitHub Enterprise ALM automation
    - [ ] Add Microsoft Power Platform GitHub Actions for validation, packing, checker analysis, and protected deployment
    - [ ] Configure Dependabot monitoring for action updates and require review before adopting new major versions
    - [x] Configure dual GitHub CLI authentication for `nswhealth.ghe.com` and `github.com`
    - [x] Configure NSW Health GHE as `origin` and the private personal repository as `github`
    - [x] Set `main` to track GHE `origin/main` and publish current branches and tags to both hosts
    - [x] Document host inference, explicit host targeting, token precedence, and Git credential routing
    - [x] Document non-Git controls and the governed future transition to personal-primary authority
    - [x] Verify personal GitHub Actions validation passes against the dual-published commit
    - [x] Record the GHE hosted-runner policy failure and absence of a repository self-hosted runner
    - [ ] Obtain an approved GHE runner or hosted-runner entitlement for repository-native validation
    - [ ] Verify equivalent repository rules, Actions policy, environments, and protected secrets on both hosts
    - [ ] Verify branches and tags continue to publish to both remotes without destructive mirror deletion
- [ ] Task: Establish governed Power Platform Pipelines promotion
    - [ ] Define development, test or pilot, and production stages with environment-specific deployment settings
    - [ ] Prefer service-principal delegated deployment and protected environment approvals where tenant policy permits
    - [ ] Document the fallback GitHub Actions deployment path when Pipelines cannot be provisioned
- [ ] Task: Create SharePoint data contracts
    - [ ] Write checks for submission, outcome, and approver configuration list definitions
    - [ ] Define least-privilege list permissions and owner configuration access
    - [ ] Add deployment documentation without tenant-specific URLs
- [ ] Task: Conductor - User Manual Verification 'Source-Controlled Power Platform Foundation' (Protocol in workflow.md)

## Phase 3: Submit and Approve Flow

- [ ] Task: Implement validated request submission
    - [ ] Write tests for required fields, unique IDs, initial status, and invalid submissions
    - [ ] Create the Teams-accessible submission trigger and persistence actions
    - [ ] Confirm requester acknowledgement contains request ID and resolved approver
- [ ] Task: Implement configurable approver resolution
    - [ ] Write tests for primary approver, fallback, inactive entries, duplicate entries, and empty configuration
    - [ ] Resolve approvers from configuration rather than hard-coded identities
    - [ ] Alert owners and preserve the request when configuration is invalid
- [ ] Task: Implement Teams approval and finalization
    - [ ] Write tests for approve, reject, duplicate response, cancellation, and connector failure paths
    - [ ] Create the Approve/Reject request and require rejection comments
    - [ ] Persist the immutable assigned approver and final outcome
    - [ ] Notify the requester of the decision or actionable failure
- [ ] Task: Conductor - User Manual Verification 'Submit and Approve Flow' (Protocol in workflow.md)

## Phase 4: Administration, Deployment, and Pilot

- [ ] Task: Implement controlled approver administration
    - [ ] Write permission and prospective-change validation scenarios
    - [ ] Provide an owner procedure to add, replace, deactivate, and reorder approvers
    - [ ] Verify existing approvals remain assigned to their original approver
- [ ] Task: Complete deployment and support runbooks
    - [ ] Document prerequisites, connection ownership, deployment, rollback, and recovery
    - [ ] Document cancellation and manual handling of an unavailable approver
    - [ ] Include governance boundaries and evidence required for wider adoption
- [ ] Task: Execute the two-person pilot
    - [ ] Deploy to the approved non-production or pilot environment
    - [ ] Test submission, approval, rejection, invalid configuration, and approver change end to end
    - [ ] Record results, residual blockers, and the decision on further rollout
- [ ] Task: Conductor - User Manual Verification 'Administration, Deployment, and Pilot' (Protocol in workflow.md)

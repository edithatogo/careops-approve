# CI qualification and promotion

Required CI retains the repository/harness, full-coverage Python and offline
Power Platform package checks. Shared source security is called at immutable
CareOps revision 3712b88f438b046e68fe37d8db2f4b6a4387b473. Actions and trusted
helpers must remain pinned to reviewed commits; no inherited tenant secrets.

`lock-refresh.yml` automatically regenerates the exact-pinned, hash-locked CI
dependencies when their declarations change. It installs the candidate, runs the
existing Python checks and retains a lock, digest receipt and patch. The source
owner applies the generated patch to the same update branch and verifies all
current-head checks before merge. An artifact is a repair candidate, not an
applied update. Do not bypass checks or add a privileged PR-code workflow to
write patches. Dependabot owns weekly Actions updates; Renovate owns Python
requirement proposals, including prereleases, without automatic merging.

`development-canary.yml` runs weekly, on relevant CI pull requests and manually.
Its tool candidate resolves current prereleases into a separate hash lock,
installs them and runs the same strict quality/full-coverage gates. CPython
preview discovery records the exact upstream manifest revision and digest;
missing runnable previews remain unavailable with tests skipped. There is no
silent downgrade to a preview older than the qualified Python 3.15 baseline.

The separate SDK lane reads Microsoft's .NET 11 release metadata, selects only a
published preview, records the metadata digest and installs the exact SDK. It
uses PAC 2.13.1 to pack the existing solution source without login. The .NET 10
runtime needed by PAC is installed alongside the development SDK; this proves
offline packaging under the selected SDK, not a port of PAC to the .NET 11
runtime. Missing previews skip packaging; setup and executed failures remain
visible. Package SHA256/version evidence is retained even when later steps fail.

Promotion requires a source PR carrying the exact qualified versions and generated
lock, all required current-head checks, and post-merge readback. Download candidate
artifacts and verify receipt digests before applying them. Canaries never edit
working locks, deploy, authenticate, notify or promote by themselves. If a
candidate fails, retain the evidence and current qualified pins; correct the
specific cause or wait for a new candidate. Reverting a source pin is separate
from native rollback. Source packages, signatures and offline interface proofs
do not establish native operation or operator acceptance.

PR #74 qualified the initial adoption at da07812a25cfb71523cad3ad9b8da8e65c2eaac4.
All eleven PR checks passed, including PAC packaging. Main protection readback
confirmed ten unfiltered app-bound required checks, administrator enforcement,
strict branch freshness, and preserved no-force/no-delete/conversation controls.
The path-filtered credentialing check is retained but is not required globally.

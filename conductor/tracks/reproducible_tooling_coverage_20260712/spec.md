# Specification

Pin the no-admin PAC/PACX toolchain in a tenant-neutral manifest, provide a
repeatable user-local installer, and measure repository control coverage without
claiming that static validation proves tenant execution.

The harness must fail when the manifest is malformed, when a coverage control
has no validation path, or when repository control coverage falls below 90%.
Tenant authentication, pilot execution, live flow state, and intranet gateway
availability remain explicitly outstanding external evidence.

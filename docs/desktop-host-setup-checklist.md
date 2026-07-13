# Desktop host setup checklist

The current laptop is not the intended execution host. The future desktop can
be registered as the local Power Automate for desktop machine after the host is
available tomorrow.

## Before registration

- Confirm the desktop is an approved NSW Health device and is connected to the
  approved network or VPN required by the intranet.
- Install or update Power Automate for desktop using the organisation-approved
  software path.
- Sign in with the approved work account; do not store passwords or tokens in
  this repository.
- Confirm the intranet application opens manually from the desktop.

## Registration and configuration

- Register the desktop in the approved Power Automate environment as a machine
  or machine group.
- Use a neutral machine/group reference in the deployment settings; do not
  commit the device name, URL, credentials, or connection identifiers.
- Bind the desktop-flow connection outside source control.
- Keep the desktop stage disabled until owner approval and a successful smoke
  test are recorded.

## Smoke test and release gate

- Run only a synthetic approved request with no confidential payload.
- Verify an unapproved, rejected, duplicate, and failed request cannot invoke
  the desktop stage.
- Verify the request ID is the idempotency key and the run state is persisted.
- Verify failure produces an owner-visible Teams alert without email.
- Record sanitized evidence in the tenant pilot evidence package.
- Enable the stage only after rollback and owner-review procedures pass.

The laptop remains a development and browser-control workstation; it is not a
registered intranet execution host.

# Light Workflow managed configuration operations

`publish-current-snapshot.sh` creates a Config Server snapshot from the
reviewed Portal properties, makes it current for the loc Light Workflow
instance, and prints both the new and previous snapshot IDs. It does not
request a runtime refresh automatically.

For a reloadable-only publication, open the running Light Workflow instance in
Portal's Control Pane, select **Modules**, select only
`light-workflow/runtime-config`, and invoke **Reload**. The controller request
fetches the current snapshot and cannot carry arbitrary property bodies.

Restore a previously reviewed snapshot with:

```bash
./rollback-current-snapshot.sh <previous-snapshot-id>
```

Then reload the same single module. If Portal review shows a restart-required
property, restore the snapshot and restart `light-workflow` instead. Set
`LIGHT_WORKFLOW_SNAPSHOT_DRY_RUN=true` to validate either transaction without
committing it. A rejected refresh leaves the previous runtime generation
active.

## Workflow LONG binding qualification

`long-binding-test.env` records the public local-development OAuth client used
by the LONG binding UI test. Source it to select the local client explicitly
instead of relying on defaults in the test repository. The client must already
be active in Portal; this file does not register a client or change the managed
Workflow runtime configuration.

Export `WORKFLOW_LONG_E2E_EMAIL` and `WORKFLOW_LONG_E2E_PASSWORD` for the local
Portal UI account, then run from the `portal-config-loc` repository root:

```bash
set -a
source all-in-lt/light-workflow-rust/long-binding-test.env
set +a
npm --prefix ../light-portal-test run test:workflow-long-binding
```

The environment file clears `WORKFLOW_LONG_AUTH_STATE_FILE` so this test signs
in through the browser. Reusing a session-state file also gives Playwright's
API request fixture SPA cookies, which can interfere with the issuer requests'
Basic authentication and cause a misleading registration 401.

The test creates its own binding, activates and exchanges it, deletes it through
Portal, and checks exchange rejection and idempotent late-close acknowledgement.

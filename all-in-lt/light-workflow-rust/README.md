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

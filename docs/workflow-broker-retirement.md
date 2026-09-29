# Workflow broker retirement

The broker provisioning assets and six issuer broker tables are retired. Shared
OAuth refresh claim sources and both LONG binding tables remain required.

The complete `init.sql` artifacts for all-in-lt, all-in-pg and all-in-one are
assembled from `portal-db/postgres/ddl.sql` and `init-lightapi.sql`, retaining
the `CREATE DATABASE configserver;` and `\c configserver;` prefix. Regenerate
with `scripts/generate-postgres-init.py` (`--installer` also updates the sibling
light-portal-install). It accepts only the current canonical schema or the
any schema revision in portal-db's reachable `ddl.sql` history as a previous baseline, checks the complete schema and
seed sections, and validates every destination before writing any file. Unknown
distribution-specific schema or seed changes require review and are not overwritten.
`--check` verifies the installer artifact as well as the three local distributions.

Deployment and cleanup are user-run. Deploy the broker-free light-oauth before
applying `patch_20260928_04_retire_workflow_broker.sql` to an existing application
database, or initialize clean volumes using the regenerated artifacts. On an
existing database, apply that retirement patch **before** rerunning
`schema/cascade-runtime.generated.sql` or any schema-script synchronization that
installs it. The new policy inventory omits the retired relationship, so validation
correctly fails while its old foreign key still exists; the failed transaction
rolls back. After the drop, the new runtime installer is safe to replay.

Merge portal-db to master before merging light-portal: light-portal CI checks out
portal-db master. Passing tests against an uncommitted sibling checkout does not
qualify that merge boundary. Recheck CI against the merged schema. Build
and deploy the new hybrid-query and hybrid-command images together. Verify the
refresh grant, LONG register/close, and a global snapshot export/import round trip.
If a new hybrid image starts before the retirement patch, snapshot export fails
with `Workflow broker retirement patch must run before snapshot export` when it
discovers a retired table. Apply the patch before treating that failure as an
export defect.
For each distribution, verify a clean-volume initialization and cascade validation.
The same retirement applies to light-portal-install. Before updating an existing
installer database, use the original plan's client-registration preflight and
deactivate any retired provisioning client through the Portal UI or recreate the
database. Removing source assets does not remove an existing client registration.
The deleted broker event bundle may also have left `workflow.credentialBroker`
configuration in a preserved Portal database. Check its property, product-version
mapping, and Workflow instance value without displaying the value itself:

```sql
SELECT p.property_id, p.active AS property_active,
       (SELECT count(*) FROM product_version_config_property_t m
        WHERE m.property_id = p.property_id AND m.active) AS active_product_mappings,
       (SELECT count(*) FROM instance_property_t i
        WHERE i.property_id = p.property_id AND i.active) AS active_instance_values
FROM config_property_t p
WHERE p.property_name = 'credentialBroker';
```

If any active broker configuration remains, deactivate its instance value,
product mapping, and catalog property through Portal commands/UI and publish a
new Workflow snapshot. Do not delete projection rows with SQL. Recheck the
effective Workflow configuration after publication; source retirement alone
does not change an existing configserver.

The private `all-in-lt/workflow-broker/.runtime/` directory is deliberately left
untouched by source retirement and remains ignored by the generic `.runtime`
rule. The user may delete that retired directory after confirming it is no longer
needed. Shared volumes and other runtime material must not be removed as part of
source regeneration or qualification.

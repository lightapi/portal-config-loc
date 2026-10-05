# Reviewed operational bundle 2.7.0

The current local deployment contract is exactly bundle 2.7.0, with 45 ordered
migrations. `bundle_contract.py` pins manifest, order and checksum identities;
the staged W7 verifier additionally pins assets and tools. Arbitrary newer
versions, changed historical SQL and partial bundles are refused.

Use the candidate Fabric repository's supported synchronization helper:

```sh
rtk proxy python3 -B crates/operational-store/deployment/sync-operational-release.py \
  --source crates/operational-store/release \
  --destination /absolute/path/to/all-in-lt/postgres-db/operations
rtk proxy python3 -B crates/operational-store/deployment/sync-operational-release.py \
  --source crates/operational-store/release \
  --destination /absolute/path/to/all-in-lt/postgres-db/operations --check
```

Synchronizing assets does not apply migrations or create readiness. For an
existing supported local `local-fresh-operational-off` installation with the
exact reviewed 44-entry 2.6.0 ledger, take verified catalog and operational
backups and exclude external schema/admission writers. Then use the local
bounded upgrade helper from this config checkout:

```sh
rtk proxy python3 -B scripts/prepare-local-operational-bundle.py \
  --state /absolute/path/to/all-in-lt/postgres-db/operations/.runtime/w7/prepared.json
rtk proxy python3 -B scripts/check-local-fresh-start.py \
  --state /absolute/path/to/all-in-lt/postgres-db/operations/.runtime/w7/prepared.json
rtk proxy bash all-in-lt/postgres-db/operations/bin/w7-startup-guard.sh \
  /absolute/path/to/all-in-lt/postgres-db/operations
```

The helper locks W7 preparation, checks all three database identities, OIDs,
the exact baseline or complete ledger, backup reference, catalog prerequisite
patches, ownership, runtime ACLs and admission OFF before applying only order
45. Repeated preparation performs readbacks and applies no migration. It
preserves credentials and the original preparation record; readiness is
invalidated during preparation and regenerated only after full readback.
It never enables admission. Normal startup requires the complete 45-entry
ledger. Do not run broad bootstrap on a populated live installation as an
upgrade shortcut; it also manages service credentials and bindings.

Fresh initialization retains the existing explicitly authorized, empty-three-
database `E04_LOCAL_FRESH_INIT=true` path; its bundle version is now 2.7.0.
General W7 preparation retains qualification references and all admission and
ownership gates. Operational references now require snapshots for stages
0 through 3, including migration 45; historical E04 references are immutable
and cannot authorize this new bundle. This local feature qualification is not
profile-wide E04 activation qualification.

Disposable fresh/upgrade/repeat qualification:

```sh
rtk proxy python3 -B scripts/qualify-operational-bundle.py \
  --baseline /absolute/path/to/retained-reviewed-2.6.0-operations \
  --output /absolute/path/to/new-additive-evidence
```

This creates only labelled network-isolated fixtures, exercises the real
bootstrap/prepare/validator/startup tools, uses a synthetic catalog guard
fixture, and removes owned containers and anonymous volumes. Record fixture
results separately from live state and Portal database test results. Portal
ordinary build remains `rtk proxy mvn -T 1C clean install`; its seven opt-in
database skips are not qualification passes. The mandatory seven-test command
and missing-fixture failure command remain in Portal's
`scripts/host-tool-workflow-access-qualification.md`.

Historical 2.6.0 identities/tools are retained under `contracts/2.6.0` for
evidence and baseline identification. No old binary/helper compatibility with
the upgraded schema is claimed. Rollback is forward: retain migrations and
upgraded consumers/recovery workers, publish disabled Tool policies/tombstones
through supported admin commands, and preserve accepted runs and request
history. After v7 events or broad acceptance, full binary downgrade is
unsupported. Before live changes use the reviewed feature `ROLLOUT.md` for
the bounded rollback and coordinated catalog/operational backup requirements.

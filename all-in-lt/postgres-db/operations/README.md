# Operational Store Assets

`bin/` and `bundle/` are byte-identical copies of the canonical versioned assets
from `light-fabric/crates/operational-store`. Do not edit staged SQL here.
Regenerate the deployment bundle from the owning crate and pass the
cross-repository parity and lifecycle gates instead.

Phase 7 also stages `operational-store-provisioner.sh`,
`provision-dev-dedicated.sh`, and `rotate-dev-dedicated-credentials.sh` from
the owning crate. Run the provisioner as a separate privileged process, not in
the PostgreSQL entrypoint and not in the Host command request. It requires
permission-restricted Portal URL/token files, an existing Docker network, and
an external binding-secret root. Only `DEV_DEDICATED` is enabled; deactivation
and decommission stop the binding container while preserving its data volume.

`scripts/deploy-local.sh lt` supervises this privileged worker as an isolated
Compose service as soon as the base stack is up. Its bind mounts use the same
absolute paths inside the worker and on the host so the development provider's
nested `docker run` mounts resolve correctly. Put a permission-restricted,
client-credentials service token containing the
`operational-store-provisioner` role and an `actor_user_id` claim naming an
active Portal user UUID at
`.release-state/operational-store-provisioner-token`, or override
`OPERATIONAL_PROVISIONER_TOKEN_FILE`. The deployment remains usable and logs a
warning when the token is absent, but requested bindings remain pending until
the worker is started.

For the bootstrap `dev.lightapi.net` Host, the provisioner adopts the existing
Compose `postgres` container and validates its exact binding, Host, environment,
and digest metadata. It does not create a second database or replace the
deployment-owned secrets already mounted by the bootstrap runtimes. All other
Host/environment bindings continue through the dedicated-container path.

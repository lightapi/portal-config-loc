# Local Compose quickstart

From `/home/steve/workspace/portal-config-loc`:

```sh
./scripts/deploy-local.sh lt
```

This ensures the initialized local stack is running. It uses the existing release
environment followed by `~/.config/lightapi/light-portal.env`, retaining private
runner/action configuration. It checks locally selected image IDs, successful
initialization one-shots, schema, backup, protected definitions, restricted policy
ACLs, TLS endpoints and native-runner readiness. Healthy unchanged services are
untouched; stopped existing containers start in dependency order. Rebuilt local
application tags are applied only to services whose image ID changed, retaining
their volumes and completed initialization. No build, pull, event
replay, password rotation, migration application or v2 activation occurs.

Check status and follow logs:

```sh
./scripts/deploy-local.sh lt status
./scripts/deploy-local.sh lt logs
```

To deliberately stop applications while retaining initialized containers,
successful one-shots and volumes:

```sh
./scripts/deploy-local.sh lt stop
./scripts/deploy-local.sh lt
```

Stop/status/logs derive the existing readiness identity automatically; no W7
variables are required. Local stop uses Compose `stop`, not `down`.

No additional one-time setup is required for this completed installation.
Keep its private environment/configuration, initialized containers, volumes,
local images, prepared initialization record and verified backup. A missing or
conflicting prerequisite produces a specific error; startup does not repair or
reinitialize databases. A changed PostgreSQL image requires separate database
compatibility review; application rebuilds do not. Historical migration qualification is separate.

Starting and restarting are different actions. The startup command never
recreates unchanged running containers. It applies rebuilt application images
selected by the existing environment files and verifies readiness afterward.
For a deliberate restart of one existing service, use
`docker restart <container-name>` after reviewing its dependencies and impact,
then rerun the startup command to check readiness. Explicit `lt restart` retains
the existing refusal; full staged redeployment is a separate operation.

Completed initialization and qualification limits remain recorded in
`../implementation/light-workflow/e04/LOCAL-STARTUP.md`.

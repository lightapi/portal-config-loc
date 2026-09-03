# portal-config-loc

This repository contains the local portal configuration and Docker Compose stacks used for service and UI development. It is intended for full-stack and front-end developers who need to work with both the backend services and the portal UI.

The canonical service, environment-variable, secret, port, dependency, and
operational-storage reference is the
[portal-config-loc operations guide](https://doc.lightapi.net/operations/docker-compose/portal-config-loc.html).

To use this repository, you must also clone the `portal-view` repository and run a local Node.js server to render the UI, which connects to the services started through the Docker Compose stacks in this repository.

If you are a backend developer, or simply want to run the complete application without cloning additional GitHub repositories, follow the CLI installation instructions provided in the [light-portal-install](https://github.com/lightapi/light-portal-install) repository.


## Get Started Quickly

Use the script first for a local Rust stack. It downloads released assets from
`https://cdn.networknt.com` when the target asset directories are missing or
empty, starts `all-in-lt`, and can verify and import the downloaded signed v2
environment bundle
automatically for a new database.

For a first run, the script starts Postgres plus `hybrid-command` and
`hybrid-query`, imports the signed environment bundle when `event_store_t` is empty, and then
starts the full Compose stack. This avoids the dependency loop where
`light-oauth` cannot serve JWKS until the OAuth key data has been imported.

Clone or update the runtime repository under `~/lightapi`:

```bash
cd ~
mkdir -p lightapi
cd lightapi
git clone git@github.com:lightapi/portal-config-loc.git
```

If the repository is already cloned:

```bash
cd ~/lightapi/portal-config-loc
git pull --rebase
```

### Recreate the Database

Full deployment defaults to `IMPORT_EVENTS=auto`: it waits for Postgres, checks
`event_store_t`, and imports the downloaded signed environment bundle only when the event
store is empty. This is the expected mode for a brand new environment or after
removing the Postgres named volume. An empty destination automatically enables
the importer's direct event-table bootstrap mode; no `EVENT_IMPORT_ARGS` are
required.

Before importing, publish the release public key locally as
`release-keys/<keyId>.pem`, where `keyId` is the manifest signing key ID. You
may instead set `EVENT_BUNDLE_KEY_DIR` to an external trusted directory. Never
place the private signing key in this repository or download the trust key from
inside the bundle it verifies.

The supported `all-in-lt` stack uses separate `configserver` and `knowledge`
databases. Application objects are rendered into the `configserver` and
`knowledge` schemas; `public` contains only database-local extension objects.
Runtime roles select their schema, so service URLs remain ordinary database
URLs without schema query parameters. Shared-database, environment-scoped
schemas remain an explicit `portal-db` option for constrained installations.
An existing volume whose application tables are still in `public` must be
rebuilt with the `CLEAN_VOLUMES=true` command below; this topology change does
not move tables in place.

To force a fresh database and import the latest baseline from the CDN, use both
`REFRESH_RELEASE_ASSETS=true` and `CLEAN_VOLUMES=true`:

```bash
cd ~/lightapi/portal-config-loc
REFRESH_RELEASE_ASSETS=true \
CLEAN_VOLUMES=true \
./scripts/deploy-local.sh lt
```

The bootstrap importer defaults to 500 events per physical database commit.
Each event still has its own UUIDv7 logical transaction ID. The importer reports
success as soon as the event, outbox, and notification rows are durable; it does
not wait for projections or inspect the DLQ. The deployment script separately
waits for the asynchronous `user-query-group` consumer cursor before starting
the full stack because OAuth and other services read projected data.

`CLEAN_VOLUMES=true` removes the Postgres named volume, but it does not remove
or refresh `~/lightapi/.release-state/assets/events.zip`.
`REFRESH_RELEASE_ASSETS=true` downloads the current signed `events.zip`
before the new database is populated. Without the refresh flag, a recreated
database can import an older cached event baseline that no longer matches the
current schema.

### Patch a Preserved Local Database

During active development, keep the local `portal-config-loc` data volume and
apply only the new canonical patches from the sibling `portal-db` checkout.
Pass the exact patch files to the normal deployment command; it stops the
application stack, starts only Postgres, applies the patches in filename order,
and then continues startup:

```bash
PORTAL_DB_PATCHES='../portal-db/postgres/patch_20260825_01_config_snapshot_logical_identity.sql ../portal-db/postgres/patch_20260825_02_instance_environment_identity.sql ../portal-db/postgres/patch_20260825_03_config_snapshot_env_tag_writer.sql' \
IMPORT_EVENTS=false \
./scripts/deploy-local.sh lt
```

The runner records each filename and SHA-256 checksum in
`configserver.portal_schema_patch_t`. Re-running the same command skips applied
patches; changing an already applied patch fails with a checksum-drift error.
Patch files must therefore remain immutable. `PORTAL_DB_PATCHES` is ignored
when `CLEAN_VOLUMES=true`, because `init.sql` creates the current schema on the
new volume.

To apply patches without running the rest of deployment, first leave only the
local Postgres container running, then invoke the runner directly:

```bash
CONTAINER_CMD=docker \
./scripts/apply-db-patches.sh configserver \
  ../portal-db/postgres/patch_20260825_01_config_snapshot_logical_identity.sql \
  ../portal-db/postgres/patch_20260825_02_instance_environment_identity.sql \
  ../portal-db/postgres/patch_20260825_03_config_snapshot_env_tag_writer.sql
```

For example, apply the selective-promotion P0-P6 patches, in order, to a
preserved `all-in-lt` database from the `portal-config-loc` repository root:

```bash
cd ~/lightapi/portal-config-loc

./scripts/apply-db-patches.sh configserver \
  ../portal-db/postgres/patch_20260828_01_product_version_promotion.sql \
  ../portal-db/postgres/patch_20260828_02_promotion_lifecycle.sql
```

The `postgres` container must be running. No PostgreSQL restart is required.
The command is safe to rerun: the patch ledger reports the patch as already
applied when its recorded checksum still matches.

Verify the new tables and patch-ledger entry:

```bash
docker exec -e PGPASSWORD=secret postgres \
  psql -h localhost -U postgres -d configserver -c \
  "\dt configserver.promotion*"

docker exec -e PGPASSWORD=secret postgres \
  psql -h localhost -U postgres -d configserver -c \
  "SELECT patch_id, applied_ts
     FROM configserver.portal_schema_patch_t
    WHERE patch_id IN (
      'patch_20260828_01_product_version_promotion',
      'patch_20260828_02_promotion_lifecycle'
    )
    ORDER BY patch_id;"
```

The expected tables are `configserver.promotion_t` and
`configserver.promotion_item_t`, plus `configserver.promotion_recovery_t`,
accompanied by both ledger rows. The second patch adds projection completion,
timeout/failure diagnostics, and the audited recheck/reconcile/replan ledger.
Do not
create these objects manually or execute the raw patch directly in pgAdmin for
`all-in-lt`: its application objects belong in the `configserver` schema, while
an unrendered patch can create unqualified objects in `public`. The patch runner
renders the correct search path and applies the schema changes and ledger entry
in one transaction.

If the database was recreated after `all-in-lt/postgres-db/init.sql` was
regenerated with these tables, this patch is not needed because the fresh
database already contains the current schema.

The daily release remains the promotion boundary: export and convert the
validated local state to one signed v2 environment archive, then let
`portal-config-dev` and `light-portal-install` recreate their databases from
that baseline. Do not concatenate standalone host exports.

### Bootstrap a Newly Generated Baseline

Use bootstrap mode for a signed v2 environment archive generated by the current
snapshot converter. On an empty database, the importer verifies its manifest,
signature, checksums, mode, and singleton event
envelopes and writes the canonical event, outbox, and notification rows directly.
It groups up to 500 singleton logical transactions into each physical database
commit and does not perform graph barriers, identity materialization, projection
convergence, or DLQ checks.

Copy the candidate archive into the release asset cache and publish its public
key in the trusted key directory, then recreate the disposable local database
without refreshing the asset from the CDN:

```bash
cp /path/to/environment-bundle.zip ~/lightapi/.release-state/assets/events.zip
mkdir -p ~/lightapi/portal-config-loc/release-keys
cp /path/to/release-2026.pem ~/lightapi/portal-config-loc/release-keys/release-2026.pem

REFRESH_RELEASE_ASSETS=false \
CLEAN_VOLUMES=true \
EVENT_IMPORTER_IMAGE=networknt/event-importer:latest \
./scripts/deploy-local.sh lt
```

The importer refuses bootstrap mode unless the destination event tables are
empty and stops on the first failed event. The deployment script supplies
bootstrap mode and the 500-event chunk size automatically when `event_store_t`
is empty. The explicit image override prevents a pinned release image from
`.release-state/docker-images.env` from replacing a locally rebuilt importer.
Never use this mode against a live or shared database.

To initialize from a custom bundle, replace the cached archive before the first
import and omit `REFRESH_RELEASE_ASSETS=true`, which would overwrite it:

```bash
mkdir -p ~/lightapi/.release-state/assets
cp /path/to/your/environment-bundle.zip ~/lightapi/.release-state/assets/events.zip
CLEAN_VOLUMES=true ./scripts/deploy-local.sh lt
```

The importer always reads `~/lightapi/.release-state/assets/events.zip` and
requires a trusted key directory. `EVENT_IMPORT_FILE` and bare arrays are
intentionally unsupported on the release/bootstrap path. Historical arrays
remain available only through an explicitly invoked importer command outside
this deployment wrapper.

### Start the Rust Stack

Docker Compose:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="docker compose" \
CONTAINER_CMD=docker \
RUST_LOG=info \
./scripts/deploy-local.sh lt
```

Podman Compose:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="podman compose" \
CONTAINER_CMD=podman \
RUST_LOG=info \
./scripts/deploy-local.sh lt
```

After startup:

```bash
COMPOSE_CMD="podman compose" ./scripts/deploy-local.sh lt status
COMPOSE_CMD="podman compose" ./scripts/deploy-local.sh lt logs
```

The automatic import path uses the event-importer container image through the
selected container runtime. Set `EVENT_IMPORT_RUNNER=local` only when you want
to use an explicitly configured host-side importer command.

Open the portal at `https://localhost`. If you use configured hostnames such as
`dev.lightapi.net`, point them to `127.0.0.1` in your hosts file.

Platform notes:

| Platform | Recommended path |
| --- | --- |
| Ubuntu | Docker Compose is the simplest path. Podman also works after installing a Compose provider. |
| Fedora Silverblue | Podman is a good default; allow rootless binding to port `443` before starting the stack. |
| macOS | Docker Desktop is the simplest path. Podman Desktop also works if the Podman machine is started. |
| Windows | Use WSL2 Ubuntu and run the script inside the WSL shell. Enable Docker Desktop WSL integration or use a Podman machine. |

For detailed OS setup, see
[Local Portal Setup](https://doc.lightapi.net/implementation/local-portal-setup.html)
in the public Light Portal documentation.

### Fedora Silverblue Port Setup

Install the Compose provider once, then reboot into the new Silverblue
deployment:

```bash
sudo rpm-ostree install podman-compose
systemctl reboot
```

Rootless Podman normally cannot bind host port `443`. The local configuration
expects `https://localhost`, so allow unprivileged processes to bind from `443`
upward before starting the stack:

```bash
printf 'net.ipv4.ip_unprivileged_port_start=443\n' | \
  sudo tee /etc/sysctl.d/99-rootless-low-ports.conf
sudo sysctl --system
```

Then start the stack:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="podman compose" \
CONTAINER_CMD=podman \
IMPORT_EVENTS=auto \
RUST_LOG=info \
./scripts/deploy-local.sh lt
```

## Released assets

`deploy-local.sh` downloads released assets from `https://cdn.networknt.com`
when the target service or UI directories are missing or empty. The default
cache directory is:

```text
~/lightapi/.release-state/assets
```

The release assets are:

```text
hybrid-query.zip
hybrid-command.zip
lightapi.zip
signin.zip
events.zip
docker-images.env
```

The script extracts the service archives into the selected compose profile and
extracts the UI archives into the gateway asset directories. For `all-in-pg`,
that means `all-in-pg/light-gateway/lightapi/dist` and
`all-in-pg/light-gateway/signin/dist`. For `all-in-lt`, it populates
`all-in-lt/light-gateway-rust/...`.

Set `REFRESH_RELEASE_ASSETS=true` to refresh the cached release archives and
replace the extracted hybrid service JARs, even when their target directories
are already populated. Populated gateway UI directories are left intact:

```bash
cd ~/lightapi/portal-config-loc
REFRESH_RELEASE_ASSETS=true ./scripts/deploy-local.sh lt
```

Before qualifying or publishing a signin release, validate the exact archive
and every extracted directory that will be mounted by Compose:

```bash
node scripts/verify-signin-assets.mjs \
  /path/to/signin.zip \
  all-in-lt/light-gateway-rust/signin/dist
```

The verifier is read-only. It checks that local assets referenced by
`index.html` exist, rejects the legacy credentialed fetch without an explicit
HTTP method, and requires an explicit credentialed `POST`. It is intentionally
not run automatically by `deploy-local.sh`, so locally populated development
bundles remain under developer control.

When recreating the database at the same time, combine it with
`CLEAN_VOLUMES=true` as shown in [Recreate the Database](#recreate-the-database).

Set `LIGHT_PORTAL_ASSET_BASE_URL` only when testing a different asset host:

```bash
LIGHT_PORTAL_ASSET_BASE_URL=https://cdn.networknt.com ./scripts/deploy-local.sh lt
```

## Optional: Copy locally built jars

If you are developing the backend services in the same workspace, build and
copy the local jars instead:

```bash
cd ~/lightapi/portal-config-loc
./scripts/copy-service-local.sh
```

Use `-f` to force rebuilding all projects:

```bash
cd ~/lightapi/portal-config-loc
./scripts/copy-service-local.sh -f
```

If you want Compose to use locally built baked-in images instead of the
published wrapper tags, add the image-local override compose file:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg
docker compose -f docker-compose.yml -f docker-compose-rust.yml -f docker-compose.image-local.yml up -d --build
```

For Podman, use the same files through `podman compose`:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg
podman compose -f docker-compose.yml -f docker-compose-rust.yml -f docker-compose.image-local.yml up -d --build
```

If you want Compose to use the host service folders directly instead of
baked-in jars, add the service-local override compose file:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg
docker compose -f docker-compose.yml -f docker-compose-rust.yml -f docker-compose.service-local.yml up -d
```

For the `all-in-lt` Rust stack, `docker-compose.yml` uses published
images for `light-workflow`, `demo-customer-profile-api`, and
`demo-offer-decision-api`. Runtime configuration lives in service folders under
`all-in-lt`, not in the source repositories:

```text
all-in-lt/light-workflow-rust/config
all-in-lt/demo-customer-profile-api-rust/config
all-in-lt/demo-offer-decision-api-rust/config
```

This keeps `./scripts/deploy-local.sh lt` working in a clean `~/lightapi`
checkout without requiring sibling source repositories. If you are actively
developing those Rust services, build the images from their source repositories
first, then point compose at those image tags:

```bash
DEMO_CUSTOMER_PROFILE_API_IMAGE=networknt/demo-customer-profile-api:0.1.0 \
DEMO_OFFER_DECISION_API_IMAGE=networknt/demo-offer-decision-api:0.1.0 \
DEMO_INSURANCE_CLAIM_MCP_SERVER_IMAGE=networknt/demo-insurance-claim-mcp-server:latest \
LIGHT_WORKFLOW_IMAGE=networknt/light-workflow:2.3.5 \
./scripts/deploy-local.sh lt
```

## Tool Embedding API Key

`hybrid-query` can call the Gemini embedding API for tool description
embeddings. Keep the API key outside git and pass it through the environment
before starting Compose:

```bash
export GEMINI_API_KEY=...
export EMBEDDING_TASK_ENABLED=true
export EMBEDDING_TASK_PROVIDER=http
```

The default endpoint is Google's OpenAI-compatible embeddings endpoint and the
default model is `gemini-embedding-001` with 384 output dimensions.

## Dedicated LLM Gateway

The `all-in-lt` Rust stack always runs a dedicated `llm-gateway` service from
the same `networknt/light-gateway` image as the Portal BFF. It loads the
`com.networknt.llm.gateway-1.0.0`
snapshot with the shared development `envTag` of `dev` and exposes HTTPS on
host port `8444` by default.

The checked-in local Compose configuration supplies its development Portal
identity. The local Portal environment file (by default
`~/.config/lightapi/light-portal.env`) is only for LLM provider API keys:

```bash
GROQ_API_KEY=...
GEMINI_API_KEY=...
NVIDIA_API_KEY=...
CODEX_API_KEY=...
```

Provider keys remain optional at startup; requests for an unconfigured provider
fail at runtime without preventing the local service graph from starting.
Non-secret optional overrides are:

```bash
LLM_GATEWAY_HOST_PORT=8444
LLM_GATEWAY_ENVIRONMENT=dev
LLM_GATEWAY_RUST_LOG=info
```

After deployment, the direct local LLM endpoint is
`https://localhost:8444/v1/models`.

After publishing the NVIDIA embedding configuration, follow
[`all-in-lt/llm-gateway-rust/VALIDATE-EMBEDDINGS.md`](all-in-lt/llm-gateway-rust/VALIDATE-EMBEDDINGS.md)
to validate `kb-query` through the live gateway without exposing the NVIDIA API
key or raw embedding vector.

The checked Phase 2 helper and both demo lanes are documented in
[`all-in-lt/llm-gateway-rust/NVIDIA-DEMO.md`](all-in-lt/llm-gateway-rust/NVIDIA-DEMO.md).

## Light Agent Codex Settings

The `all-in-lt` Rust stack includes three Agent services backed by the shared
`light-agent` image and configuration templates:

| Service | Service ID | Host port |
| --- | --- | --- |
| `light-agent` | `com.networknt.agent.account-1.0.0` | `8083` |
| `light-agent-advisor` | `com.networknt.agent.advisor-1.0.0` | `8084` |
| `light-agent-tech-support` | `com.networknt.agent.tech-support-1.0.0` | `8088` |

All three select the shared `dev` Config Server environment. The local-only
Compose file includes a different long-lived development token for each Agent.
Each token contains the matching `sid`, the local host identity, and `env=dev`;
developers do not need to supply or manage these values.

The historical tokens formerly embedded in the `light-fabric` `run-*` scripts
did not contain an `env` claim. The Compose defaults were minted from the same
local OAuth clients with `env=dev` so they satisfy the current Config Server
request contract and remain reusable by local developers.

The Agents default to the Codex provider with `gpt-5.5` and low reasoning
effort. Keep Codex credentials outside Git and pass them through the environment:

```bash
export CODEX_API_KEY=...
export CODEX_ACCOUNT_ID=...
```

Optional overrides:

```bash
export LIGHT_AGENT_AGENT_DEF_ID=019e5748-dc1b-748b-908b-89d579f03af9
export LIGHT_AGENT_MODEL=gpt-5.5
export CODEX_REASONING_EFFORT=low
export LIGHT_AGENT_IMAGE=networknt/light-agent:latest
export LIGHT_AGENT_ACCOUNT_PORT=8083
export LIGHT_AGENT_ADVISOR_PORT=8084
export LIGHT_AGENT_TECH_SUPPORT_PORT=8088
```

For a locally built image from `light-fabric`, build it there and point compose
at the tag:

```bash
cd ~/lightapi/light-fabric
./apps/light-agent/build.sh agent-local --local
export LIGHT_AGENT_IMAGE=networknt/light-agent:agent-local
```

The compose files mount `${PORTAL_DATA_DIR:-./data}` to `/data`. By default,
non-database data files stay under the selected compose directory, for example
`all-in-pg/data`. To keep using a shared host directory, set
`PORTAL_DATA_DIR` before running Compose or `deploy-local.sh`.

Postgres uses a Compose named volume called `postgres-data` instead of the
host bind directory `postgres-db/data`. This avoids rootless Podman permission
and SELinux label issues on Fedora Silverblue.

### Rust Logging

Rust services read `RUST_LOG` at startup. The supported base levels are:

```text
off
error
warn
info
debug
trace
```

`error` is the quietest useful level, `info` is normally enough for local
operation, `debug` is verbose, and `trace` is usually only useful for short,
focused debugging sessions. Higher-volume levels include lower-volume messages;
for example, `info` also includes `warn` and `error`.

The Rust compose files default services to verbose debug-oriented logging. To
reduce repeated logs, start or recreate the stack with a quieter level:

```bash
RUST_LOG=info ./scripts/deploy-local.sh pg rust
RUST_LOG=info ./scripts/deploy-local.sh lt
```

To change one service after the stack is already running, recreate that service
from the selected compose directory:

```bash
cd all-in-lt
RUST_LOG=warn podman compose up -d --force-recreate light-gateway
```

Use the same `RUST_LOG` value on later `podman compose up`, `docker compose up`,
or `deploy-local.sh` commands if you want to keep that rendered configuration.
`RUST_LOG` affects Rust services only; Java services use their Java logging
configuration.

## Start portal-view

Start the portal view to access the dashboard or for UI development.

```
cd ~/lightapi
git clone git@github.com:lightapi/portal-view.git
cd portal-view
npm install
npm run dev
```

Click the user profile icon in the bottom-left corner of the page to log in with:

```
steve.hu@lightapi.net
123456
```
# Instance clone rollout

The `all-in-lt`, `all-in-pg`, and `all-in-one` development variants provide
identical, enabled `instance-clone.yml` policies for every hybrid-command/query
process. They share a committed development-only key; developers do not need
to configure it. Command and all query nodes use the same key and key
identifier.

## Operational Database Through Phase 6

The active `all-in-lt` profile creates an additive `operations` database beside
`configserver` and `knowledge`. Fixed local database URLs are defined directly
in Compose. Each non-root runtime materializes its required private
compatibility file inside its own container before starting; no host secret
directory or ownership-changing helper is involved. The checksum-pinned
operational metadata bundle and Host/environment validation remain unchanged.
Controller, Agent, Workflow, A2A, Gateway evidence, tenant audit, and artifact
metadata retain their separate roles and schemas. No operational rows are
copied from Config Server.

Direct Compose users can start immediately:

```bash
cd all-in-lt
docker compose up -d
```

`CLEAN_VOLUMES=true` explicitly destroys the named PostgreSQL volume and all
five databases. Before any operational runtime has written application data,
the narrower Phase 1 fallback removes only `operations`:

```bash
cd all-in-lt
OPERATIONAL_RESET_CONFIRM=DELETE_EMPTY_OPERATIONS \
  docker compose run --rm --no-deps \
  --entrypoint /opt/operational-store/bin/reset-empty-operational-store.sh \
  operational-store-bootstrap
```

The reset refuses to run when any service-owned operational schema contains a
table and always verifies that `configserver` and `knowledge` remain present.
For the early-development Agent fallback, use
`OPERATIONAL_RESET_CONFIRM=RESET_AGENT_OPS` with
`postgres-db/operations/bin/reset-agent-store.sh`; it truncates only
`agent_ops`.

Phase 6 enables the bounded `light-gateway` evidence spool and the explicit
development-only `stdout://collector` sink. Production must replace that sink
with an approved external collector. Artifact rows contain object references,
never bytes. Gateway, audit, and artifact development resets require
`RESET_GATEWAY_OPS`, `RESET_AUDIT_OPS`, and `RESET_ARTIFACT_OPS` respectively
and clear only their own schema.

## Private Host deltas

The signed baseline owns the three canonical Hosts; release deltas remain
available for older pinned baselines. Keep customer-specific Host exports outside Git in
`data/private-event-deltas`; see [the private delta guide](events/PRIVATE_INSTANCE_DELTAS.md).

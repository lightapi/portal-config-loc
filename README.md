# portal-config-loc

This repository contains the local portal configuration and Docker Compose stacks used for service and UI development. It is intended for full-stack and front-end developers who need to work with both the backend services and the portal UI.

To use this repository, you must also clone the `portal-view` repository and run a local Node.js server to render the UI, which connects to the services started through the Docker Compose stacks in this repository.

If you are a backend developer, or simply want to run the complete application without cloning additional GitHub repositories, follow the CLI installation instructions provided in the [light-portal-install](https://github.com/lightapi/light-portal-install) repository.


## Get Started Quickly

Use the script first for a local Rust stack. It downloads released assets from
`https://cdn.networknt.com` when the target asset directories are missing or
empty, starts `all-in-lt`, and can import the downloaded `events.json`
automatically for a new database.

For a first run, the script starts Postgres plus `hybrid-command` and
`hybrid-query`, imports `events.json` when `event_store_t` is empty, and then
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
`event_store_t`, and imports the downloaded `events.json` only when the event
store is empty. This is the expected mode for a brand new environment or after
removing the Postgres named volume. An empty destination automatically enables
the importer's direct event-table bootstrap mode; no `EVENT_IMPORT_ARGS` are
required.

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
./scripts/deploy-local.sh lt rust
```

The bootstrap importer defaults to 500 events per physical database commit.
Each event still has its own UUIDv7 logical transaction ID. The importer reports
success as soon as the event, outbox, and notification rows are durable; it does
not wait for projections or inspect the DLQ. The deployment script separately
waits for the asynchronous `user-query-group` consumer cursor before starting
the full stack because OAuth and other services read projected data.

`CLEAN_VOLUMES=true` removes the Postgres named volume, but it does not remove
or refresh `~/lightapi/.release-state/assets/events.json`.
`REFRESH_RELEASE_ASSETS=true` downloads and extracts the current `events.zip`
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
./scripts/deploy-local.sh lt rust
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

The daily release remains the promotion boundary: export and convert the
validated local state to `events.json`, then let `portal-config-dev` and
`light-portal-install` recreate their databases from that baseline.

### Recover a Preserved Historical Baseline

Use this only for a disposable local database when the preserved `events.json`
predates graph revision and identity-materialization metadata. Keep the source
asset by setting `REFRESH_RELEASE_ASSETS=false`, and explicitly acknowledge the
write-fenced import mode:

```bash
REFRESH_RELEASE_ASSETS=false \
CLEAN_VOLUMES=true \
EVENT_IMPORT_ARGS='--historical-import --legacy-write-fenced' \
./scripts/deploy-local.sh lt rust
```

Never use this mode against a live or shared database. It preserves normal
envelope, schema, nonce, and uniqueness validation, but appends every preserved
event through the direct historical path so command processing cannot reserve a
second nonce or invent missing graph revisions. Projection remains asynchronous.

### Bootstrap a Newly Generated Baseline

Use bootstrap mode for an `events.json` generated by the current snapshot
converter. On an empty database, the importer validates singleton event
envelopes and writes the canonical event, outbox, and notification rows directly.
It groups up to 500 singleton logical transactions into each physical database
commit and does not perform graph barriers, identity materialization, projection
convergence, or DLQ checks.

Copy the candidate into the release asset cache, then recreate the disposable
local database without refreshing the asset from the CDN:

```bash
cp /path/to/events.candidate.json ~/lightapi/.release-state/assets/events.json

REFRESH_RELEASE_ASSETS=false \
CLEAN_VOLUMES=true \
EVENT_IMPORTER_IMAGE=networknt/event-importer:latest \
./scripts/deploy-local.sh lt rust
```

The importer refuses bootstrap mode unless the destination event tables are
empty and stops on the first failed event. The deployment script supplies
bootstrap mode and the 500-event chunk size automatically when `event_store_t`
is empty. The explicit image override prevents a pinned release image from
`.release-state/docker-images.env` from replacing a locally rebuilt importer.
Never use this mode against a live or shared database.

To initialize from a custom snapshot, replace the cached file before the first
import and omit `REFRESH_RELEASE_ASSETS=true`, which would overwrite it:

```bash
mkdir -p ~/lightapi/.release-state/assets
cp /path/to/your/events.json ~/lightapi/.release-state/assets/events.json
CLEAN_VOLUMES=true ./scripts/deploy-local.sh lt rust
```

The importer always reads `~/lightapi/.release-state/assets/events.json`.
`EVENT_IMPORT_FILE` is intentionally not supported.

### Start the Rust Stack

Docker Compose:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="docker compose" \
CONTAINER_CMD=docker \
RUST_LOG=info \
./scripts/deploy-local.sh lt rust
```

Podman Compose:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="podman compose" \
CONTAINER_CMD=podman \
RUST_LOG=info \
./scripts/deploy-local.sh lt rust
```

After startup:

```bash
COMPOSE_CMD="podman compose" ./scripts/deploy-local.sh lt rust status
COMPOSE_CMD="podman compose" ./scripts/deploy-local.sh lt rust logs
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
./scripts/deploy-local.sh lt rust
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
`all-in-pg/light-gateway/signin/dist`. For `all-in-lt`, it populates both
`all-in-lt/light-gateway-java/...` and `all-in-lt/light-gateway-rust/...` so
either gateway variant can be selected.

Set `REFRESH_RELEASE_ASSETS=true` to refresh the cached release archives and
replace the extracted hybrid service JARs, even when their target directories
are already populated. Populated gateway UI directories are left intact:

```bash
cd ~/lightapi/portal-config-loc
REFRESH_RELEASE_ASSETS=true ./scripts/deploy-local.sh lt rust
```

Before qualifying or publishing a signin release, validate the exact archive
and every extracted directory that will be mounted by Compose:

```bash
node scripts/verify-signin-assets.mjs \
  /path/to/signin.zip \
  all-in-lt/light-gateway-java/signin/dist \
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
LIGHT_PORTAL_ASSET_BASE_URL=https://cdn.networknt.com ./scripts/deploy-local.sh lt rust
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

For the `all-in-lt` Rust stack, `docker-compose-rust.yml` uses published
images for `light-workflow`, `demo-customer-profile-api`, and
`demo-offer-decision-api`. Runtime configuration lives in service folders under
`all-in-lt`, not in the source repositories:

```text
all-in-lt/light-workflow-rust/config
all-in-lt/demo-customer-profile-api-rust/config
all-in-lt/demo-offer-decision-api-rust/config
```

This keeps `./scripts/deploy-local.sh lt rust` working in a clean `~/lightapi`
checkout without requiring sibling source repositories. If you are actively
developing those Rust services, build the images from their source repositories
first, then point compose at those image tags:

```bash
DEMO_CUSTOMER_PROFILE_API_IMAGE=networknt/demo-customer-profile-api:0.1.0 \
DEMO_OFFER_DECISION_API_IMAGE=networknt/demo-offer-decision-api:0.1.0 \
DEMO_INSURANCE_CLAIM_MCP_SERVER_IMAGE=networknt/demo-insurance-claim-mcp-server:latest \
LIGHT_WORKFLOW_IMAGE=networknt/light-workflow:2.3.5 \
./scripts/deploy-local.sh lt rust
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

Keep its long-lived Portal token outside git in the local Portal environment
file (by default `~/.config/lightapi/light-portal.env`):

```bash
LLM_GATEWAY_LIGHT_PORTAL_AUTHORIZATION="Bearer ..."
```

The token must carry `sid=com.networknt.llm.gateway-1.0.0`. Provider keys remain
optional at startup. `GROQ_API_KEY`, `GEMINI_API_KEY`, or `NVIDIA_API_KEY` can
be supplied through the same file; requests for an unconfigured provider fail
at runtime without preventing the local service graph from starting. Optional
overrides are:

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
Each token contains the matching `sid`, the local host identity, and `env=dev`.
The defaults can be overridden when testing a replacement token:

```bash
export LIGHT_AGENT_ACCOUNT_LIGHT_PORTAL_AUTHORIZATION='Bearer ...'
export LIGHT_AGENT_ADVISOR_LIGHT_PORTAL_AUTHORIZATION='Bearer ...'
export LIGHT_AGENT_TECH_SUPPORT_LIGHT_PORTAL_AUTHORIZATION='Bearer ...'
```

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
RUST_LOG=info ./scripts/deploy-local.sh lt rust
```

To change one service after the stack is already running, recreate that service
from the selected compose directory:

```bash
cd all-in-lt
RUST_LOG=warn podman compose -f docker-compose.yml -f docker-compose-rust.yml up -d --force-recreate light-gateway
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
process. They share a committed development-only fallback key. Override it for
any shared or externally reachable environment:

```bash
export INSTANCE_CLONE_PLAN_HMAC_KEY='<local-secret>'
export INSTANCE_CLONE_PLAN_HMAC_KEY_ID='v1'
```

Do not import a real secret into configuration snapshots. Command and all query
nodes must use the same key and key identifier.

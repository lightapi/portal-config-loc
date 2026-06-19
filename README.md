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
removing the Postgres named volume.

To force a fresh database and re-import the downloaded events, use
`CLEAN_VOLUMES=true`:

```bash
CLEAN_VOLUMES=true ./scripts/deploy-local.sh lt rust
```

To initialize from a custom snapshot, replace the cached file before the first
import:

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

Set `REFRESH_RELEASE_ASSETS=true` to redownload the cached archives:

```bash
cd ~/lightapi/portal-config-loc
REFRESH_RELEASE_ASSETS=true ./scripts/deploy-local.sh lt rust
```

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

## Light Agent Codex Settings

The Rust compose stacks include `light-agent` for the account agent. It defaults
to the Codex provider with `gpt-5.5` and low reasoning effort. The local
development compose files include the account-agent portal token by default,
matching the existing `light-gateway` local-token pattern. Keep Codex
credentials outside git and pass them through the environment:

```bash
export CODEX_API_KEY=...
export CODEX_ACCOUNT_ID=...
```

Optional overrides:

```bash
export LIGHT_AGENT_MODEL=gpt-5.5
export CODEX_REASONING_EFFORT=low
export LIGHT_AGENT_IMAGE=networknt/light-agent:latest
export LIGHT_AGENT_LIGHT_PORTAL_AUTHORIZATION='Bearer ...'
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

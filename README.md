# portal-config-loc
Portal configuration and docker-compose to start light-portal services at local to help service developers and UI developers. For pure UI developers, he/she can use the https://localhost:3000 to connect to the dev portal server.

## Get Started Quickly

Use the script first for a local Rust stack. It copies the checked-in assets
from the sibling `service-asset` repository when the target asset directories
are missing or empty, starts `all-in-lt`, and can import
`service-asset/events.json` automatically for a new database.

Clone or update the two runtime repositories under `~/lightapi`:

```bash
cd ~
mkdir -p lightapi
cd lightapi
git clone git@github.com:lightapi/portal-config-loc.git
git clone git@github.com:lightapi/service-asset.git
```

If both repositories are already cloned:

```bash
cd ~/lightapi/portal-config-loc
git pull --rebase
cd ~/lightapi/service-asset
git pull --rebase
```

### Optional: Use Your Own Events

The importer always reads this exact file:

```text
~/lightapi/service-asset/events.json
```

To initialize a new local database with your own snapshot, replace
`~/lightapi/service-asset/events.json` before running `deploy-local.sh` for the
first time:

```bash
cp /path/to/your/events.json ~/lightapi/service-asset/events.json
```

Do not use a different filename. `deploy-local.sh` rejects `EVENT_IMPORT_FILE`
so every import path uses only `service-asset/events.json`. After the script has
started and imported events into Postgres, replacing the file will not change
the existing database. To reinitialize from a different file, remove the
Postgres named volume, replace `service-asset/events.json`, and then start the
script again with `IMPORT_EVENTS=auto`.

For Podman:

```bash
cd ~/lightapi/portal-config-loc/all-in-lt
podman compose -f docker-compose.yml -f docker-compose-rust.yml down -v
```

For Docker:

```bash
cd ~/lightapi/portal-config-loc/all-in-lt
docker compose -f docker-compose.yml -f docker-compose-rust.yml down -v
```

Docker Compose:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="docker compose" \
CONTAINER_CMD=docker \
IMPORT_EVENTS=auto \
RUST_LOG=info \
./scripts/deploy-local.sh lt rust
```

Podman Compose:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="podman compose" \
CONTAINER_CMD=podman \
IMPORT_EVENTS=auto \
RUST_LOG=info \
./scripts/deploy-local.sh lt rust
```

`IMPORT_EVENTS=auto` waits for Postgres, checks `event_store_t`, and imports
`~/lightapi/service-asset/events.json` only when the event store is empty. This
is the expected mode for a brand new environment or after removing the Postgres
named volume. Leave `IMPORT_EVENTS` unset for normal restarts, or use
`IMPORT_EVENTS=true` only when you intentionally want to import again.

The automatic import path uses the event-importer container image through the
selected container runtime. Set `EVENT_IMPORT_RUNNER=local` only when you want
to use the host-side importer scripts from `service-asset`.

After startup:

```bash
COMPOSE_CMD="podman compose" ./scripts/deploy-local.sh lt rust status
COMPOSE_CMD="podman compose" ./scripts/deploy-local.sh lt rust logs
```

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

### Fedora Silverblue Postgres Permissions

Postgres data is stored in a Compose named volume, not in
`postgres-db/data`. If you previously started the stack before this change and
hit a permission error on the old bind-mounted data directory, pull the latest
config and recreate the stack:

```bash
cd ~/lightapi/portal-config-loc
git pull --rebase
COMPOSE_CMD="podman compose" CONTAINER_CMD=podman ./scripts/deploy-local.sh lt rust stop
COMPOSE_CMD="podman compose" CONTAINER_CMD=podman IMPORT_EVENTS=auto ./scripts/deploy-local.sh lt rust
```

If you need a completely fresh database after a failed first run, remove the
Compose volume before starting again:

```bash
cd ~/lightapi/portal-config-loc/all-in-lt
podman compose -f docker-compose.yml -f docker-compose-rust.yml down -v
```

### Fedora Silverblue Controller Certificates

If `controller-rs` fails with a message that
`CONTROLLER_TLS_CERT_PATH` points to missing `/keystore/server.pem`, use the
latest Compose files and recreate the Rust stack. The cert files are tracked in
`all-in-lt/light-controller-rust`, but rootless Podman on Silverblue needs the
keystore bind mount to be SELinux relabeled.

```bash
cd ~/lightapi/portal-config-loc
git pull --rebase
COMPOSE_CMD="podman compose" CONTAINER_CMD=podman ./scripts/deploy-local.sh lt rust restart
```

## Create a workspace

```
cd ~
mkdir lightapi
```

## Choose a service source

For `portal-view` development there are two practical ways to populate the hybrid service jars under:

- `all-in-pg/hybrid-query/service`
- `all-in-pg/hybrid-command/service`

The recommended shared source for checked-in service and UI assets is the separate `service-asset` repository:

- `~/lightapi/service-asset/hybrid-query`
- `~/lightapi/service-asset/hybrid-command`
- `~/lightapi/service-asset/lightapi/dist`
- `~/lightapi/service-asset/signin/dist`

Use a local build only if you are actively changing one or more `*-query` or `*-command` services in your workspace and need those unpublished changes locally.

### Option 1: Use checked-in assets from `service-asset`

Clone both repositories into the same workspace:

```bash
cd ~
mkdir -p lightapi
cd lightapi
git clone git@github.com:lightapi/portal-config-loc.git
git clone git@github.com:lightapi/service-asset.git
```

You can copy the checked-in assets manually if needed:

```bash
cd ~/lightapi
cp service-asset/hybrid-query/*.jar portal-config-loc/all-in-pg/hybrid-query/service/
cp service-asset/hybrid-command/*.jar portal-config-loc/all-in-pg/hybrid-command/service/
cp -R service-asset/lightapi/dist portal-config-loc/all-in-pg/light-gateway/lightapi
cp -R service-asset/signin/dist portal-config-loc/all-in-pg/light-gateway/signin
cp -R service-asset/lightapi/dist portal-config-loc/all-in-lt/light-gateway-java/lightapi
cp -R service-asset/signin/dist portal-config-loc/all-in-lt/light-gateway-java/signin
cp -R service-asset/lightapi/dist portal-config-loc/all-in-lt/light-gateway-rust/lightapi
cp -R service-asset/signin/dist portal-config-loc/all-in-lt/light-gateway-rust/signin
```

This manual step is usually unnecessary now. When you run `./scripts/deploy-local.sh`, it checks the hybrid service directories and the gateway UI asset directories under the currently selected compose directory. For `all-in-pg`, that means `all-in-pg/light-gateway/lightapi/dist` and `all-in-pg/light-gateway/signin/dist`. For `all-in-lt`, it populates both `all-in-lt/light-gateway-java/...` and `all-in-lt/light-gateway-rust/...` so either gateway variant can be selected. If any of them are missing, it automatically copies them from `~/lightapi/service-asset`. If the `service-asset` repo or the expected files are missing, the deploy script exits with an error.

### Option 2: Copy locally built jars

If you are developing the backend services in the same workspace, build and copy the local jars instead:

```bash
cd ~/lightapi/portal-config-loc
./scripts/copy-service-local.sh
```

This script now also copies the built jars into `~/lightapi/service-asset/hybrid-query` and `~/lightapi/service-asset/hybrid-command` when the `service-asset` repository is present.

Use `-f` to force rebuilding all projects:

```bash
cd ~/lightapi/portal-config-loc
./scripts/copy-service-local.sh -f
```

If you want Compose to use locally built baked-in images instead of the published wrapper tags, add the image-local override compose file:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg
docker compose -f docker-compose.yml -f docker-compose-rust.yml -f docker-compose.image-local.yml up -d --build
```

For Podman, use the same files through `podman compose`:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg
podman compose -f docker-compose.yml -f docker-compose-rust.yml -f docker-compose.image-local.yml up -d --build
```

If you want Compose to use the host service folders directly instead of baked-in jars, add the service-local override compose file:

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

## Start services

```
cd ~/lightapi
git clone git@github.com:lightapi/portal-config-loc.git
git clone git@github.com:lightapi/service-asset.git
cd portal-config-loc
./scripts/deploy-local.sh pg rust
```

The compose files mount `${PORTAL_DATA_DIR:-./data}` to `/data`. By default, non-database data files stay under the selected compose directory, for example `all-in-pg/data`. To keep using a shared host directory, set `PORTAL_DATA_DIR` before running Compose or `deploy-local.sh`.

Postgres uses a Compose named volume called `postgres-data` instead of the
host bind directory `postgres-db/data`. This avoids rootless Podman permission
and SELinux label issues on Fedora Silverblue. To reset Postgres for a selected
stack, run Compose directly from that stack directory with `down -v`.

### Podman Compose

The deploy script defaults to Docker Compose for existing development machines.
To use Podman Compose, set `COMPOSE_CMD`:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="podman compose" CONTAINER_CMD=podman ./scripts/deploy-local.sh lt rust
```

You can also run Compose directly from the selected stack directory:

```bash
cd ~/lightapi/portal-config-loc/all-in-lt
podman compose -f docker-compose.yml -f docker-compose-rust.yml up -d
```

If `podman compose` cannot find a provider, verify `podman-compose` is installed
and visible on `PATH`:

```bash
podman compose version
podman-compose --version
```

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

## Import Events

The preferred first-run path is automatic import through `deploy-local.sh`:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="podman compose" CONTAINER_CMD=podman IMPORT_EVENTS=auto ./scripts/deploy-local.sh lt rust
```

`IMPORT_EVENTS=auto` imports only when `event_store_t` is empty. To force an
import, use:

```bash
COMPOSE_CMD="podman compose" CONTAINER_CMD=podman IMPORT_EVENTS=true ./scripts/deploy-local.sh lt rust start
```

Automatic import uses a container by default. `CONTAINER_CMD` selects the
runtime and `EVENT_IMPORTER_IMAGE` selects the image:

```bash
COMPOSE_CMD="podman compose" \
CONTAINER_CMD=podman \
IMPORT_EVENTS=auto \
EVENT_IMPORTER_IMAGE=networknt/event-importer:latest \
./scripts/deploy-local.sh lt rust start
```

Manual local import is still available from `service-asset` by setting
`EVENT_IMPORT_RUNNER=local`. The Rust importer is the best local option on
Linux because it does not require a local JDK:

```bash
cd ~/lightapi/portal-config-loc
COMPOSE_CMD="podman compose" \
CONTAINER_CMD=podman \
IMPORT_EVENTS=true \
EVENT_IMPORT_RUNNER=local \
./scripts/deploy-local.sh lt rust start
```

The Java importer is available if `JAVA_HOME` points to a local JDK:

```
cd ~/lightapi/service-asset
./importer.sh -f events.json
```

## Start portal-view

Start the portal view in Nodejs to UI development.

```
cd ~/lightapi
git clone git@github.com:lightapi/portal-view.git
cd portal-view
npm install
npm run dev
```

click the user profile icon on the top right corner to login with

```
steve.hu@lightapi.net
123456
```

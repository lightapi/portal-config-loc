# portal-config-loc
Portal configuration and docker-compose to start light-portal services at local to help service developers and UI developers. For pure UI developers, he/she can use the https://localhost:3000 to connect to the dev portal server.

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

If you want Docker to use locally built baked-in images instead of the published wrapper tags, add the image-local override compose file:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg
docker compose -f docker-compose.yml -f docker-compose-rust.yml -f docker-compose.image-local.yml up -d --build
```

If you want Docker to use the host service folders directly instead of baked-in jars, add the service-local override compose file:

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
before starting Docker Compose:

```bash
export GEMINI_API_KEY=...
export EMBEDDING_TASK_ENABLED=true
export EMBEDDING_TASK_PROVIDER=http
```

The default endpoint is Google's OpenAI-compatible embeddings endpoint and the
default model is `gemini-embedding-001` with 384 output dimensions.

## Start services

```
cd ~/lightapi
git clone git@github.com:lightapi/portal-config-loc.git
git clone git@github.com:lightapi/service-asset.git
cd portal-config-loc
./scripts/deploy-local.sh pg rust
```

The compose files mount `${PORTAL_DATA_DIR:-./data}` to `/data`. By default, data files stay under the selected compose directory, for example `all-in-pg/data`. To keep using a shared host directory, set `PORTAL_DATA_DIR` before running Docker Compose or `deploy-local.sh`.

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
RUST_LOG=warn docker compose -f docker-compose.yml -f docker-compose-rust.yml up -d --force-recreate light-gateway
```

Use the same `RUST_LOG` value on later `docker compose up` or
`deploy-local.sh` commands if you want to keep that rendered configuration.
`RUST_LOG` affects Rust services only; Java services use their Java logging
configuration.

## Import Events

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

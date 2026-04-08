# portal-config-loc
Portal configuration and docker-compose to start light-portal services at local to help service developers and UI developers. For pure UI developers, he/she can use the https://localhost:3000 to connect to the dev portal server.

## Choose a service source

For `portal-view` development there are two practical ways to populate the hybrid service jars under:

- `all-in-pg/hybrid-query/service`
- `all-in-pg/hybrid-command/service`

Use the published snapshot jars by default if you are only working on `portal-view` or another consumer of the services. This is the easiest setup for most developers.

Use a local build only if you are actively changing one or more `*-query` or `*-command` services in your workspace and need those unpublished changes locally.

### Option 1: Download published jars

The script below downloads every `*-query` and `*-command` jar into the `all-in-pg` service folders. It uses the official Maven `maven-dependency-plugin:copy` approach so Maven resolves the snapshot metadata and downloads the correct jar into the target directory. For `*-SNAPSHOT` versions it uses Sonatype snapshot repository, and for release versions it uses Maven Central.

```bash
cd ~/lightapi/portal-config-loc
./scripts/download-service-jars.sh
```

By default it downloads `2.3.4-SNAPSHOT`. To use another version:

```bash
cd ~/lightapi/portal-config-loc
VERSION=2.3.4-SNAPSHOT ./scripts/download-service-jars.sh
```

If you want to refresh snapshots, rerun the script. It uses Maven `-U`, so developers can run it daily to pick up newly published snapshot jars.

### Option 2: Copy locally built jars

If you are developing the backend services in the same workspace, build and copy the local jars instead:

```bash
cd ~/lightapi/portal-config-loc
./scripts/copy-service-local.sh
```

Use `-f` to force rebuilding all projects:

```bash
cd ~/lightapi/portal-config-loc
./scripts/copy-service-local.sh -f
```

### Create a workspace

```
cd ~
mkdir lightapi
```

### Start services

```
cd lightapi
git clone git@github.com:lightapi/portal-config-loc.git
cd portal-config-loc
./scripts/download-service-jars.sh
./scripts/deploy-local.sh pg rust
```

### Start portal-view

Start the portal view in Nodejs to UI development.

```
cd ~/lightapi
git clone git@github.com:lightapi/portal-view.git
cd portal-view
yarn install
yarn dev
```

click the user profile icon on the top right corner to login with

```
steve.hu@lightapi.net
123456
```

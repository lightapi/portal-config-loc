# portal-config-loc
Portal configuration and docker-compose to start light-portal services at local to help service developers and UI developers. For pure UI developers, he/she can use the https://localhost:3000 to connect to the dev portal server.

## Choose a service source

For `portal-view` development there are two practical ways to populate the hybrid service jars under:

- `all-in-pg/hybrid-query/service`
- `all-in-pg/hybrid-command/service`

Use the baked-in hybrid Docker images by default if you are only working on `portal-view` or another consumer of the services. This is the easiest setup for most developers because the jars are packaged into published wrapper images for `hybrid-command` and `hybrid-query`.

Use a local build only if you are actively changing one or more `*-query` or `*-command` services in your workspace and need those unpublished changes locally.

### Option 1: Use published baked-in hybrid images

The default `all-in-pg` compose file now pulls published wrapper images by default:

- `networknt/portal-hybrid-command:2.2.1-services`
- `networknt/portal-hybrid-query:2.2.1-services`

You can override them with:

- `HYBRID_COMMAND_IMAGE`
- `HYBRID_QUERY_IMAGE`

The script below can still refresh the jars in those folders before the image build. It uses the same official Maven `maven-dependency-plugin:copy` command that works from the command line, so Maven resolves the snapshot metadata and downloads the correct jar into the target directory. For `*-SNAPSHOT` versions it uses Sonatype snapshot repository, and for release versions it uses Maven Central.

```bash
cd ~/lightapi/portal-config-loc
./scripts/download-service-jars.sh
```

By default it downloads `2.3.4-SNAPSHOT`. To use another version:

```bash
cd ~/lightapi/portal-config-loc
VERSION=2.3.4-SNAPSHOT ./scripts/download-service-jars.sh
```

If you want to refresh snapshots, rerun the script after the new snapshot jars are published.

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

If you want Docker to use locally built baked-in images instead of the published wrapper tags, add the image-local override compose file:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg
docker compose -f docker-compose.yml -f docker-compose.controller-rs.yml -f docker-compose.image-local.yml up -d --build
```

If you want Docker to use the host service folders directly instead of baked-in jars, add the service-local override compose file:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg
docker compose -f docker-compose.yml -f docker-compose.controller-rs.yml -f docker-compose.service-local.yml up -d
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

### Publish wrapper images

If you maintain the baked-in hybrid images, publish them from `all-in-pg` after refreshing the service jars:

```bash
cd ~/lightapi/portal-config-loc
./scripts/download-service-jars.sh
cd all-in-pg/hybrid-command
./build.sh 2.2.1-services
cd ../hybrid-query
./build.sh 2.2.1-services
```

To build without pushing:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg/hybrid-command
./build.sh 2.2.1-services -l
cd ../hybrid-query
./build.sh 2.2.1-services -l
```

If you change the jars in `all-in-pg/hybrid-command/service` or `all-in-pg/hybrid-query/service` and want to rebuild local wrapper images before restarting:

```bash
cd ~/lightapi/portal-config-loc/all-in-pg
docker compose -f docker-compose.yml -f docker-compose.controller-rs.yml -f docker-compose.image-local.yml build hybrid-command hybrid-query1 hybrid-query2 hybrid-query3
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

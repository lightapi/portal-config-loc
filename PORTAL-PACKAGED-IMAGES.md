# Image-only Portal in all-in-lt

Both Portal images must contain their service JARs. For local builds, select the
images in `light-portal.env` (the file selected by `LIGHT_PORTAL_ENV_FILE`):

```dotenv
PORTAL_HYBRID_COMMAND_IMAGE=networknt/portal-hybrid-command:2.3.5-dev.20260929.1156
PORTAL_HYBRID_QUERY_IMAGE=networknt/portal-hybrid-query:2.3.5-dev.20260929.1156
```

Registry publication and digest references are not required. Explicit digest
references remain supported for deployments that use them.
Default Compose has no host `/service` mounts or service-JAR folders in
`all-in-lt`, `all-in-one` or `all-in-pg`. To update services, rebuild the hybrid
images and select their tags; the images retain their internal `/service`
directories. `copy-service-local.sh` is a compatibility notice and performs no
builds or copies. Gateway asset handling is unchanged.

Render using the existing environment files:

```sh
./scripts/deploy-local.sh lt config
```

An optional two-variable fragment can override those selections:

```sh
PORTAL_IMAGE_ENV_FILE=/absolute/path/portal-images.env ./scripts/deploy-local.sh lt config
```

This renders configuration without starting containers or downloading release
environment files. Treat rendered output as private: configuration can contain
secrets. Check both selected images, absent `/service` mounts and retained `/config`
mounts. The fragment is validated without shell evaluation and takes precedence
over process overrides and the full-stack release environment file. Without a
fragment, process overrides take precedence over release-file values. The
fragment must not replace the full-stack environment file.

The same fragment and effective-image validation apply to standalone
`scripts/import-event-deltas.sh` and `all-in-lt/light-identity-issuer/issuer-tokens.sh`.
Both validate/export the pair before any container or database action. Ordered
Compose env files are resolved first (later local files win), then process
overrides, then the authoritative Portal fragment. The release checker also
refuses an invalid effective Portal pair rather than trusting a caller.

Use `./scripts/deploy-local.sh lt` to ensure the initialized local stack is
running. It performs the local startup checks and preserves healthy unchanged
services; see [LOCAL-QUICKSTART.md](LOCAL-QUICKSTART.md). No development service
override is enabled by default.

Rollback requires the previous images **and deployment configuration**. Older
images without bundled services also require restoring their service mounts.
Preserve Compose project identity, existing volumes and private configuration;
do not use a disposable project's volume inventory as runtime qualification.

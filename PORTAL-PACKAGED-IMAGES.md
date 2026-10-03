# Image-only Portal in all-in-lt

Both Portal images must contain their service JARs. all-in-lt requires explicit
`networknt/portal-hybrid-command@sha256:...` and
`networknt/portal-hybrid-query@sha256:...` references; old defaults are refused.
Default Compose has no host `/service` mounts. Host JAR directories and other
layouts' ZIP handling are retained. Gateway asset handling is unchanged.

Supply the successful build's two-variable fragment:

```sh
PORTAL_IMAGE_ENV_FILE=/absolute/path/portal-images.env ./scripts/deploy-local.sh lt config
```

This renders configuration without starting containers or downloading release
environment files. Treat rendered output as private: configuration can contain
secrets. Check both exact digests, absent `/service` mounts and retained `/config`
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

Bare `./scripts/deploy-local.sh lt` remains refused by W7. An authorized runtime
exercise must use the existing stop, stage-controller, fresh-readiness, start
sequence documented in the E04 runbook; packaging does not waive its database,
bundle, instance or permission prerequisites. No development service override is
enabled by default.

Rollback requires the previous images **and deployment configuration**. Older
images without bundled services also require restoring their service mounts.
Preserve Compose project identity, existing volumes and private configuration;
do not use a disposable project's volume inventory as runtime qualification.

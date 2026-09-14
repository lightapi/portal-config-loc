# Standalone light-a2a setup

The normal `all-in-lt` stack includes `light-a2a` without Compose profiles.
The external-agent integration runtime is separate from light-agent's native
A2A endpoints. It requires both a packaged image and activated Portal authority.

## Build and select the image

From the workspace directory:

```sh
cd light-fabric
./apps/light-a2a/build.sh VERSION --local --skip-latest
```

Set `LIGHT_A2A_IMAGE=networknt/light-a2a:VERSION` in the release image env file
(default `../.release-state/docker-images.env`). The workspace release script
includes light-a2a in both `lt-rust` and `rust-apps` image sets and writes this
variable into a complete release manifest. For an isolated image build use
`./release-docker-images.sh --component light-a2a --tag VERSION --local --no-compose-env --skip-compose-stop`.
The component-only command intentionally does not replace the complete manifest.

## Author and activate the workload

Use the existing Portal authoring/import and candidate-checked publication
commands. Generated input belongs in `light-portal-event`. Do not insert generated
policy into a snapshot or put fabricated bindings into local `values.yml`.

1. Create the runtime instance for Host `dev.lightapi.net`, service
   `com.networknt.light-a2a-1.0.0`, environment `dev`, using the Agent product
   required by the A2A publication compiler. Configure its bootstrap/registry
   credentials and operational/artifact-store bindings through the normal
   configuration mechanisms.
2. Choose the external agent. `EXTERNAL_SIDECAR` needs a backend implementing
   `light-a2a-backend/v1` in the same network namespace, with the reviewed contract,
   capabilities and mounted context key. `REMOTE_A2A` needs an approved remote
   destination, reviewed Agent Card and outbound policy. An arbitrary URL or an
   empty binding list cannot satisfy this requirement.
3. Author the Agent definition, assigned Skills, Gateway instance/API association,
   metadata, retention profile, signing profile/key reference and A2A binding.
   Publish the Agent definition and Skills first. Prepare and sign the A2A Agent
   Card, then publish using the exact preview candidate digest/version. Activate
   the resulting runtime and Gateway snapshots through Portal.
4. Verify the published `runtimePolicy` matches the workload identity and remains
   activated and not revoked or replaced. Runtime policy has no time-based
   expiration; legacy expiry timestamps are ignored. Verify database/secret access,
   artifact volume permissions and the selected backend's availability.

The Docker image runs as UID/GID 999 to match the local protected secret volumes.
It contains curl, `/app/light-a2a`, bundled defaults and writable cache/artifact
paths. Bootstrap authorization is supplied through
`LIGHT_A2A_LIGHT_PORTAL_AUTHORIZATION` in the private Portal env file.

## Deployment qualification

The A2A diagnostic is explicit and is not called by `deploy-local.sh`:

```sh
python3 scripts/verify-a2a-deployment.py docker docker compose \
  --env-file ../.release-state/docker-images.env \
  -f all-in-lt/docker-compose.yml
```

Run it after the local database is running and bootstrap/authoring has completed.
Add the private Portal env file as a second `--env-file` if it overrides the
image selection. The diagnostic never starts or stops services. It checks image
availability and current snapshot policy, permits omitted identity fields with
valid template defaults, and does not require local store bindings in snapshots.
Missing/malformed snapshots, future activation times or identity mismatches produce an error. It is not an
end-to-end runtime qualification and does not validate store access or credentials.

Normal deployment remains free to start Postgres and import baseline events.
There is no automatic A2A gate before that bootstrap. The standalone service
still needs an actual backend and activated policy to become ready; removing the
diagnostic gate does not make an unconfigured service deployable, skip it, or
relax the required-service readiness checks.

After authoring, run `./scripts/deploy-local.sh lt`, verify all required services
including `light-a2a` are ready, and run the same command again to qualify a normal
restart. A2A readiness is `http://localhost:8448/_a2a/ready`; `/health` alone does
not prove policy or backend readiness. No profile selection is needed.

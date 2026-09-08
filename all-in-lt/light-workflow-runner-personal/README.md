# Personal Codex Runner

## Enrollment status

Enrollment was verified live on 2026-09-05. The running service uses
`.runtime/runner.yml`, not the placeholder `runner.yml.example`.

| Requirement | Configured value / result |
| --- | --- |
| Controller host endpoint | `wss://localhost:8438/ws/runner`, published as `127.0.0.1:8438:8438` |
| TLS trust | User service supplies `SSL_CERT_FILE` pointing to `light-controller-rust/ca.pem`; no `controllerTlsCaFile` YAML property |
| Runner subject | `urn:lightapi:runner:personal-codex-runner` |
| Host | `01964b05-552a-7c4b-9184-6857e7f3dc5f` |
| Runner / enrollment IDs | `personal-codex-runner` / `personal-codex-runner-enrollment` |
| Runner JWT audience / scope | `urn:lightapi:runner` / `runner.connect` |
| Agent origin | `com.networknt.agent.account-1.0.0` |
| Native credentials / concurrency | Existing `~/.codex`, mode `0700`; maximum concurrency `1` |
| Installed runner/worker hashes | Match the generated admission and runner configuration |
| Account agent execution authorization | Authenticated execution-result request returns HTTP 200 |
| Runner readiness / registration | `{"ready":true}` / controller registration accepted |

`print-admission` takes the workflow origin as its second argument. The agent
origin is derived separately from `agentWorker.originServiceId`. The generated
document therefore contains workflow origin `light-workflow` and agent origin
`com.networknt.agent.account-1.0.0`. The workflow origin is not proof that the
Portal workflow product is configured to dispatch work to this personal pool.

Do not start a second foreground runner while the user service is active:
both would use the same enrollment, health port, and execution journal.

## Runner enablement and deployment

The base Compose file defaults `CONTROLLER_RUNNER_ENABLED` to false so a fresh
installation can start without a locally enrolled runner. Enabling it requires
an admission file plus a valid execution database credential, schema, and binding.
Controller already defaults its runner JWT audience to `urn:lightapi:runner`;
the overlay sets that value explicitly. Agent execution calls also require
`execution.invoke` on their workload credentials.

Local enrollment uses two overlays:

- Tracked `compose.yml`: runner enablement, admission mount, audience, and loopback port.
- Private `.runtime/credentials.compose.yml`: agent execution credentials only.

Neither overlay contains image pins. `start.sh` uses the same release image
file as normal deployment (`RELEASE_IMAGE_ENV_FILE`, default
`$workspace/.release-state/docker-images.env`) and optional `LIGHT_PORTAL_ENV_FILE`.
It refuses to start without a release image file, admission, and credentials.
Before stopping services, both deployment paths check the selected image for
`io.lightapi.agent.session-lifecycle=1`. Build the corrected agent Dockerfile and
select that image in the release environment before deploying. The label
identifies support for independent session cleanup and structured initialization
errors; a tag timestamp is not used as evidence because local tags may be reused.
Images missing this capability are rejected, even if their tag is familiar.

Use a release containing the chat authentication and memory fixes; the historical
local-only `chat-auth` image was never published and is not a portable release.

`deploy-local.sh lt` automatically includes these overlays when
`.runtime/credentials.compose.yml` exists. It fails early if admission is missing.
This keeps an enrolled local runner enabled across normal deployments without
reverting controller/agent images. Setting `CONTROLLER_RUNNER_ENABLED=false`
explicitly still disables runner execution. Direct use of the base Compose file
alone does not include the runner enrollment.

For an older installation with `.runtime/compose.yml`, regenerate enrollment
using `configure-local.py` to create the credentials-only file. The old mixed
image/settings/credentials file is no longer consumed. Keep both private files
out of Git and logs. Recreating Controller applies environment and mount changes;
no Controller rebuild is needed for configuration changes.

## Remaining Portal coding prerequisite

The sibling `light-portal` source now accepts a validated coding profile from
module `agent-policy-authoring`, property `codingProfile` (`map`), assigned to
the instance's product version and authored at instance scope. It publishes the
complete map as `agentPolicy.execution.codingProfile` through normal Agent
publication. See `light-portal/db-provider/README.md` for the setup and contract.
Deploy the updated Portal query/command services before using this path; this
source change does not itself publish a live coding profile.

The remaining work also needs an admitted immutable repository-bundle spool,
matching template/profile digests, and an account-agent build that accepts
the same Codex 0.153.4 contract as the upgraded worker. The currently deployed
account-agent image is `networknt/light-agent:2.3.5-dev.20260903.1403`; updating
the host runner did not rebuild that container. Requalify the agent contract
before publishing a 0.153.4 profile. Do not hand-edit the generated snapshot or
insert a profile directly into operational tables to bypass publication.

## Local operation

The local enrollment is generated by `configure-local.py`. Its `.runtime/`
directory is ignored by Git, owner-only, and contains pinned runner/worker
binaries, the separately installed Codex 0.153.4 distribution, runner configuration,
admission, a private credentials-only Compose overlay, and a 30-day runner JWT. The OAuth private
key is read from the existing local database into memory and is never written
to this directory. The agent token overrides retain their existing claims and
add only `execution.invoke`.

Start the configured services from the workspace root:

```bash
./portal-config-loc/all-in-lt/light-workflow-runner-personal/start.sh
systemctl --user status light-workflow-runner-personal
curl http://127.0.0.1:9444/readyz
journalctl --user -u light-workflow-runner-personal -f
```

The user service is enabled at user-session startup. Controller port 8438 is
published only on loopback. `SSL_CERT_FILE` supplies the local CA; TLS hostname
verification stays enabled. The runner uses the existing owner-only
`~/.codex` login and a separate pinned Codex executable, leaving the normal CLI
installation unchanged.

The active native executable is `.runtime/codex-0.153.4/bin/codex` with its
complete companion distribution. The previous runtime artifact set is retained
in `.runtime/rollback-0.153.2/`. The upgrade strategy and qualification record
are in `light-fabric/docs/src/product/light-agent-worker/codex-upgrade-strategy.md`.

To verify GPT-6 Astra explicitly from the workspace root:

```bash
LIGHT_CODEX_NATIVE_EXECUTABLE="$PWD/portal-config-loc/all-in-lt/light-workflow-runner-personal/.runtime/codex-0.153.4/bin/codex" \
LIGHT_CODEX_SMOKE_MODEL=gpt-6-astra \
  ./portal-config-loc/all-in-lt/light-workflow-runner-personal/run-smoke.sh
```

Use `start.sh` to apply enrollment directly, or use `deploy-local.sh lt` for a
normal deployment after enrollment. Both use the tracked runner settings and
private execution credentials, with images selected by the release environment.

Renew the runner token before 30 days, or regenerate admission after replacing
either pinned runner/worker binary or changing its configuration:

```bash
python3 portal-config-loc/all-in-lt/light-workflow-runner-personal/configure-local.py
./portal-config-loc/all-in-lt/light-workflow-runner-personal/start.sh
systemctl --user restart light-workflow-runner-personal
```

This enrolls the native coding worker for the account agent's exact service ID.
The command allowlist contains only the generated coding template in
`.runtime/command-template.json`. The generic shell backend in the example is
still a mock; this is not a general shell/workflow execution pool. Publishing a
Portal `codingProfile` that matches these template, capability, and compatibility
digests is a separate step before dispatching coding jobs from the UI. Runner
readiness and a direct subscription smoke do not by themselves qualify that
end-to-end UI path.

This host-native profile validates the local Codex subscription path without
routing model traffic through `llm-gateway`. The runner itself remains a host
process so the native Codex client can use its own owner-scoped credential
store and the user's multi-repository workspace.

Run the smoke from the workspace root:

```bash
./portal-config-loc/all-in-lt/light-workflow-runner-personal/run-smoke.sh
```

The script requires Codex CLI `0.153.4`, an existing ChatGPT login, `psql`, and
the local `llm_audit` database. It resolves the native Codex executable behind
the npm launcher, performs one real App Server turn, and fails if the
`llm-gateway` audit row count changes.

For controller enrollment, copy `runner.yml.example`, replace every
`replace-*` value with the exact local value, make `codexHome` owner-only, and
generate the admission document with `light-workflow-runner print-admission`.
The controller runner endpoint, admission file, and a JWT with `runner.connect`
must be enabled separately; the subscription smoke does not weaken or bypass
those platform authorization requirements.

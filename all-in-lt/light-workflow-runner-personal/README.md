# Personal Codex Runner

For shared workspace tasks from GenAI Chat, follow
[Shared workspace Chat deployment](workspace-chat.md). That deployment uses a
versioned private runner directory and a systemd override; the enrollment notes
below describe the earlier baseline.

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
the base Compose file sets that value explicitly. Agent execution calls also require
`execution.invoke` on their workload credentials.

Runner enablement, admission mount, audience, loopback port, and the 180-second
initial execution lease are in the base `all-in-lt/docker-compose.yml`.
The standard developer command is `scripts/deploy-local.sh lt` from this repo.
No additional profile or workspace parameters are required. `start.sh` is a
compatibility wrapper for that same command.

The deploy script renders `.runtime/admission.json` from the installed native
runner user service before starting Compose, then starts that service. Private
`.runtime/credentials.compose.yml` credentials are included automatically.
Images continue to come from the normal release image environment. A developer
without enrollment starts with empty admission; the rest of the stack can run.
Existing credentials without an installed runner service fail preparation with
an actionable error instead of silently using stale admission.

Before stopping services, deployment checks enrolled agents' selected image for
`io.lightapi.agent.session-lifecycle=1`. A tag timestamp is not evidence of
capability because local tags may be reused. Build all updated services through
the normal release process.

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

Use `deploy-local.sh lt` for normal deployment after enrollment. The
`start.sh` wrapper uses the same tracked runner settings and
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

## codex-personal in the local stack

The base `all-in-lt/docker-compose.yml` now includes `light-agent-codex-personal`
and the controller runner admission settings. The prepared files
`.runtime/codex-personal/service.jwt` and `.runtime/codex-personal/admission.json`
are required and remain private. The native runner continues to run through the
`light-workflow-runner-personal` user systemd service with its codex-personal
configuration. The generated codex-personal Compose overlay is no longer needed
for normal stack startup.

The LLM gateway loads `${LIGHT_PORTAL_ENV_FILE}` (default
`~/.config/lightapi/light-portal.env`) directly as its service environment file.
Update provider credentials there. From `all-in-lt`, apply configuration changes
with `docker compose up -d`; `docker compose restart` alone does not apply changed
environment variables or add services. A fresh checkout must prepare the private
codex-personal runtime files before starting this stack.

## Native Codex policy and workflow models

See [the personal policy upgrade](codex-policy-upgrade.md) for the opt-in
`codex-personal-policy-v1` contract, native permissions, and `coding.nativeModel`.

# Claude personal runner

The base `all-in-lt/docker-compose.yml` runs `light-agent-claude-personal` on
loopback port 8090. Its dedicated native runner runs as the logged-in user's
`light-workflow-runner-claude-personal.service`, with health on port 9445.
Codex keeps its own Agent, runner, credential store, and sessions.

Build the native Rust worker, runner, and local Claude Agent image from the workspace:

```bash
./light-fabric/scripts/build-claude-personal-local.sh
```

Build the Java publishers through their normal build/release pipeline, including
the updated `light-portal` dependency. Select the resulting images with
`PORTAL_HYBRID_COMMAND_IMAGE` and `PORTAL_HYBRID_QUERY_IMAGE`.

Install Linux bubblewrap, Git, Python, the Rust musl target, and the pinned native
Claude Code 2.1.269 installation. Log in normally with Claude on the host. The
qualified native SHA-256 is
`25e44883f54419569a3d739f38cbbdaebe83b09895da0f343e1b003710a4775b`.
Setup resolves the executable symlink and rejects a different binary. No Claude
binary or native login is distributed inside the Agent image.

Create the `claude-personal` Agent/API and runtime instance in Portal. Supply a
local service JWT for `com.networknt.agent.claude-personal-1.0.0` with
`portal.r`, `portal.w`, and `execution.invoke`, plus a runner JWT with:

- subject `urn:lightapi:runner:personal-claude-runner`
- runner ID `personal-claude-runner`, enrollment ID `personal-claude-runner-enrollment`
- the same Host, audience `urn:lightapi:runner`, scope `runner.connect`

Tokens come from the local issuer; setup does not mint or log them. Check their
expiry and renew them through that issuer. The September 12 local qualification
uses 30-day development credentials. Native Claude login is separate.

From this directory:

```bash
python3 setup.py --fabric /absolute/workspace/light-fabric \
  --claude /absolute/path/to/claude --native-home /absolute/home/.claude \
  --runner-jwt /private/runner.jwt --service-jwt /private/service.jwt \
  --instance-id INSTANCE_UUID --ca ../light-controller-rust/ca.pem \
  --permission-mode inherit --install-user-service
```

Use `--permission-mode bypassPermissions` for an explicitly authorized unattended
machine. `inherit` preserves installed permission rules and never silently
upgrades a denied operation to bypass. The generated `claudePolicy` uses
`permissionSource: claude-cli`, a `sonnet` default and a pinned reported model.
Review/edit the generated model allowlist before publication if needed.

Setup writes `.runtime/runner.yml`, content-addressed runner/worker binaries,
private journals and spool paths, `coding-profile.json`, and a user service unit.
The `.runtime` directory is owner-only and Git-ignored. `service.jwt` is readable
by the non-root Agent through its single-file bind mount; other local users
cannot traverse its owner-only parent. No native credential file is copied.

Publish the complete generated profile at instance scope under
`agent-policy-authoring / codingProfile`. Use
`{"allowedTurnTypes":["coding"],"defaultTurnType":"coding"}` for the authoring
`turnPolicy`. Preview and publish through Portal; do not hand-edit a generated
snapshot. The publisher checks the exact local Claude contract. Qualification is
`local-qualified`; supported production distribution eligibility remains separate.

Then run the normal command, with no extra Compose overlay:

```bash
cd ../..
./scripts/deploy-local.sh lt
```

The deploy script rebuilds the Controller admission manifest from both installed
runner units, preserves each identity, restarts both units to load their installed configurations, and requires both
personal Agent containers to be healthy. It also verifies each configured runner
process against its installed executable/configuration and waits for healthy
Controller connectivity and the expected backend compatibility digest. The base Compose file selects the local
Claude Agent image; Java publishers use the standard
`PORTAL_HYBRID_COMMAND_IMAGE` and `PORTAL_HYBRID_QUERY_IMAGE` selections.
There are no Claude-specific Java image overrides. A raw `docker compose restart`
does not apply changed environment or bind mounts; use the normal deploy command.

Run the real deployment smoke after restart:

```bash
python3 -m venv /tmp/claude-smoke
/tmp/claude-smoke/bin/pip install -r /absolute/workspace/light-fabric/scripts/claude-personal-test-requirements.txt
/tmp/claude-smoke/bin/python /absolute/workspace/light-fabric/scripts/run-claude-deployment-smoke.py \
  --runtime "$PWD/all-in-lt/light-workflow-runner-claude-personal/.runtime" \
  --report /tmp/claude-deployment.json
```

The smoke uses the public Agent WebSocket admission and Controller scheduling,
checks durable fenced receipts, resumes separate implementation/review native
sessions, closes both, independently tests the patch, and requires no change in
local gateway audit rows. Run on a quiet local stack. It needs local Docker access
for receipt/audit reads and consumes native subscription usage. Failed attempts
are not silently resumed; the bounded diagnostic stays private in `.runtime`.

## Preflight, upgrades and renewal

Before replacing an installed worker, finish and close active workflow sessions.
A profile/policy change can invalidate their resume binding. Do not rewrite old
checkpoints to make them match a new profile. The normal restart sends SIGTERM
through systemd and uses the runner's existing bounded drain/cancellation; work
that cannot finish in that grace period requires explicit workflow recovery.

```bash
# Run from portal-config-loc. These commands never display credential contents.
python3 scripts/personal-runner-lifecycle.py preflight all-in-lt
python3 scripts/personal-runner-lifecycle.py check all-in-lt --timeout 90
python3 scripts/personal-runner-lifecycle.py storage all-in-lt
```

Preflight checks issuer-token expiry, installed worker/native binary pins, native
file-backed login expiry, and at least 1 GiB free on the native-state filesystem.
It runs before the normal deploy stops containers. Missing configured units,
expired credentials, pin mismatches, and disconnected runners fail explicitly;
an entirely unenrolled optional runner is skipped. Token parsing is diagnostic;
the Controller and Portal still verify signatures and identity.

For issuer-token expiry, obtain replacement service/runner JWTs from the local
issuer and rerun setup with the same Host/instance identity. Native login expiry
is separate: refresh/login using the installed Claude CLI on the host, then rerun
preflight. The worker's read-only credential mount cannot persist refreshes. Do
not turn on API-key fallback or copy credentials into an Agent image. Keychain-only
login remains outside the qualified profile.

For a worker upgrade: build, rerun setup, publish its newly generated profile
through Portal, then use `./scripts/deploy-local.sh lt`. Setup alone does not
replace the running process. The restart readiness gate rejects an old process
or backend identity even when its HTTP health endpoint returns 200. A native CLI
or reported-model change needs requalification; changing a digest to bypass the
check is not an upgrade procedure.

## State retention and independent validation

Use `storage` for an aggregate byte count, filesystem free space, and checkpoint
state counts without reading or displaying native transcripts. Check it at least
weekly and before upgrades. Native transcript/home/cache state is retained until
explicit operator cleanup; ordinary `close` is a reuse prohibition, not deletion.
The shared checkpoint implementation prunes CLOSED records after 30 days while
holding their per-thread locks; lock files are retained to preserve mutual exclusion.
Native directories are not automatically pruned with those records.

Keep READY and IN_FLIGHT/uncertain native state and checkpoints. Before manual
cleanup, stop/drain the runner and use durable workflow/job records to identify
closed conversations. Retain closed conversation data for 30 days unless the
owner's audit policy requires longer. Export required evidence first. Never use
age alone or a wildcard deletion of `.light-claude-*`: native directories may
outlive their checkpoint records, and unrecognized/orphan state needs explicit
reconciliation. Restart and run `check` afterwards. The storage command performs
no deletion; automatic native-history garbage collection is not yet qualified.

The native adapter reports no authoritative test exit-code evidence. Required
build/test gates must be fixed workflow actions on the reconstructed exact patch,
with command, exit status and artifact digest recorded independently of Claude's
prose or review verdict. The deployment smoke now independently runs a fixed
unittest suite, checks ignored build outputs stay out of the patch, and changes
the candidate between reviewer turns. This small Python fixture does not qualify
Rust/Java/Node dependency builds or arbitrary installed plugins and tools.

## Shared workspaces with the Codex runner

Both runners can use the same owner-managed workspace store. They keep separate
native conversations and runner identities. Use `setup.py --workspace-config
/path/to/workspace.json` for an initial Claude enrollment; setup preserves the
existing setting when the option is omitted. Published `workspaceBindings` must
match the runner-local bindings. Shared workspace mode uses the fixed task file
tools, with read-only inspect/review and digest-checked implementation edits.
It does not inherit native filesystem tools or expose the host checkout.

For an existing pair, `scripts/prepare-shared-native-runners.py --help` describes
the upgrade inputs. Supply both current runner configs and coding profiles, the
existing workspace configuration, the light-fabric checkout, and a new output
directory. Build both native workers and the runner first. The helper creates
versioned binaries, configs, profiles, admission, and systemd overrides without
changing registrations, credentials, published snapshots, or running services.
The registration must already authorize both Agent service IDs.

Publish each generated `coding-profile.json` through Portal authoring and publish
its new Agent policy snapshot. Install each generated `shared-workspace.conf` as
`~/.config/systemd/user/light-workflow-runner-{personal,claude-personal}.service.d/zz-shared-workspace.conf`
using the corresponding directory (Codex maps to `personal`). Run
`systemctl --user daemon-reload`, then the normal `./scripts/deploy-local.sh lt`.
On subsequent upgrades, regenerate and replace these overrides too: an older
`zz-shared-workspace.conf` continues to override the base unit created by setup.
Do not copy a config onto a running version directory.

The September 12 local enrollment uses
`.runtime/shared-native-20260912/{codex,claude}` and the existing
`~/.local/share/light-workspace` store. Authoring events are recorded in
`light-portal-event/genai/20260912-shared-native-workspace`. A new Chat session
loads the newly published workspace catalog. Workflow callers additionally need
an exact `workflow-agent:<agent-definition-UUID>` subject grant, which the helper
accepts through `--workflow-subject`; this does not enable the separate Workflow
cross-database Agent job bridge.

## One full-stack Compose deployment

`all-in-lt/docker-compose.yml` starts all services, including both personal Agents
and A2A, without Compose profiles. Use the normal `./scripts/deploy-local.sh lt`
command. Both personal enrollments and compatible images are full-stack setup
prerequisites; deployment validates enrollment and image capabilities before
stopping the existing stack. Native workers remain host user services managed by
the normal deployment script.

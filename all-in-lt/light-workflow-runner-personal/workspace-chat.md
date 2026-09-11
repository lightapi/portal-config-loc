# Shared workspace Chat deployment

The default developer Compose stack connects Portal Chat to the native personal runner. The store
stays at `/home/steve/.local/share/light-workspace`; it is not mounted into the
Agent container. The runner accesses it on the host.

## Prepare

Complete the existing personal runner enrollment and Codex login first. The
helper reads `.runtime/codex-personal/runner.yml` and `coding-profile.json`.
Use the qualified Codex installation, including its matching `codex-code-mode`
companion executable. Do not replace only the main executable.

Build `controller-rs` with the timeout-result protocol fix. The base Compose file sets
`CONTROLLER_RUNNER_RESERVATION_TTL_SECS=180`: the controller currently uses this
window for the initial execution lease too. The default 15 seconds is too short
for coding turns. The worker's 120-second Chat wall-clock limit still applies.

Build `light-agent`, `light-agent-worker`, and `light-workflow-runner` in
`light-fabric` for `x86_64-unknown-linux-musl`. Build the updated hybrid-command
and hybrid-query with `mvn -DskipTests clean package`; a package without clean can
retain stale classes in an existing shaded JAR. Build local images using the normal release image configuration. No workspace
image overlay or special image tag is needed.

For an existing operations database, apply the operational-store release bundle,
including execution-store `0002_prefixed_policy_digests`. It widens the execution
session and audit policy digests to accommodate the `sha256:` prefix. An existing
Postgres volume does not rerun initialization SQL when Compose restarts.

From `all-in-lt`, prepare a new private deployment directory:

```bash
python3 light-workflow-runner-personal/prepare-workspace-chat.py \
  --subject 01964b05-5532-7c79-8cde-191dcbd421b8 \
  --output "$PWD/light-workflow-runner-personal/.runtime/workspace-chat-20260911-v2"
```

The output directory must not exist. Use a new name for the next rebuild. The
registration must contain the actual Portal Host ID and the Codex agent grant;
`HOST_ID` is a placeholder, not a valid deployment value. Do not edit an existing
store registration or task metadata to bypass its immutability checks.

## Activate

1. In Instance Admin, open `codex-personal` → Config. Update the **authoring**
   property `agent-policy-authoring.codingProfile` with the generated
   `coding-profile.json`. Do not edit the compiled `agentPolicy.execution` value.
2. Open **Publish Agent policy**, review the preview, and activate it. The policy
   must remain coding-only and include the generated workspace binding.
3. With no active runner leases, install the generated `workspace-chat.conf` as
   `~/.config/systemd/user/light-workflow-runner-personal.service.d/workspace-chat.conf`.
   Run `systemctl --user daemon-reload` and restart the native runner to apply
   the new configuration. This is one-time enrollment or an explicit worker upgrade.
4. From the `portal-config-loc` repository, start the standard developer stack:

   ```bash
   scripts/deploy-local.sh lt
   ```

   No Compose profile, workspace overlay, or extra parameter is needed. The
   script generates `.runtime/admission.json` from the installed runner's actual
   executable and configuration before deployment. The base Compose file mounts
   that stable path. Private execution credentials are included automatically;
   normal release image selections apply to all four agents.
5. Verify `http://127.0.0.1:9444/metrics`: connected and backend healthy must be 1.
   Reconnect Chat and create a new session after changing the policy. The current
   Portal user must match the workspace binding published in step 2.

Each developer still performs their own enrollment, Codex login, workspace
registration, and policy publication. Credentials and private workspace paths
are not shared through Git. Without an enrolled runner, the same command starts
with empty runner admission; personal workspace execution remains unavailable.

## Test from Chat

Choose Shared workspace → personal → Understand code → Existing task →
`workspace-smoke-1`. Ask for the README titles in `light-fabric` and `portal-view`.
Wait for `COMPLETED` and the actual answer, not merely acceptance. Then choose
Implement changes and request a small file edit. Verify the file in the managed
task worktree and retain the returned checkpoint for follow-up.

New task provisions all registered repositories and needs Git access and known
integration branches. Large first-time provisioning may exceed the current
120-second turn deadline; pre-create the task with `light-workspace call` and use
Existing task for the initial Chat qualification. Do not resubmit uncertain
writes as a new task; inspect the durable execution and fencing state first.

The current Chat tools list repositories/files, read files, and edit files with
content checks. Tests, indexing, GitHub actions, and workflow orchestration are
separate milestones. Uninitialized empty submodules are pinned by their Git
pointer; initialized submodule contents and symlinks are rejected.

Keep the previous private deployment directory for rollback. Restore its runner
unit/admission and publish its matching authored profile together; worker and
policy digests must match. Never roll back only one side.

## Verified local result, September 11, 2026

Policy version 4 is active for `codex-personal`, with the v2 private runner
configuration and all 128 registered repositories in `workspace-smoke-1`.

| Browser request | Result |
| --- | --- |
| `01a09085-43b3-7702-bb63-9b527970f6b9` | COMPLETED; README titles from light-fabric and portal-view |
| `01a0908d-0c52-78c0-ac28-c01a28fc0260` | COMPLETED; updated and read back workspace-chat-smoke.txt in light-fabric |

The final checkpoint was
`sha256:2ef0444ebdf4bb2d6b7ae6320c06a8769229b1899d5f680df018b2d73464e4b8`.
The file contains `WORKSPACE_CHAT_E2E_OK` and `FOLLOWUP_VERIFIED`, each followed by
a newline. It exists only in the managed task worktree. No commit or push ran.
The task is ready; runner connected/healthy are 1, active leases and cleanup
backlog are 0.

Qualification exposed and fixed cross-agent outbox dispatch, the 15-second
initial lease window, TIMED_OUT reporting, and terminal replay after reconnect.
The timed-out write was retained and the task recovered with the operator's
generation fence after stopping the runner. One later model edit was rejected;
an exact-current-digest retry succeeded. Always inspect the final explanation:
COMPLETED means the agent turn finished, not that every requested edit succeeded.

The shared-workspace host-isolation gate passed 37 tests; Chat passed 26 tests.
Controller timeout tests and the live PostgreSQL reconnect/fencing regression
passed. Both documentation books build with their existing search-size warnings.
New task provisioning from Chat is not part of this live qualification.

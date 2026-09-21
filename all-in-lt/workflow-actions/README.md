# A2 local workflow action profile

This opt-in profile activates the frozen issue #374 dual-identity contracts for
the personal stack. It uses separate workflow-only Codex and Claude service and
Agent identities. Private keys and bearer tokens stay in `.runtime/active`.

Run `python3 prepare.py --output .runtime/active` while the local PostgreSQL
container is available. Review `manifest.json`, then create `.runtime/enabled`.
The normal `deploy-local.sh lt` command includes `compose.yml` when that marker
exists. Apply operational migration `0007_workflow_action_dispatch` before the
new Workflow image starts.

The preparation step creates a local A2 CA and ten-year development certificates
and app tokens signed by the local issuer, matching the local stack's checkout-and-
run fixture policy. Official environments must use managed PKI and issuer-created
app credentials with their approved rotation policy instead.

Prepared service trees are assigned to the workflow images' runtime identity
(UID/GID `999`). Private files and PKI directories stay mode `0600`/`0700`;
only the non-secret Workflow action policy is made host-readable so
`deploy-local.sh` can load it.

## Local Portal ingress qualification

`prepare-portal-ingress.py --output <new-private-runtime-directory> --activate`
is a separate, explicitly approved **development-only** addition. It creates a
dedicated `com.networknt.portal.workflow-ingress-local-1.0.0` app credential and
client certificate, both valid for one day. Like `prepare.py`, it signs the app
fixture with the local issuer key in memory; it does not write to configserver.
It preserves existing Workflow app profiles and CA certificates, saves the old
Gateway policy, then adds the interactive app/peer pair and an incoming CA bundle.
Restart `light-gateway` after activation. Never use this fixture signing path in
an official environment.

Set `PORTAL_WORKFLOW_INGRESS_CONFIG` (without a `VITE_` prefix) in the local
`portal-view/.env.local` to the generated `ingress.json`, then restart/reload
Vite. The server plugin holds the credential and mTLS key; browser requests
retain their normal session/CSRF and Gateway Tool ACL checks. Only POST `/mcp`
from `https://localhost:3000` is forwarded to fixed `https://localhost/mcp` with
certificate verification. Supplied Authorization, app token and Workflow action
headers are rejected. No user grants are fabricated. This plugin is not part of
the production bundle and is not installer qualification.

The 2026-09-14 local activation lives in
`.runtime/portal-ingress-20260914`. Its non-secret manifest records policy hashes
and the pinned client fingerprint. Gateway restarted at 21:37:33 UTC, preserving
access-control revision `809fcf46c220fa12d0647036dd87349fe2b59bf079e1343240bdf655cb66fe63`
and default-deny. Signed-in MCP initialization and catalog discovery succeeded;
the isolated Tool's published schema is visible. No invocation was submitted.
The app expires **2026-09-15 21:37:22 UTC**; do not treat this as durable deployment.

Rollback: disable `PORTAL_WORKFLOW_INGRESS_CONFIG` and restart Vite; restore the
saved `gateway-policy.previous.yml` to the exact Gateway policy bind mount and
restart Gateway. Before restoration, compare the live policy with the saved
proposed policy: if it differs, reconcile later edits rather than overwriting
them. The added CA bundle can remain unused; restoring the previous policy
restores its original CA file reference and caller set. Do not rerun preparation
over an existing directory or regenerate the A2 stack to renew this identity.

Verification: `node --test server/workflowIngress.test.mjs` in `portal-view`
passes seven tests. The existing client/dialog/fetch suite passes 20 tests.
Live anonymous direct MCP and forged-session ingress requests return 401;
foreign Origin, supplied app identity, duplicate CSRF cookies and a runtime
credential-file URL return 403. HTTP/2 split Cookie fields are joined per RFC
9113 section 8.2.3, but duplicate authentication cookie names remain rejected.

## Light CLI: user token only

The Light CLI is open source and downloadable anywhere, so it cannot keep an application secret
or certificate. It calls `/mcp` with the signed-in user's token alone. `prepare.py` sets
`interactiveUserOnly` in the Gateway's caller policy, and `prepare-light-cli.py` does the same to
an already-running Gateway. A request with **no** application credential (`x-scope-token`) is then
admitted on its user token, as an interactive caller with no action reference. Anyone who does
present an application credential is judged exactly as before, and a request that claims a
workflow action without one is refused. What a CLI user may do is decided by their roles and the
route's ACL.

```sh
python3 prepare-light-cli.py                 # prepare and show; changes nothing
python3 prepare-light-cli.py --activate      # install, restart the Gateway, verify
python3 prepare-light-cli.py --rollback DIR  # restore what DIR saved
```

The Gateway image must be a build that knows `interactiveUserOnly` (an older one refuses to start
on the unknown field; `--activate` then restores the previous policy itself). The script also removes
the `com.networknt.light-cli-1.0.0` certificate profile an earlier version added. It is idempotent,
and keeps the saved previous policy in the output directory under `.runtime/`.

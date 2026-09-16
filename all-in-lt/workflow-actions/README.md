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

# Workflow Invoke local setup

Use `./scripts/deploy-local.sh lt` for the full local stack. The main Compose
file selects `networknt/light-workflow:2.3.5-dev.20260909.2338` by default.
The Workflow run credential keyring is prepared idempotently by the runtime
secrets init service. Configure `workflow.publication.publisherClientIds` to
include the Portal hybrid-command client-credentials client ID, then assign
the Gateway MCP and Portal command ACLs described in the
[Workflow Invoke operator setup](https://doc.lightapi.net/product/light-workflow/workflow-invoke.html).

Portal sends definition, grant, and Tool binding publication through Gateway
MCP. The Portal has no direct Workflow operations database publishing path.
Gateway accepts JWT-only operation; mTLS can be configured later. Clients call
the published workflow-backed Tool, not Workflow's internal `workflow_invoke`.

# Agent bootstrap configuration

Each deployed Agent has its own `/config` bind mount:

| Compose service | Config directory | Service ID |
| --- | --- | --- |
| light-agent (Account) | light-agent-account-rust/config | com.networknt.agent.account-1.0.0 |
| light-agent-advisor | light-agent-advisor-rust/config | com.networknt.agent.advisor-1.0.0 |
| light-agent-tech-support | light-agent-tech-support-rust/config | com.networknt.agent.tech-support-1.0.0 |
| light-agent-codex-personal | light-agent-codex-personal-rust/config | com.networknt.agent.codex-personal-1.0.0 |

Each directory contains only `startup.yml`, `ca.pem`, `cert.pem`, and `key.pem`.
These PEM files use the existing local-development certificate material. Bootstrap
uses the CA; cert/key are available for an instance that enables HTTPS remotely.
Do not add local `agent.yml`, `client.yml`, `portal-registry.yml`, or `values.yml`.
The Agent image supplies its module templates, and Config Server supplies the
instance values. A downloaded cache is container-local under `/app/config-cache`.

`startup.yml` supplies the host/service/environment identity, Config Server URL,
bootstrap CA, timeouts, and cache location. Authorization remains a private
runtime credential supplied by Compose. Runtime transport settings (ports,
advertised addresses, registry/query URLs, MCP transport, and client TLS) belong
to the corresponding Portal instance properties; the publisher owns signed
Agent policy settings.

The migration is in sibling repository
`light-portal-event/config/20260910-agent-bootstrap-only/`. It was applied to the
local four Agent instances and their current Config Server snapshots were refreshed
before recreation. Fresh databases and installer release bundles must include
these remote transport settings before using this layout. This migration does not
publish the separate explicit-turn-policy feature.

Use the normal deployment script to retain enrolled-runner credential overlays.
For manual Compose commands on this enrolled installation, include
`-f light-workflow-runner-personal/compose.yml` and
`-f light-workflow-runner-personal/.runtime/credentials.compose.yml` along with
`-f docker-compose.yml`; the private overlay contains execution-scoped credentials.
No separate codex-personal Compose overlay is needed for the base service.

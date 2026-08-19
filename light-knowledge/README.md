# Local Knowledge runtime

The Knowledge image supplies the canonical `knowledge.yml`, `worker.yml`, and
bootstrap configuration. Deployment overrides come from the Config Server
snapshot for `lk` version `1.0.0`; this repository does not mount local copies
of those files into the container.

Compose supplies database URLs and local-only delegation/cache/heartbeat
values through environment variables. `LIGHT_PORTAL_AUTHORIZATION` is the
long-lived service token used to fetch the Config Server snapshot and register
with the controller. The protected Portal command and `kb-index`/`kb-query`
lanes may still use independently scoped authorization values.

The builder trusts the development CA committed at
`all-in-lt/light-controller-rust/ca.pem`. Compose mounts that repository-local
file at `/keystore/ca.pem`; it has no dependency on a sibling `keystore`
checkout. Local hostname verification is disabled because the shared
development certificate does not contain the Compose DNS name. Production
must use a CA-issued certificate with a matching SAN and enable hostname
verification.

When the periodically rotated service token changes, override the shared value
with `LIGHT_PORTAL_AUTHORIZATION` or update its Compose default. The three
call paths can still be overridden independently with:

- `KNOWLEDGE_PORTAL_AUTHORIZATION`
- `KNOWLEDGE_INDEX_EMBEDDING_AUTHORIZATION`
- `KNOWLEDGE_QUERY_EMBEDDING_AUTHORIZATION`

`LIGHT_AGENT_DELEGATION_SECRET` remains a separate local override because it
protects agent delegation rather than service-to-service JWT authentication.

The application and workers run with the local host identity so their bind
mounted object and checkout directories remain writable. `deploy-local.sh`
derives `LOCAL_UID` and `LOCAL_GID` from the current account. Developers can
override both values when invoking Compose through another runtime boundary.

The protected `kb-index` and `kb-query` public Aliases must set **Bound
Workload Principal** to the `sub` claim of the configured service token. For
the checked-in local token that value is
`019ff2f7-e56e-758a-a17b-45b057556326`. Change the Alias through the LLM Model
Control Plane while logged in as a platform administrator; the service token
is not an authorization-code token and cannot administer its own Alias.

Only public-model provider credentials such as `NVIDIA_API_KEY` need to be
supplied for the normal local setup. Production Kubernetes deployments should
continue to mount separately scoped database credentials, delegation keys,
and rotated workload identities rather than using these local defaults.

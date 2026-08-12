# Local Knowledge runtime

The `all-in-lt` Compose stack creates the Knowledge runtime configuration in
the `light-knowledge-runtime` named volume. Developers do not create or manage
service-token or database-URL files.

`light-knowledge-bootstrap` derives the local PostgreSQL URLs from the Compose
service, writes deterministic local-only delegation/cache/heartbeat values,
and writes the checked-in local `light-knowledge` service token to the three
runtime authorization files. The same token is used for Portal promotion
acknowledgements and the protected `kb-index`/`kb-query` embedding lanes.

When the periodically rotated service token changes, override the shared value
with `LIGHT_KNOWLEDGE_AUTHORIZATION` or update its Compose default. The three
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

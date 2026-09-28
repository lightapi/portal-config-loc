# Local PostgreSQL connection budget

The full Compose stack keeps five base Agents and two Workflow action Agents running. Each Agent has a query pool capped at four connections and a separate notification listener. Workflow has a query pool capped at 16 connections, four host executor workers, and a separate listener per worker. These are upper bounds, not connections reserved at startup.

At those caps, Agents can use up to 28 connections (7 × (4 + 1)) and Workflow up to 20 (16 + 4). Gateway and other services also use PostgreSQL, so the local PostgreSQL cap is 200 rather than the server default of 100. Three PostgreSQL slots remain reserved for superusers.

`LIGHT_AGENT_DB_MAX_CONNECTIONS`, `WORKFLOW_DB_MAX_CONNECTIONS`, `WORKFLOW_HOST_EXECUTOR_CONCURRENCY`, and `POSTGRES_MAX_CONNECTIONS` override the local Compose defaults. Size them together under a representative concurrent workload. Check `pg_stat_activity` and `SHOW max_connections` after redeployment; a Compose or source change alone does not establish runtime headroom. The new Agent setting requires an image built from the corresponding light-fabric change.

See [networknt/implementation#103](https://github.com/networknt/implementation/issues/103) for the cross-deployment sizing work.

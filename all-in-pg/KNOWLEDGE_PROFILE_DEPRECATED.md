# Knowledge profile status

The `all-in-pg` Knowledge profile is retired because it uses the pre-snapshot
clone/projector topology. It is deliberately registered as
`knowledge-legacy-unsupported` and is not a supported deployment target.

Use `portal-config-loc/all-in-lt` for local Knowledge development and
qualification. That topology contains the separate `light-knowledge` and
`light-knowledge-admin` services, recurring signed control snapshots, and the
canonical Knowledge database bootstrap. The normal Config Server stack here no
longer runs the legacy Knowledge bootstrap implicitly.

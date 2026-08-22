# Knowledge topology status

The pre-snapshot `all-in-pg` Knowledge services were removed rather than kept
behind an opt-in profile. Starting this Compose application therefore cannot
accidentally launch the retired clone/projector topology.

Use `portal-config-loc/all-in-lt` for local Knowledge development and
qualification. That topology contains the separate `light-knowledge` and
`light-knowledge-admin` services, recurring signed control snapshots, and the
canonical Knowledge database bootstrap. The normal Config Server stack here no
longer contains the legacy Knowledge bootstrap or service definitions.

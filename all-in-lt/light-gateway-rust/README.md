# Local portal gateway configuration

The Rust portal gateway loads the current Config Server snapshot for
`com.networknt.portal.gateway-1.0.0` with environment tag `loc` when the
container starts.

After importing an event that changes an instance-level gateway property,
wait for the projection and publish a new current snapshot:

```bash
cd ~/workspace/portal-config-loc/all-in-lt/light-gateway-rust
./publish-current-snapshot.sh
docker restart light-gateway
```

Use a rollback-only dry run to verify the instance and snapshot procedure:

```bash
PORTAL_GATEWAY_SNAPSHOT_DRY_RUN=true ./publish-current-snapshot.sh
```

For the promotion recovery endpoint, verify that the active snapshot contains
the access-control rule before restarting the gateway:

```bash
PGPASSWORD=secret psql -h localhost -U postgres -d configserver -Atc \
  "select p.property_value::jsonb ? 'lightapi.net/user/promotionRecovery/0.1.0'
     from configserver.config_snapshot_t s
     join configserver.config_snapshot_property_t p using (snapshot_id)
    where s.instance_id = '26ecfd54-5239-5d87-a82a-e335b2a2da22'
      and s.current
      and p.property_name = 'endpointRules';"
```

The expected result is `t`.

Here is the working config for portal-event topic with Timestamp support. 


```
{
  "name": "outbox-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "secret",
    "database.dbname": "configserver",
    "database.server.name": "postgres",
    "topic.prefix": "portal-event", 

    "schema.include.list": "public",
    "table.include.list": "public.outbox_message_t",

    "plugin.name": "pgoutput",
    "publication.name": "dbz_publication",
    "slot.name": "dbz_replication_slot",

    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",

    "transforms": "unwrap,timestamp_converter,outbox,final_route", 

    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.delete.handling.mode": "none",

    "transforms.timestamp_converter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.timestamp_converter.field": "event_ts",
    "transforms.timestamp_converter.target.type": "Timestamp",
    "transforms.timestamp_converter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",

    "transforms.outbox.type": "io.debezium.transforms.outbox.EventRouter",

    "transforms.outbox.table.field.event.id": "id",
    "transforms.outbox.table.field.event.key": "user_id",
    "transforms.outbox.table.field.event.type": "event_type",
    "transforms.outbox.table.field.event.timestamp": "event_ts",
    "transforms.outbox.table.field.event.payload": "payload",
    "transforms.outbox.table.field.event.metadata": "metadata",

    "transforms.outbox.table.field.aggregate.type": "aggregate_type",
    "transforms.outbox.table.field.aggregate.id": "aggregate_id",

    "transforms.final_route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.final_route.regex": "portal-event\\.public\\.outbox_message_t", 
    "transforms.final_route.replacement": "portal-event"
  }
}
```

The issue with above configuration:

1. The id is used as topic key. 
2. The json is used for the key and value

We need to use user_id column as key and payload as value. 

Here is the configuration that has user_id as key. In the config, we have defined message.key.columns to be user_id and also use extractKey to remove all struct info to leave only the user_id as the key. 


```
{
  "name": "outbox-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "secret",
    "database.dbname": "configserver",
    "database.server.name": "postgres",
    "topic.prefix": "portal-event", 

    "schema.include.list": "public",
    "table.include.list": "public.outbox_message_t",
    "message.key.columns": "public.outbox_message_t:user_id",

    "plugin.name": "pgoutput",
    "publication.name": "dbz_publication",
    "slot.name": "dbz_replication_slot",

    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": "false",

    "transforms": "unwrap,extractKey,timestamp_converter,outbox,final_route", 

    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.delete.handling.mode": "none",

    "transforms.extractKey.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.extractKey.field": "user_id",

    "transforms.timestamp_converter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.timestamp_converter.field": "event_ts",
    "transforms.timestamp_converter.target.type": "Timestamp",
    "transforms.timestamp_converter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",

    "transforms.outbox.type": "io.debezium.transforms.outbox.EventRouter",

    "transforms.outbox.table.field.event.id": "id",
    "transforms.outbox.table.field.event.key": "user_id",
    "transforms.outbox.table.field.event.type": "event_type",
    "transforms.outbox.table.field.event.timestamp": "event_ts",
    "transforms.outbox.table.field.event.payload": "payload",
    "transforms.outbox.table.field.event.metadata": "metadata",

    "transforms.outbox.table.field.aggregate.type": "aggregate_type",
    "transforms.outbox.table.field.aggregate.id": "aggregate_id",

    "transforms.final_route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.final_route.regex": "portal-event\\.public\\.outbox_message_t", 
    "transforms.final_route.replacement": "portal-event"
  }
}

```

This is the final version that has payload as the Kafka value. 

```
{
  "name": "outbox-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "secret",
    "database.dbname": "configserver",
    "database.server.name": "postgres",
    "topic.prefix": "portal-event", 

    "schema.include.list": "public",
    "table.include.list": "public.outbox_message_t",
    "message.key.columns": "public.outbox_message_t:user_id",

    "plugin.name": "pgoutput",
    "publication.name": "dbz_publication",
    "slot.name": "dbz_replication_slot",

    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter.schemas.enable": "false",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": "false",

    "transforms": "unwrap,timestamp_converter,extractPayload,extractKey,outbox,final_route", 

    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.delete.handling.mode": "none",

    "transforms.timestamp_converter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.timestamp_converter.field": "event_ts",
    "transforms.timestamp_converter.target.type": "Timestamp",
    "transforms.timestamp_converter.format": "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",

    "transforms.extractPayload.type": "org.apache.kafka.connect.transforms.ExtractField$Value",
    "transforms.extractPayload.field": "payload",
    "transforms.extractPayload.parse.json": "true",

    "transforms.extractKey.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.extractKey.field": "user_id",

    "transforms.outbox.type": "io.debezium.transforms.outbox.EventRouter",
    "transforms.outbox.table.field.event.id": "id",
    "transforms.outbox.table.field.event.key": "user_id",
    "transforms.outbox.table.field.event.type": "event_type",
    "transforms.outbox.table.field.event.timestamp": "event_ts",
    "transforms.outbox.table.field.event.payload": "payload",
    "transforms.outbox.table.field.event.metadata": "metadata",
    "transforms.outbox.table.field.aggregate.type": "aggregate_type",
    "transforms.outbox.table.field.aggregate.id": "aggregate_id",

    "transforms.final_route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.final_route.regex": "portal-event\\.public\\.outbox_message_t", 
    "transforms.final_route.replacement": "portal-event"
  }
}

```

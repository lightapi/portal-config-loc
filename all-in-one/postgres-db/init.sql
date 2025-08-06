CREATE DATABASE configserver;
\c configserver;

DROP TABLE IF EXISTS tag_t CASCADE;

DROP TABLE IF EXISTS entity_tag_t CASCADE;

DROP TABLE IF EXISTS category_t CASCADE;

DROP TABLE IF EXISTS entity_category_t CASCADE;

DROP TABLE IF EXISTS schema_t CASCADE;

DROP TABLE IF EXISTS rule_group_t CASCADE;

DROP TABLE IF EXISTS rule_t CASCADE;

DROP TABLE IF EXISTS api_endpoint_rule_t CASCADE;

DROP TABLE IF EXISTS api_endpoint_t CASCADE;

DROP TABLE IF EXISTS deployment_instance_property_t CASCADE;

DROP TABLE IF EXISTS deployment_instance_t CASCADE;

DROP TABLE IF EXISTS instance_t CASCADE;

DROP TABLE IF EXISTS api_scope_t CASCADE;

DROP TABLE IF EXISTS api_t CASCADE;

DROP TABLE IF EXISTS api_version_t CASCADE;

DROP TABLE IF EXISTS app_api_t CASCADE;

DROP TABLE IF EXISTS app_t CASCADE;

DROP TABLE IF EXISTS chain_handler_t CASCADE;

DROP TABLE IF EXISTS config_property_t CASCADE;

DROP TABLE IF EXISTS config_t CASCADE;

DROP TABLE IF EXISTS environment_property_t CASCADE;

DROP TABLE IF EXISTS instance_api_path_prefix_t;

DROP TABLE IF EXISTS instance_api_property_t CASCADE;

DROP TABLE IF EXISTS instance_api_t CASCADE;

DROP TABLE IF EXISTS instance_app_api_t CASCADE;

DROP TABLE IF EXISTS instance_app_property_t CASCADE;

DROP TABLE IF EXISTS instance_app_api_property_t CASCADE;

DROP TABLE IF EXISTS instance_app_t CASCADE;

DROP TABLE IF EXISTS instance_path_t CASCADE;

DROP TABLE IF EXISTS instance_property_t CASCADE;

DROP TABLE IF EXISTS network_zone_t CASCADE;

DROP TABLE IF EXISTS instance_file_t CASCADE;

DROP TABLE IF EXISTS product_property_t CASCADE;

DROP TABLE IF EXISTS product_version_property_t CASCADE;

DROP TABLE IF EXISTS product_version_config_t CASCADE;

DROP TABLE IF EXISTS product_version_config_property_t CASCADE;

DROP TABLE IF EXISTS product_version_environment_t CASCADE;

DROP TABLE IF EXISTS product_version_t CASCADE;

DROP TABLE IF EXISTS platform_t CASCADE;

DROP TABLE IF EXISTS pipeline_t CASCADE;

DROP TABLE IF EXISTS snapshot_product_version_property_t CASCADE;

DROP TABLE IF EXISTS snapshot_product_property_t CASCADE;

DROP TABLE IF EXISTS snapshot_environment_property_t CASCADE;

DROP TABLE IF EXISTS snapshot_instance_property_t CASCADE;

DROP TABLE IF EXISTS snapshot_instance_app_api_property_t CASCADE;

DROP TABLE IF EXISTS snapshot_instance_app_property_t CASCADE;

DROP TABLE IF EXISTS snapshot_instance_api_property_t CASCADE;

DROP TABLE IF EXISTS config_snapshot_property_t CASCADE;

DROP TABLE IF EXISTS config_snapshot_t CASCADE;

DROP TABLE IF EXISTS deployment_t CASCADE;

DROP TABLE IF EXISTS product_version_pipeline_t CASCADE;

DROP TABLE IF EXISTS runtime_instance_t CASCADE;

DROP TABLE IF EXISTS api_endpoint_scope_t CASCADE;

DROP TABLE IF EXISTS host_t CASCADE;

DROP TABLE IF EXISTS org_t CASCADE;

DROP table IF EXISTS relation_t CASCADE;;

DROP table IF EXISTS relation_type_t CASCADE;

DROP table IF EXISTS value_locale_t CASCADE;

DROP table IF EXISTS ref_value_t CASCADE;

DROP table IF EXISTS ref_table_t CASCADE;

DROP table IF EXISTS attribute_permission_t CASCADE;

DROP table IF EXISTS attribute_row_filter_t CASCADE;

DROP table IF EXISTS attribute_col_filter_t CASCADE;

DROP table IF EXISTS attribute_user_t CASCADE;

DROP table IF EXISTS attribute_t CASCADE;

DROP table IF EXISTS group_user_t CASCADE;

DROP table IF EXISTS group_permission_t CASCADE;

DROP table IF EXISTS group_row_filter_t CASCADE;

DROP table IF EXISTS group_col_filter_t CASCADE;

DROP table IF EXISTS group_t CASCADE; -- move to ref

DROP table IF EXISTS user_permission_t CASCADE;

DROP table IF EXISTS user_row_filter_t CASCADE;

DROP table IF EXISTS user_col_filter_t CASCADE;

DROP table IF EXISTS role_user_t CASCADE;

DROP table IF EXISTS role_permission_t CASCADE;

DROP table IF EXISTS role_row_filter_t CASCADE;

DROP table IF EXISTS role_col_filter_t CASCADE;

DROP table IF EXISTS role_t CASCADE;

DROP table IF EXISTS position_permission_t;

DROP table IF EXISTS position_row_filter_t;

DROP table IF EXISTS position_col_filter_t;

DROP table IF EXISTS employee_position_t CASCADE;

DROP table IF EXISTS position_t CASCADE;

DROP table IF EXISTS employee_t CASCADE;

DROP table IF EXISTS customer_t CASCADE;

DROP table IF EXISTS user_crypto_wallet_t CASCADE;

DROP table IF EXISTS user_host_t CASCADE;

DROP TABLE IF EXISTS user_t CASCADE;

DROP TABLE IF EXISTS auth_refresh_token_t CASCADE;

DROP TABLE IF EXISTS auth_code_t CASCADE;

DROP TABLE IF EXISTS auth_ref_token_t CASCADE;

DROP TABLE IF EXISTS auth_client_t CASCADE;

DROP TABLE IF EXISTS auth_provider_client_t CASCADE;

DROP TABLE IF EXISTS auth_provider_api_t CASCADE;

DROP TABLE IF EXISTS auth_provider_key_t CASCADE;

DROP TABLE IF EXISTS auth_provider_t CASCADE;

DROP TABLE IF EXISTS notification_t CASCADE;

DROP TABLE IF EXISTS message_t CASCADE;

DROP TABLE IF EXISTS config_property_t CASCADE;

DROP TABLE IF EXISTS audit_log_t CASCADE;
DROP TABLE IF EXISTS task_asst_t CASCADE;
DROP TABLE IF EXISTS task_info_t CASCADE;
DROP TABLE IF EXISTS process_info_t CASCADE;
DROP TABLE IF EXISTS worklist_column_t CASCADE;
DROP TABLE IF EXISTS worklist_t CASCADE;
DROP TABLE IF EXISTS event_store_t CASCADE;
DROP TABLE IF EXISTS outbox_message_t CASCADE;


CREATE TABLE event_store_t (
    id UUID PRIMARY KEY,                   -- Unique ID for the event itself
    host_id UUID NOT NULL,                 -- host_id will be the Kafka key for multi-tenancy
    user_id UUID NOT NULL,                 -- user_id will be the Kafka key for single-tenancy  
    nonce BIGINT NOT NULL,                 -- The nonce per user sequence number
    aggregate_id VARCHAR(255) NOT NULL,    -- The ID of the aggregate (e.g., customer-123)
    aggregate_version BIGINT DEFAULT 1 NOT NULL,     -- Monotonically increasing sequence number per aggregate
    aggregate_type VARCHAR(255) NOT NULL,  -- The type of aggregate (e.g., 'Customer')
    event_type VARCHAR(255) NOT NULL,      -- The specific type of event (e.g., 'CustomerNameChanged')
    event_ts TIMESTAMP WITH TIME ZONE NOT NULL, -- When the event occurred
    payload JSONB NOT NULL,                -- The full event payload (JSON)
    metadata JSONB,                        -- Optional: correlation IDs, causation IDs, user ID, etc.
    -- Constraints for event order and uniqueness per aggregate
    UNIQUE (user_id, nonce),
    UNIQUE (aggregate_id, aggregate_version)
);

-- Index for efficient lookup by aggregate
CREATE INDEX idx_event_store_aggregate ON event_store_t (aggregate_id);

CREATE TABLE outbox_message_t (
    id UUID PRIMARY KEY,                   -- Unique ID for this outbox message
    host_id UUID NOT NULL,                 -- host_id will be the Kafka key for multi-tenancy
    user_id UUID NOT NULL,                 -- user_id will be the Kafka key for single-tenancy
    nonce BIGINT NOT NULL,                 -- The nonce per user sequence number
    aggregate_id VARCHAR(255) NOT NULL,    -- The ID of the aggregate (for Kafka key)
    aggregate_version BIGINT DEFAULT 1 NOT NULL,     -- Monotonically increasing sequence number per aggregate
    aggregate_type VARCHAR(255) NOT NULL,  -- The type of aggregate (for Kafka topic routing)
    event_type VARCHAR(255) NOT NULL,      -- The specific type of event
    event_ts TIMESTAMP WITH TIME ZONE NOT NULL, -- When the event was created
    payload JSONB NOT NULL,                -- The full event payload (JSON)
    metadata JSONB                         -- Optional: correlation IDs, causation IDs, user ID, etc.
    -- Note: No sequence_number here, as the Event Store manages that.
    -- Debezium will process these by insertion order.
);
-- An index on timestamp can be useful for manual cleanup or if not using CDC
-- CREATE INDEX idx_outbox_timestamp ON outbox_messages (timestamp);


CREATE TABLE schedule_t (
    schedule_id          UUID NOT NULL, -- unique id for schedule event.
    host_id              UUID NOT NULL,
    schedule_name        VARCHAR(126) NOT NULL,
    frequency_unit       VARCHAR(16) NOT NULL,
    frequency_time       INTEGER NOT NULL,
    start_ts             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    event_topic          VARCHAR(126) NOT NULL,
    event_type           VARCHAR(126) NOT NULL,
    event_data           TEXT NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(schedule_id)
);

CREATE INDEX idx_schedule_host_id ON schedule_t (host_id);


CREATE TABLE tag_t (
    tag_id               UUID NOT NULL,   -- unique id to identify the category
    host_id              UUID,            -- null mean global category
    entity_type          VARCHAR(50) NOT NULL,   -- entity type
    tag_name             VARCHAR(126) NOT NULL CHECK (
        tag_name = LOWER(tag_name) AND
        tag_name ~ '^[a-z0-9_-]+$'
    ),  -- tag name must be lower case and url friendly.
    tag_desc             VARCHAR(1024),          -- decription
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (tag_id)
);

-- 1. Unique index for GLOBAL tags (where host_id IS NULL)
-- Ensures uniqueness of (entity_type, tag_name) ONLY when host_id is NULL
CREATE UNIQUE INDEX idx_tag_unique_global
ON tag_t (entity_type, tag_name)
WHERE host_id IS NULL;

-- 2. Unique index for TENANT-SPECIFIC tags (where host_id IS NOT NULL)
-- Ensures uniqueness of (host_id, entity_type, tag_name)
-- for rows that belong to a specific host.
CREATE UNIQUE INDEX idx_tag_unique_tenant
ON tag_t (host_id, entity_type, tag_name)
WHERE host_id IS NOT NULL;


CREATE INDEX idx_tag_entity_type ON tag_t (entity_type);
CREATE INDEX idx_tag_name ON tag_t (tag_name);
CREATE INDEX idx_tag_host_id ON tag_t (host_id);

CREATE TABLE entity_tag_t (
    entity_id             UUID NOT NULL,
    entity_type           VARCHAR(50) NOT NULL,
    tag_id                UUID NOT NULL REFERENCES tag_t(tag_id) ON DELETE CASCADE,
    aggregate_version     BIGINT DEFAULT 1 NOT NULL,
    update_user           VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (entity_id, entity_type, tag_id)
);

CREATE INDEX idx_entity_tag_id ON entity_tag_t (tag_id);
CREATE INDEX idx_entity_tag_entity ON entity_tag_t (entity_id, entity_type);


CREATE TABLE category_t (
    category_id          UUID NOT NULL,   -- unique id to identify the category
    host_id              UUID,            -- null mean global category
    entity_type          VARCHAR(50) NOT NULL,   -- the entity type
    category_name        VARCHAR(126) NOT NULL CHECK (
        category_name = LOWER(category_name) AND
        category_name ~ '^[a-z0-9_-]+$'
    ),  -- category name, must be lower case and url friendly.
    category_desc        VARCHAR(1024),          -- decription
    parent_category_id   UUID REFERENCES category_t(category_id) ON DELETE SET NULL, -- parent category id, null if there is no parent.
    sort_order           INT DEFAULT 0,          -- sort order on the UI
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (category_id)
);

-- 1. Unique index for GLOBAL categories (where host_id IS NULL)
-- Ensures uniqueness of (entity_type, category_name, parent_category_id) ONLY when host_id is NULL
CREATE UNIQUE INDEX idx_category_unique_global
ON category_t (entity_type, category_name, parent_category_id)
NULLS NOT DISTINCT -- Handles NULLs in parent_category_id correctly
WHERE host_id IS NULL;

-- 2. Unique index for TENANT-SPECIFIC categories (where host_id IS NOT NULL)
-- Ensures uniqueness of (host_id, entity_type, category_name, parent_category_id)
-- for rows that belong to a specific host.
CREATE UNIQUE INDEX idx_category_unique_tenant
ON category_t (host_id, entity_type, category_name, parent_category_id)
NULLS NOT DISTINCT -- Handles NULLs in parent_category_id correctly
WHERE host_id IS NOT NULL;


CREATE INDEX idx_category_entity_type ON category_t (entity_type);
CREATE INDEX idx_category_parent ON category_t (parent_category_id);
CREATE INDEX idx_category_name ON category_t (category_name);
CREATE INDEX idx_category_host_id ON category_t (host_id);

CREATE TABLE entity_category_t (
    entity_id             UUID NOT NULL,
    entity_type           VARCHAR(50) NOT NULL,
    category_id           UUID NOT NULL REFERENCES category_t(category_id) ON DELETE CASCADE,
    aggregate_version     BIGINT DEFAULT 1 NOT NULL,
    update_user           VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (entity_id, entity_type, category_id)
);

CREATE INDEX idx_entity_category_id ON entity_category_t (category_id);
CREATE INDEX idx_entity_category_entity ON entity_category_t (entity_id, entity_type);

CREATE TABLE schema_t (
    schema_id            VARCHAR(126) NOT NULL CHECK (
        schema_id = LOWER(schema_id) AND
        schema_id ~ '^[a-z0-9_-]+$'
    ),  -- schema id, must be lower case and url friendly and uniquely identify a schema
    host_id              UUID,            -- null means global schema
    schema_version       VARCHAR(12) NOT NULL,   -- the version of the schema
    schema_type          VARCHAR(16) NOT NULL,   -- schema type
    spec_version         VARCHAR(12) NOT NULL,   -- schema specification version
    schema_source        VARCHAR(126) NOT NULL,  -- which api or app owns the schema
    schema_name          VARCHAR(126) NOT NULL,  -- schema name
    schema_desc          VARCHAR(1024),          -- description of the schema
    schema_body          VARCHAR(65535) NOT NULL,-- schema body 
    schema_owner         VARCHAR(126) NOT NULL,  -- schema owner
    schema_status        CHAR(1) DEFAULT 'P' NOT NULL,  -- D draft P published R retired
    example              VARCHAR(65535),         -- json example
    comment_status       CHAR(1) DEFAULT 'O' NOT NULL, -- comment open or closed. O open C close
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (schema_id)
);

ALTER TABLE schema_t
    ADD CHECK ( schema_status IN ('D', 'P', 'R'));

-- Ensures uniqueness of (schema_id, schema_version) ONLY when host_id is NULL
CREATE UNIQUE INDEX idx_schema_unique_global
ON schema_t (schema_id, schema_version)
WHERE host_id IS NULL;

-- 2. Unique index for TENANT-SPECIFIC schemas (where host_id IS NOT NULL)
-- Ensures uniqueness of (host_id, schema_id, schema_version)
-- for rows that belong to a specific host.
CREATE UNIQUE INDEX idx_schema_unique_tenant
ON schema_t (host_id, schema_id, schema_version)
WHERE host_id IS NOT NULL;


-- Add index on host_id for efficient tenant-specific lookups
CREATE INDEX idx_schema_host_id ON schema_t (host_id);
-- Add index on schema_name for lookups by name
CREATE INDEX idx_schema_schema_name ON schema_t (schema_name);
-- Add index on schema_type for filtering by schema type
CREATE INDEX idx_schema_schema_type ON schema_t (schema_type);

-- all entities that can potentially share between hosts will not have host_id column.

CREATE TABLE rule_t (
    rule_id              VARCHAR(255) NOT NULL, -- com.networknt.rule01. or rule01.networknt.com.
    host_id              UUID,                  -- null for global rule
    rule_name            VARCHAR(128) NOT NULL, -- easy to remember name.
    rule_version         VARCHAR(32) NOT NULL,  -- version that follows major.minor.patch pattern.
    rule_type            VARCHAR(32) NOT NULL,
    rule_group           VARCHAR(64),           -- set up several rules with the same group to execute them together.
    rule_desc            VARCHAR(1024),
    rule_body            VARCHAR(65535) NOT NULL,
    rule_owner           VARCHAR(64) NOT NULL,
    common               CHAR(1) DEFAULT 'N' NOT NULL, -- keep it for backward compitable. default to 'N'
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (rule_id)
);

ALTER TABLE rule_t
    ADD CHECK ( common IN ('Y', 'N'));

-- Ensures uniqueness of (rule_id) ONLY when host_id is NULL
CREATE UNIQUE INDEX idx_rule_unique_global
ON rule_t (rule_id)
WHERE host_id IS NULL;

-- Ensures uniqueness of (host_id, rule_id) for rows that belong to a specific host.
CREATE UNIQUE INDEX idx_rule_unique_tenant
ON rule_t (host_id, rule_id)
WHERE host_id IS NOT NULL;

-- Add index on host_id for efficient tenant-specific lookups
CREATE INDEX idx_rule_host_id ON rule_t (host_id);


-- define a list of rules that needs to be executed together in sequence.
CREATE TABLE rule_group_t (
    group_id             VARCHAR(64) NOT NULL,
    rule_id              VARCHAR(255) NOT NULL,
    host_id              UUID,                 -- null for global rule group.
    group_name           VARCHAR(128) NOT NULL,
    execute_sequence     INT NOT NULL,         -- execute sequence for the rule_id in the group.
    group_desc           VARCHAR(4000),
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(group_id, rule_id)
);

-- Ensures uniqueness of (group_id, rule_id) ONLY when host_id is NULL
CREATE UNIQUE INDEX idx_rule_group_unique_global
ON rule_group_t (group_id, rule_id)
WHERE host_id IS NULL;

-- Ensures uniqueness of (host_id, group_id, rule_id) for rows that belong to a specific host.
CREATE UNIQUE INDEX idx_rule_group_unique_tenant
ON rule_group_t (host_id, group_id, rule_id)
WHERE host_id IS NOT NULL;

-- Add index on host_id for efficient tenant-specific lookups
CREATE INDEX idx_rule_group_host_id ON rule_group_t (host_id);

-- api must associate with a host, so host_id is in this table.
CREATE TABLE api_endpoint_rule_t (
    host_id              UUID NOT NULL,
    endpoint_id          UUID NOT NULL,
    rule_id              VARCHAR(255) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL

);
ALTER TABLE api_endpoint_rule_t ADD CONSTRAINT api_rule_pk PRIMARY KEY ( host_id, endpoint_id, rule_id);


CREATE TABLE api_t (
    host_id                 UUID NOT NULL,
    api_id                  VARCHAR(16) NOT NULL,    -- unique identifier within the org/host.
    api_name                VARCHAR(128) NOT NULL,
    api_desc                VARCHAR(1024),
    operation_owner         UUID,
    delivery_owner          UUID,
    region                  VARCHAR(16),
    business_group          VARCHAR(64),
    lob                     VARCHAR(16),
    platform                VARCHAR(20),
    capability              VARCHAR(20),
    git_repo                VARCHAR(1024),
    api_tags                VARCHAR(1024),          -- single word separated with comma.
    api_status              VARCHAR(32) NOT NULL,
    aggregate_version       BIGINT DEFAULT 1 NOT NULL,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE api_t ADD CONSTRAINT api_pk PRIMARY KEY (host_id, api_id);



CREATE TABLE api_version_t (
    host_id                 UUID NOT NULL,
    api_version_id          UUID NOT NULL,
    api_id                  VARCHAR(16) NOT NULL,
    api_version             VARCHAR(16) NOT NULL,
    api_type                VARCHAR(7) NOT NULL,    -- openapi, graphql, hybrid
    service_id              VARCHAR(512) NOT NULL,  -- several api version can have one service_id
    api_version_desc        VARCHAR(1024),
    spec_link               VARCHAR(1024),
    spec                    TEXT,
    aggregate_version       BIGINT DEFAULT 1 NOT NULL,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, api_version_id),
    FOREIGN KEY(host_id, api_id) REFERENCES api_t(host_id, api_id) ON DELETE CASCADE
);


ALTER TABLE api_version_t ADD CONSTRAINT api_version_uk UNIQUE(host_id, api_id, api_version);

CREATE TABLE api_endpoint_t (
    host_id              UUID NOT NULL,
    endpoint_id          UUID NOT NULL,
    api_version_id       UUID NOT NULL,
    endpoint             VARCHAR(1024) NOT NULL,  -- endpoint path@method
    http_method          VARCHAR(10),
    endpoint_path        VARCHAR(1024),
    endpoint_name        VARCHAR(128) NOT NULL,
    endpoint_desc        VARCHAR(1024),
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, endpoint_id),
    FOREIGN KEY(host_id, api_version_id) REFERENCES api_version_t(host_id, api_version_id) ON DELETE CASCADE
);

ALTER TABLE api_endpoint_t
    ADD CHECK ( http_method IN ( 'delete', 'get', 'patch', 'post', 'put' ) );


CREATE TABLE api_endpoint_scope_t (
    host_id                 UUID NOT NULL,
    endpoint_id             UUID NOT NULL,
    scope                   VARCHAR(128) NOT NULL,
    scope_desc              VARCHAR(1024),
    aggregate_version       BIGINT DEFAULT 1 NOT NULL,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE api_endpoint_scope_t ADD CONSTRAINT api_endpoint_scope_pk PRIMARY KEY (host_id, endpoint_id, scope );

-- The calling relationship between app and api with scope.
CREATE TABLE app_api_t (
    host_id                 UUID NOT NULL,
    app_id                  VARCHAR(512) NOT NULL,
    endpoint_id             UUID NOT NULL,        
    scope                   VARCHAR(128) NOT NULL,
    aggregate_version       BIGINT DEFAULT 1 NOT NULL,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, app_id, endpoint_id, scope),
    FOREIGN KEY(host_id, endpoint_id, scope) REFERENCES api_endpoint_scope_t(host_id, endpoint_id, scope) ON DELETE CASCADE
);


CREATE TABLE app_t (
    host_id                 UUID NOT NULL,
    app_id                  VARCHAR(512) NOT NULL,
    app_name                VARCHAR(128) NOT NULL,
    app_desc                VARCHAR(2048),
    is_kafka_app            BOOLEAN DEFAULT false,
    operation_owner         UUID,
    delivery_owner          UUID,
    aggregate_version       BIGINT DEFAULT 1 NOT NULL,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE app_t ADD CONSTRAINT app_pk PRIMARY KEY ( host_id, app_id);




CREATE TABLE chain_handler_t (
    chain_id          UUID NOT NULL,
    configuration_id  UUID NOT NULL,
    sequence_id       INTEGER NOT NULL,
    aggregate_version BIGINT DEFAULT 1 NOT NULL,
    update_user       VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts         TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE chain_handler_t ADD CONSTRAINT chain_handler_pk PRIMARY KEY ( chain_id,
                                                                          configuration_id );



-- each config file will have an entry in this table including the deployment files.
CREATE TABLE config_t (
    config_id                 UUID NOT NULL,
    config_name               VARCHAR(128) NOT NULL,
    config_phase              CHAR(1) NOT NULL DEFAULT 'R', -- D deployment R runtime
    config_type               VARCHAR(32) DEFAULT 'Handler',
    light4j_version           VARCHAR(12), -- initial population has no version. Each new config file introduced willl have a version
    class_path                VARCHAR(1024),
    config_desc               VARCHAR(4096),
    aggregate_version         BIGINT DEFAULT 1 NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE config_t
    ADD CHECK ( config_type IN ( 'Handler', 'Module', 'Template') );

ALTER TABLE config_t
    ADD CHECK ( config_phase IN ( 'G', 'D', 'R') ); -- G generator, D deployment, R runtime

ALTER TABLE config_t ADD CONSTRAINT config_pk PRIMARY KEY ( config_id );

ALTER TABLE config_t ADD CONSTRAINT config_uk UNIQUE (config_name);



-- each config file will have a config_id reference and this table contains all the properties including default. 
CREATE TABLE config_property_t (
    config_id                 UUID NOT NULL,
    property_id               UUID NOT NULL,
    property_name             VARCHAR(64) NOT NULL,
    property_type             VARCHAR(32) DEFAULT 'Config' NOT NULL,
    light4j_version           VARCHAR(12), -- only newly introduced property has a version.
    display_order             INTEGER,
    required                  BOOLEAN DEFAULT false NOT NULL,
    property_desc             VARCHAR(4096),
    property_value            TEXT,
    value_type                VARCHAR(32),
    resource_type             VARCHAR(30) DEFAULT 'none',
    aggregate_version         BIGINT DEFAULT 1 NOT NULL,
    update_user               VARCHAR(255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL, 
    PRIMARY KEY(property_id)
);

ALTER TABLE config_property_t
    ADD CHECK ( property_type IN ( 'Cert', 'Config', 'File') );


COMMENT ON COLUMN config_property_t.property_value IS
    'Property Default Value';

COMMENT ON COLUMN config_property_t.value_type IS
    'One of string, boolean, integer, float, map, list';

COMMENT ON COLUMN config_property_t.resource_type IS
  'One of none, api, app, app_api, api|app_api, app|app_api, all';

ALTER TABLE config_property_t ADD CONSTRAINT config_property_uk UNIQUE ( config_id, property_name );


CREATE TABLE environment_property_t (
    host_id            UUID NOT NULL,
    environment        VARCHAR(16) NOT NULL,
    property_id        UUID NOT NULL,
    property_value     TEXT,
    aggregate_version  BIGINT DEFAULT 1 NOT NULL,
    update_user        VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, environment, property_id),
    FOREIGN KEY(property_id) REFERENCES config_property_t(property_id) ON DELETE CASCADE
);


-- for each platform like jenkins, ansible etc. 
CREATE TABLE platform_t (
    host_id                     UUID NOT NULL,
    platform_id                 UUID NOT NULL,
    platform_name               VARCHAR(126) NOT NULL,
    platform_version            VARCHAR(8) NOT NULL,
    client_type                 VARCHAR(10)NOT NULL,
    client_url                  VARCHAR(255) NOT NULL,
    credentials                 VARCHAR(255) NOT NULL,
    proxy_url                   VARCHAR(255),
    proxy_port                  INTEGER,
    handler_class               VARCHAR(1024) NOT NULL, -- The handler class in light-portal to interact with the platform. 
    console_url                 VARCHAR(255), -- the url pattern that we can access the console logs. 
    environment                 VARCHAR(16),
    zone                        VARCHAR(16),
    region                      VARCHAR(16),
    lob                         VARCHAR(16),
    aggregate_version           BIGINT DEFAULT 1 NOT NULL,
    update_user                 VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, platform_id)
);

--  each platform will have multiple pipelines. 
CREATE TABLE pipeline_t (
    host_id                     UUID NOT NULL,
    pipeline_id                 UUID NOT NULL,
    platform_id                 UUID NOT NULL,
    pipeline_version            VARCHAR(16) NOT NULL,     -- if there is no version, it doesn't make sense we have current flag.
    pipeline_name               VARCHAR(1024) NOT NULL,   -- name of the pipeline that will be displayed in dropdown.
    current                     BOOLEAN DEFAULT false,    -- The current pipeline for the platform_id if it is true.
    endpoint                    VARCHAR(1024) NOT NULL,
    version_status              VARCHAR(16) NOT NULL,     -- from ref table pipeline_version_status. Supported, Outdated, Deprecated, Removed
    system_env                  VARCHAR(16) NOT NULL,     -- a pipeline must be 
    runtime_env                 VARCHAR(16),
    request_schema              TEXT NOT NULL,
    response_schema             TEXT NOT NULL,
    aggregate_version           BIGINT DEFAULT 1 NOT NULL,
    update_user                 VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, pipeline_id),
    FOREIGN KEY(host_id, platform_id) REFERENCES platform_t(host_id, platform_id) ON DELETE CASCADE
);


CREATE TABLE instance_t (
    host_id              UUID NOT NULL,
    instance_id          UUID NOT NULL,
    instance_name        VARCHAR(126) NOT NULL,
    product_version_id   UUID NOT NULL,
    service_id           VARCHAR(512) NOT NULL, -- for a standalone product, use service_id for query.
    current              BOOLEAN DEFAULT false, -- for this service_id, the current product version
    readonly             BOOLEAN DEFAULT false, -- lock the instance level configuration customization. 
    environment          VARCHAR(16),
    service_desc         VARCHAR(4096),         -- service description and it should be the same for all instances
    instance_desc        VARCHAR(1024),         -- instance description and it is related to the specific prod version
    zone                 VARCHAR(16),
    region               VARCHAR(16),
    lob                  VARCHAR(16), 
    resource_name        VARCHAR(126),          -- identify the resource, host, or namespace.
    business_name        VARCHAR(126),
    env_tag              VARCHAR(16),           -- envirnment tag along with service_id for service lookup and configuration.
    topic_classification VARCHAR(126),          -- for kafka sidecar only.
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_id)
);


COMMENT ON COLUMN instance_t.service_id IS
' Naming Convention: (delimit with dash, use lower case)
  <product>-<region/country>-[lob]-<app/domain>-<resource/host>-<zone>
    - Light Gateway: lg-ca-eadp-sag1-aiz
    - Light Balancer: lb-ca-gb-sv0a0332-corp
    - Light Proxy Client: lpc-ca-gb-sv0a0332leg1-corp
    - Light Proxy Server: lps-ph-sv0a0123-aiz
    - Light Proxy Sidecar: lp-ca-gb-claims-payments-corp
    - Light Proxy Lambda: lpl-ca-xp-client-corp
    - Kafka Sidecar: ks-ca-grs-member-corp
';


ALTER TABLE instance_t
    ADD CONSTRAINT instance_uk UNIQUE (host_id, service_id, env_tag, product_version_id);


-- one to many from the instance_t table.
CREATE TABLE deployment_instance_t (
    host_id                UUID NOT NULL,
    instance_id            UUID NOT NULL,
    deployment_instance_id UUID NOT NULL,         -- UUID as part of the PK
    service_id             VARCHAR(512) NOT NULL, -- A unique engish identifier
    ip_address             VARCHAR(30),           -- for VM deployment only, both v4 or v6
    port_number            INT,                   -- port number to match the runtime instance along with ip address and service_id(logical instance)
    system_env             VARCHAR(16) NOT NULL,  -- choose from product_version_environment_t table as dropdown.
    runtime_env            VARCHAR(16) NOT NULL,  -- which jdk, sytem etc.
    pipeline_id            UUID NOT NULL,         -- picked up pipeline for the deployment
    deploy_status          VARCHAR(32) DEFAULT 'NotDeployed' NOT NULL,  -- NotDeployed, Deploying, Deployed, DeployFailed, UnDeployed, UnDeployFailed
    aggregate_version      BIGINT DEFAULT 1 NOT NULL,
    update_user            VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, deployment_instance_id),
    FOREIGN KEY(host_id, instance_id) REFERENCES instance_t(host_id, instance_id) ON DELETE CASCADE
);

-- customized config at the deployment instance level. Usually, it is the hostname.
CREATE TABLE deployment_instance_property_t (
    host_id                 UUID NOT NULL,
    deployment_instance_id  UUID NOT NULL,
    property_id             UUID NOT NULL,
    property_value          TEXT,
    aggregate_version       BIGINT DEFAULT 1 NOT NULL,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, deployment_instance_id, property_id),
    FOREIGN KEY(host_id, deployment_instance_id) REFERENCES deployment_instance_t(host_id, deployment_instance_id) ON DELETE CASCADE,
    FOREIGN KEY(property_id) REFERENCES config_property_t(property_id) ON DELETE CASCADE
);


-- one gateway instance can have multiple APIs managed by it. 
CREATE TABLE instance_api_t (
    host_id              UUID NOT NULL,
    instance_api_id      UUID NOT NULL,
    instance_id          UUID NOT NULL,
    api_version_id       UUID NOT NULL,
    active               BOOLEAN DEFAULT true,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_api_id),
    FOREIGN KEY(host_id, instance_id) REFERENCES instance_t(host_id, instance_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, api_version_id) REFERENCES api_version_t(host_id, api_version_id) ON DELETE CASCADE
);

ALTER TABLE instance_api_t ADD CONSTRAINT instance_api_uk UNIQUE (host_id, instance_id, api_version_id);


-- customized config property for the instance api.
CREATE TABLE instance_api_property_t (
    host_id              UUID NOT NULL,
    instance_api_id      UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_api_id, property_id),
    FOREIGN KEY(host_id, instance_api_id) REFERENCES instance_api_t(host_id, instance_api_id) ON DELETE CASCADE,
    FOREIGN KEY(property_id) REFERENCES config_property_t(property_id) ON DELETE CASCADE
);

-- path prefix definition for the instance api.
CREATE TABLE instance_api_path_prefix_t (
    host_id              UUID NOT NULL,
    instance_api_id      UUID NOT NULL,
    path_prefix          VARCHAR(1024) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_api_id, path_prefix),
    FOREIGN KEY(host_id, instance_api_id) REFERENCES instance_api_t(host_id, instance_api_id) ON DELETE CASCADE
);

-- one gateway instance may have many applications connecting to it to consume APIs.
CREATE TABLE instance_app_t (
    host_id              UUID NOT NULL,
    instance_app_id      UUID NOT NULL,
    instance_id          UUID NOT NULL,
    app_id               VARCHAR(512) NOT NULL,
    app_version          VARCHAR(16) NOT NULL,
    active               BOOLEAN DEFAULT true,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_app_id),
    FOREIGN KEY(host_id, instance_id) REFERENCES instance_t(host_id, instance_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, app_id) REFERENCES app_t(host_id, app_id) ON DELETE CASCADE
);

ALTER TABLE instance_app_t ADD CONSTRAINT instance_app_uk UNIQUE (host_id, instance_id, app_id, app_version);



CREATE TABLE instance_app_property_t (
    host_id              UUID NOT NULL,
    instance_app_id      UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_app_id, property_id),
    FOREIGN KEY(host_id, instance_app_id) REFERENCES instance_app_t(host_id, instance_app_id) ON DELETE CASCADE,
    FOREIGN KEY(property_id) REFERENCES config_property_t(property_id) ON DELETE CASCADE
);

-- add instance api and app association relation
CREATE TABLE instance_app_api_t (
    host_id              UUID NOT NULL,
    instance_app_id      UUID NOT NULL,
    instance_api_id      UUID NOT NULL,
    active               BOOLEAN DEFAULT true,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_app_id, instance_api_id),
    FOREIGN KEY(host_id, instance_app_id) REFERENCES instance_app_t(host_id, instance_app_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, instance_api_id) REFERENCES instance_api_t(host_id, instance_api_id) ON DELETE CASCADE
);

ALTER TABLE instance_app_api_t ADD CONSTRAINT instance_app_api_uk UNIQUE ( instance_app_id, instance_api_id );

CREATE TABLE instance_app_api_property_t (
    host_id              UUID NOT NULL,
    instance_app_id      UUID NOT NULL,
    instance_api_id      UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_app_id, instance_api_id, property_id)
);

ALTER TABLE instance_app_api_property_t 
    ADD CONSTRAINT instance_app_api_property_uk 
        UNIQUE ( instance_app_id, instance_api_id, property_id );

ALTER TABLE instance_app_api_property_t
    ADD CONSTRAINT instance_app_api_property_fk FOREIGN KEY (host_id, instance_app_id, instance_api_id)
        REFERENCES instance_app_api_t (host_id, instance_app_id, instance_api_id)
            ON DELETE CASCADE;

ALTER TABLE instance_app_api_property_t
    ADD CONSTRAINT config_property_fk1 FOREIGN KEY (property_id)
        REFERENCES config_property_t( property_id)
            ON DELETE CASCADE;


CREATE TABLE instance_property_t (
    host_id              UUID NOT NULL,
    instance_id          UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_property_t ADD CONSTRAINT instance_property_pk PRIMARY KEY ( host_id, instance_id,
                                                                                  property_id);

-- Stores additional config files specific for the instance.
CREATE TABLE instance_file_t (
    host_id              UUID NOT NULL,
    instance_file_id     UUID NOT NULL,
    instance_id          UUID NOT NULL,
    file_type            VARCHAR(32) DEFAULT 'File',
    file_name            VARCHAR (126) NOT NULL,
    file_value           TEXT NOT NULL,
    file_desc            VARCHAR(1024) NOT NULL,
    expiration_ts        TIMESTAMP WITH TIME ZONE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_file_id)
);

COMMENT ON COLUMN instance_file_t.expiration_ts IS
  'An expiration timestamp is optional, but mostly should be used for Certificates that are bound to expire some day.';

ALTER TABLE instance_file_t ADD v_file_name VARCHAR(126) GENERATED ALWAYS AS ( LOWER(file_name) ) STORED;

ALTER TABLE instance_file_t
    ADD CHECK ( file_type IN ( 'Cert', 'File' ) );

ALTER TABLE instance_file_t 
    ADD CONSTRAINT instance_file_uk 
        UNIQUE (instance_id, v_file_name);

ALTER TABLE instance_file_t
  ADD CONSTRAINT instance_file_fk FOREIGN KEY (host_id, instance_id)
    REFERENCES instance_t (host_id, instance_id)
      ON DELETE CASCADE;


-- product level customized properties which is generic or common for the product. 
CREATE TABLE product_property_t (
    product_id           VARCHAR(8) NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE product_property_t ADD CONSTRAINT product_property_pk PRIMARY KEY ( product_id,
                                                                                property_id);

CREATE TABLE product_version_t (
    host_id              UUID NOT NULL,
    product_version_id   UUID NOT NULL,
    product_id           VARCHAR(8) NOT NULL,
    product_version      VARCHAR(12) NOT NULL, -- internal product version 
    light4j_version      VARCHAR(12) NOT NULL, -- open source release version
    break_code           BOOLEAN DEFAULT false, -- breaking code change to upgrade to this version.
    break_config         BOOLEAN DEFAULT false, -- config server need this to decide if clone is allowed for this version. 
    release_note         TEXT,
    version_desc         VARCHAR(1024),
    release_type         VARCHAR(24) NOT NULL, -- Alpha Version, Beta Version, Release Candidate, General Availability, Production Release
    current              BOOLEAN DEFAULT false,
    version_status       VARCHAR(16) NOT NULL, -- Supported, Deprecated, NotSupported
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, product_version_id)
);

ALTER TABLE product_version_t ADD CONSTRAINT product_version_uk UNIQUE (host_id, product_id, product_version);

-- mapping of product version to systme environment
CREATE TABLE product_version_environment_t (
    host_id              UUID NOT NULL,
    product_version_id   UUID NOT NULL,
    system_env           VARCHAR(16) NOT NULL,
    runtime_env          VARCHAR(16) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, product_version_id, system_env, runtime_env),
    FOREIGN KEY(host_id, product_version_id) 
        REFERENCES product_version_t(host_id, product_version_id) ON DELETE CASCADE
);


-- config file and product version mapping (applicable config for pv)
CREATE TABLE product_version_config_t (
    host_id              UUID NOT NULL,
    product_version_id   UUID NOT NULL,
    config_id            UUID NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, product_version_id, config_id),
    FOREIGN KEY(host_id, product_version_id) 
        REFERENCES product_version_t(host_id, product_version_id) ON DELETE CASCADE,
    FOREIGN KEY(config_id) 
        REFERENCES config_t(config_id) ON DELETE CASCADE
);

-- config property and product version mapping (applicable config properties for pv)
CREATE TABLE product_version_config_property_t (
    host_id              UUID NOT NULL,
    product_version_id   UUID NOT NULL,
    property_id          UUID NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, product_version_id, property_id),
    FOREIGN KEY(host_id, product_version_id) 
        REFERENCES product_version_t(host_id, product_version_id) ON DELETE CASCADE,
    FOREIGN KEY(property_id) 
        REFERENCES config_property_t(property_id) ON DELETE CASCADE
);

-- customized property for product version within the host.
CREATE TABLE product_version_property_t (
    host_id              UUID NOT NULL,
    product_version_id   UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (126) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, product_version_id, property_id),
    FOREIGN KEY(host_id, product_version_id)
        REFERENCES product_version_t(host_id, product_version_id) ON DELETE CASCADE,
    FOREIGN KEY(property_id) REFERENCES config_property_t(property_id) ON DELETE CASCADE
);

-- each product version will have several pipelines
CREATE TABLE product_version_pipeline_t (
    host_id              UUID NOT NULL,
    product_version_id   UUID NOT NULL,
    pipeline_id          UUID NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (126) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, product_version_id, pipeline_id),
    FOREIGN KEY(host_id, product_version_id)
        REFERENCES product_version_t(host_id, product_version_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, pipeline_id) REFERENCES pipeline_t (host_id, pipeline_id) ON DELETE CASCADE
);

-- 
CREATE TABLE deployment_t (
    host_id                  UUID NOT NULL,
    deployment_id            UUID NOT NULL,
    deployment_instance_id   UUID NOT NULL,   -- since deployment is per leg, we need to link to deployment instance.
    deployment_status        VARCHAR(16) NOT NULL, -- 
    deployment_type          VARCHAR(16) NOT NULL,
    schedule_ts              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    platform_job_id          VARCHAR(126),           -- update by the executor once it is started
    aggregate_version        BIGINT DEFAULT 1 NOT NULL,
    update_user              VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, deployment_id),
    FOREIGN KEY(host_id, deployment_instance_id) REFERENCES deployment_instance_t(host_id, deployment_instance_id) ON DELETE CASCADE
);



-- runtime instance created by the control pane. 
CREATE TABLE runtime_instance_t (
    host_id                  UUID NOT NULL,
    runtime_instance_id      UUID NOT NULL,  -- auto generated uuid as part of pk
    deployment_instance_id   UUID NOT NULL,  -- which logical instance in instance_t
    service_id               VARCHAR(512) NOT NULL, -- serviceId from the server.yml
    env_tag                  VARCHAR(16),           -- optional environment from server.yml
    ip_address               VARCHAR(30) NOT NULL,  -- detected from the server instance and registered on the control pane.
    port_number              INT NOT NULL,          -- registered on control pane.         
    instance_status          VARCHAR(16) NOT NULL,  -- Deployed, Running, Shutdown, Starting 
    aggregate_version        BIGINT DEFAULT 1 NOT NULL,
    update_user              VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, runtime_instance_id),
    FOREIGN KEY(host_id, deployment_instance_id) REFERENCES deployment_instance_t(host_id, deployment_instance_id) ON DELETE CASCADE
);


CREATE TABLE org_t (
    domain               VARCHAR(64) NOT NULL,  -- networknt.com lightapi.net
    org_name             VARCHAR(128) NOT NULL,
    org_desc             VARCHAR(4096) NOT NULL,
    org_owner            UUID NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(domain)
);


CREATE TABLE host_t (
    host_id              UUID NOT NULL, -- a generated unique identifier.
    domain               VARCHAR(64) NOT NULL,
    sub_domain           VARCHAR(64) NOT NULL, -- dev, sit, stg, prd, pre-sit, sit-green, sit-ca, sit-us etc.
    host_desc            VARCHAR(4096),
    host_owner           UUID NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id),
    FOREIGN KEY(domain) REFERENCES org_t(domain) ON DELETE CASCADE
);


ALTER TABLE host_t ADD CONSTRAINT domain_uk UNIQUE ( domain, sub_domain );


-- Table for defining reference types (e.g., 'Countries', 'OrderStatus')
CREATE TABLE ref_table_t (
    table_id             UUID NOT NULL, -- UUID genereated by Util
    host_id              UUID,          -- NULL for global/shared tables
    table_name           VARCHAR(80) NOT NULL, -- Name of the ref table for lookup.
    table_desc           TEXT NULL,
    active               BOOLEAN NOT NULL DEFAULT TRUE, -- Only active table returns values
    editable             BOOLEAN NOT NULL DEFAULT TRUE, -- Table value and locale can be updated via ref admin
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,  
    PRIMARY KEY(table_id)
);

-- Partial unique indexes for table_name scope
CREATE UNIQUE INDEX idx_ref_table_unique_global ON ref_table_t (table_name) WHERE host_id IS NULL;
CREATE UNIQUE INDEX idx_ref_table_unique_tenant ON ref_table_t (host_id, table_name) WHERE host_id IS NOT NULL;
CREATE INDEX idx_ref_table_host_id ON ref_table_t(host_id); -- Index for host lookup

-- Table for individual values within a reference table
CREATE TABLE ref_value_t (
    value_id             UUID NOT NULL,
    table_id             UUID NOT NULL,
    value_code           VARCHAR(80) NOT NULL, -- The dropdown value
    value_desc           TEXT NULL,            -- Optional detailed description  
    start_ts             TIMESTAMP WITH TIME ZONE NULL,
    end_ts               TIMESTAMP WITH TIME ZONE NULL,
    display_order        INT DEFAULT 0,        -- for editor and dropdown list.
    active               BOOLEAN NOT NULL DEFAULT TRUE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(value_id),
    FOREIGN KEY (table_id) REFERENCES ref_table_t (table_id) ON DELETE CASCADE,
    CONSTRAINT unique_ref_value_code_in_table UNIQUE (table_id, value_code) -- Enforce unique codes within a table
);

CREATE INDEX idx_ref_value_table_id ON ref_value_t(table_id); -- Index for finding values by table


CREATE TABLE value_locale_t (
    value_id             UUID NOT NULL,
    language             VARCHAR(2) NOT NULL,
    value_label          VARCHAR(255) NOT NULL, -- The drop label in language.
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(value_id,language),
    FOREIGN KEY (value_id) REFERENCES ref_value_t (value_id) ON DELETE CASCADE
);

CREATE INDEX idx_value_locale_lang ON value_locale_t(language);


CREATE TABLE relation_type_t (
    relation_id          UUID NOT NULL,
    relation_name        VARCHAR(32) NOT NULL, -- The lookup keyword for the relation.
    relation_desc        TEXT NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(relation_id)
);



CREATE TABLE relation_t (
    relation_id          UUID NOT NULL,
    value_id_from        UUID NOT NULL,
    value_id_to          UUID NOT NULL,
    active               BOOLEAN NOT NULL DEFAULT TRUE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,  
    PRIMARY KEY (relation_id, value_id_from, value_id_to),
    FOREIGN KEY (relation_id) REFERENCES relation_type_t (relation_id) ON DELETE CASCADE,
    FOREIGN KEY (value_id_from) REFERENCES ref_value_t (value_id) ON DELETE CASCADE,
    FOREIGN KEY (value_id_to) REFERENCES ref_value_t (value_id) ON DELETE CASCADE
);

CREATE INDEX idx_relation_from ON relation_t(value_id_from);
CREATE INDEX idx_relation_to ON relation_t(value_id_to);


CREATE TABLE user_t (
    user_id              UUID NOT NULL,
    email                VARCHAR(255) NOT NULL,
    password             VARCHAR(1024) NULL,
    language             CHAR(2) NOT NULL,
    first_name           VARCHAR(32) NULL,
    last_name            VARCHAR(32) NULL,
    user_type            CHAR(1) NULL, -- E employee C customer or E employee P personal B business
    phone_number         VARCHAR(20) NULL,
    gender               CHAR(1) NULL,
    birthday             DATE NULL,
    country              VARCHAR(3) NULL,
    province             VARCHAR(32) NULL,
    city                 VARCHAR(32) NULL,
    address              VARCHAR(128) NULL,
    post_code            VARCHAR(16) NULL,
    verified             BOOLEAN NOT NULL DEFAULT false,
    token                VARCHAR(64) NULL,
    locked               BOOLEAN NOT NULL DEFAULT false,
    nonce                BIGINT NOT NULL DEFAULT 0,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE user_t ADD CONSTRAINT user_pk PRIMARY KEY ( user_id );

ALTER TABLE user_t ADD CONSTRAINT user_email_uk UNIQUE ( email );

CREATE TABLE user_host_t (
    host_id              UUID NOT NULL,
    user_id              UUID NOT NULL,
    -- other relationship-specific attributes (e.g., roles within the host)
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, user_id),
    FOREIGN KEY (user_id) REFERENCES user_t (user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id) REFERENCES host_t (host_id) ON DELETE CASCADE
);

CREATE TABLE user_crypto_wallet_t (
    user_id              UUID NOT NULL,
    crypto_type          VARCHAR(32) NOT NULL,
    crypto_address       VARCHAR(128) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, crypto_type, crypto_address),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE
);

CREATE TABLE customer_t (
    host_id              UUID NOT NULL,
    customer_id          VARCHAR(50) NOT NULL,
    user_id              UUID NOT NULL,
    -- Other customer-specific attributes
    referral_id          VARCHAR(50), -- the customer_id who refers this customer.
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, customer_id),
    -- make sure that the user_host_t host_id update is cascaded
    FOREIGN KEY (host_id, user_id) REFERENCES user_host_t(host_id, user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (host_id, referral_id) REFERENCES customer_t(host_id, customer_id) ON DELETE CASCADE
);

CREATE TABLE employee_t (
    host_id              UUID NOT NULL,
    employee_id          VARCHAR(50) NOT NULL,  -- Employee ID or number or ACF2 ID. Unique within the host.
    user_id              UUID NOT NULL,
    title                VARCHAR(126),
    manager_id           VARCHAR(50), -- manager's employee_id if there is one.
    hire_date            DATE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, employee_id),
    -- make sure that the user_host_t host_id update is cascaded
    FOREIGN KEY (host_id, user_id) REFERENCES user_host_t(host_id, user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (host_id, manager_id) REFERENCES employee_t(host_id, employee_id) ON DELETE CASCADE
);

CREATE TABLE position_t (
    host_id              UUID NOT NULL,
    position_id          VARCHAR(128) NOT NULL,
    position_desc        VARCHAR(2048),
    inherit_to_ancestor  CHAR(1) DEFAULT 'N',
    inherit_to_sibling   CHAR(1) DEFAULT 'N',
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, position_id)
);

CREATE TABLE employee_position_t (
    host_id              UUID NOT NULL,
    employee_id          VARCHAR(50) NOT NULL,
    position_id          VARCHAR(128) NOT NULL,
    position_type        CHAR(1) NOT NULL, -- P position of own, D inherited from a decendant, S inherited from a sibling.
    start_ts             TIMESTAMP WITH TIME ZONE,
    end_ts               TIMESTAMP WITH TIME ZONE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, employee_id, position_id),
    FOREIGN KEY (host_id, position_id) REFERENCES position_t(host_id, position_id) ON DELETE CASCADE
);

CREATE TABLE position_permission_t (
    host_id              UUID NOT NULL,
    position_id          VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, position_id, endpoint_id),
    FOREIGN KEY (host_id, position_id) REFERENCES position_t(host_id, position_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);

CREATE TABLE position_row_filter_t (
    host_id                  UUID NOT NULL,
    position_id              VARCHAR(128) NOT NULL,
    endpoint_id              UUID NOT NULL,
    col_name                 VARCHAR(128) NOT NULL,
    operator                 VARCHAR(32) NOT NULL,
    col_value                VARCHAR(1024) NOT NULL,
    aggregate_version        BIGINT DEFAULT 1 NOT NULL,
    update_user              VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, position_id, endpoint_id, col_name),
    FOREIGN KEY (host_id, position_id) REFERENCES position_t(host_id, position_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);

CREATE TABLE position_col_filter_t (
    host_id              UUID NOT NULL,
    position_id          VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    columns              VARCHAR(1024) NOT NULL, -- list of columns to keep for the position in json string array format.
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, position_id, endpoint_id),
    FOREIGN KEY (host_id, position_id) REFERENCES position_t(host_id, position_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);

CREATE TABLE role_t (
    host_id              UUID NOT NULL,
    role_id              VARCHAR(128) NOT NULL,
    role_desc            VARCHAR(1024),
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id),
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);

CREATE TABLE role_permission_t (
    host_id              UUID NOT NULL,
    role_id              VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id, endpoint_id),
    FOREIGN KEY (host_id, role_id) REFERENCES role_t(host_id, role_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);

CREATE TABLE role_row_filter_t (
    host_id              UUID NOT NULL,
    role_id              VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    col_name             VARCHAR(128) NOT NULL,
    operator             VARCHAR(32) NOT NULL,
    col_value            VARCHAR(1024) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id, endpoint_id, col_name),
    FOREIGN KEY (host_id, role_id) REFERENCES role_t(host_id, role_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);

CREATE TABLE role_col_filter_t (
    host_id              UUID NOT NULL,
    role_id              VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    columns              VARCHAR(1024) NOT NULL, -- list of columns to keep for the role in json string array format.
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id, endpoint_id),
    FOREIGN KEY (host_id, role_id) REFERENCES role_t(host_id, role_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);


CREATE TABLE role_user_t (
    host_id              UUID NOT NULL,
    role_id              VARCHAR(128) NOT NULL,
    user_id              UUID NOT NULL,
    start_ts             TIMESTAMP WITH TIME ZONE,
    end_ts               TIMESTAMP WITH TIME ZONE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id, user_id),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, role_id) REFERENCES role_t(host_id, role_id) ON DELETE CASCADE
);

CREATE TABLE user_permission_t (
    host_id              UUID NOT NULL,
    user_id              UUID NOT NULL,
    endpoint_id          UUID NOT NULL,
    start_ts             TIMESTAMP WITH TIME ZONE,
    end_ts               TIMESTAMP WITH TIME ZONE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, host_id, endpoint_id),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);


CREATE TABLE user_row_filter_t (
    host_id              UUID NOT NULL,
    user_id              UUID NOT NULL,
    endpoint_id          UUID NOT NULL,
    col_name             VARCHAR(128) NOT NULL,
    operator             VARCHAR(32) NOT NULL,
    col_value            VARCHAR(1024) NOT NULL,
    start_ts             TIMESTAMP WITH TIME ZONE,
    end_ts               TIMESTAMP WITH TIME ZONE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, host_id, endpoint_id, col_name),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);

CREATE TABLE user_col_filter_t (
    host_id              UUID NOT NULL,
    user_id              UUID NOT NULL,
    endpoint_id          UUID NOT NULL,
    columns              VARCHAR(1024) NOT NULL, -- list of columns to keep for the user in json string array format.
    start_ts             TIMESTAMP WITH TIME ZONE,
    end_ts               TIMESTAMP WITH TIME ZONE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, host_id, endpoint_id),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);


CREATE TABLE group_t (
    host_id              UUID NOT NULL,
    group_id             VARCHAR(128) NOT NULL,
    group_desc           VARCHAR(2048),
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id)
);

CREATE TABLE group_permission_t (
    host_id              UUID NOT NULL,
    group_id             VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id, endpoint_id),
    FOREIGN KEY (host_id, group_id) REFERENCES group_t(host_id, group_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);

CREATE TABLE group_row_filter_t (
    host_id              UUID NOT NULL,
    group_id             VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    col_name             VARCHAR(128) NOT NULL,
    operator             VARCHAR(32) NOT NULL,
    col_value            VARCHAR(1024) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id, endpoint_id, col_name),
    FOREIGN KEY (host_id, group_id) REFERENCES group_t(host_id, group_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);

CREATE TABLE group_col_filter_t (
    host_id              UUID NOT NULL,
    group_id             VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    columns              VARCHAR(1024) NOT NULL, -- list of columns to keep for the group in json string array format.
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id, endpoint_id),
    FOREIGN KEY (host_id, group_id) REFERENCES group_t(host_id, group_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE
);


CREATE TABLE group_user_t (
    host_id              UUID NOT NULL,
    group_id             VARCHAR(128) NOT NULL,
    user_id              UUID NOT NULL,
    start_ts             TIMESTAMP WITH TIME ZONE,
    end_ts               TIMESTAMP WITH TIME ZONE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id, user_id),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, group_id) REFERENCES group_t(host_id, group_id) ON DELETE CASCADE
);

-- attribute
CREATE TABLE attribute_t (
    host_id              UUID NOT NULL,
    attribute_id         VARCHAR(128) NOT NULL,
    attribute_type       VARCHAR(50) CHECK (attribute_type IN ('string', 'integer', 'boolean', 'date', 'float', 'list')), -- Define allowed data types
    attribute_desc       VARCHAR(2048),
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id)
);

CREATE TABLE attribute_user_t (
    host_id              UUID NOT NULL,
    attribute_id         VARCHAR(128) NOT NULL,
    user_id              UUID NOT NULL, -- References users_t
    attribute_value      VARCHAR(1024) NOT NULL, -- Store values as strings; you can cast later
    start_ts             TIMESTAMP WITH TIME ZONE,
    end_ts               TIMESTAMP WITH TIME ZONE,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id, user_id),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, attribute_id) REFERENCES attribute_t(host_id, attribute_id) ON DELETE CASCADE
);


CREATE TABLE attribute_permission_t (
    host_id              UUID NOT NULL,
    attribute_id         VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,    
    attribute_value      VARCHAR(1024) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id, endpoint_id),
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, attribute_id) REFERENCES attribute_t(host_id, attribute_id) ON DELETE CASCADE
);

CREATE TABLE attribute_row_filter_t (
    host_id              UUID NOT NULL,
    attribute_id         VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    attribute_value      VARCHAR(1024) NOT NULL,
    col_name             VARCHAR(128) NOT NULL,
    operator             VARCHAR(32) NOT NULL,
    col_value            VARCHAR(1024) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id, endpoint_id, col_name),
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, attribute_id) REFERENCES attribute_t(host_id, attribute_id) ON DELETE CASCADE
);

CREATE TABLE attribute_col_filter_t (
    host_id              UUID NOT NULL,
    attribute_id         VARCHAR(128) NOT NULL,
    endpoint_id          UUID NOT NULL,
    attribute_value      VARCHAR(1024) NOT NULL,
    columns              VARCHAR(1024) NOT NULL, -- list of columns to keep for the attribute in json string array format.
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id, endpoint_id),
    FOREIGN KEY (host_id, endpoint_id) REFERENCES api_endpoint_t(host_id, endpoint_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, attribute_id) REFERENCES attribute_t(host_id, attribute_id) ON DELETE CASCADE
);


CREATE TABLE auth_provider_t (
    provider_id          VARCHAR(22) NOT NULL,
    host_id              UUID NOT NULL,  -- host that the provider belong to.
    provider_name        VARCHAR(126) NOT NULL,
    provider_desc        VARCHAR(4096),
    operation_owner      UUID,
    delivery_owner       UUID,
    jwk                  VARCHAR(65535) NOT NULL, -- json web key that contains current and previous public keys
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (provider_id),
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);


CREATE TABLE auth_provider_key_t (
    provider_id          VARCHAR(22) NOT NULL,
    kid                  VARCHAR(22) NOT NULL,
    public_key           VARCHAR(65535) NOT NULL,
    private_key          VARCHAR(65535) NOT NULL,
    key_type             CHAR(2) NOT NULL, -- LC long live current LP long live previous TC token current, TP token previous
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(provider_id, kid),
    FOREIGN KEY(provider_id) REFERENCES auth_provider_t (provider_id) ON DELETE CASCADE
);

-- multiple apis can share the same auth provider. 
CREATE TABLE auth_provider_api_t(
    host_id              UUID NOT NULL,
    api_id               VARCHAR(16) NOT NULL,
    provider_id          VARCHAR(22) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, api_id, provider_id),
    FOREIGN KEY(provider_id) REFERENCES auth_provider_t (provider_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, api_id) REFERENCES api_t(host_id, api_id) ON DELETE CASCADE
);


-- a client can associate with an api or app.
CREATE TABLE auth_client_t (
    host_id               UUID NOT NULL,
    client_id            UUID NOT NULL,
    client_name          VARCHAR(126) NOT NULL,
    app_id               VARCHAR(512), -- this client is owned by an app
    api_id               VARCHAR(16), -- this client is owned by an api
    client_type          VARCHAR(12) NOT NULL, -- public, confidential, trusted, external
    client_profile       VARCHAR(10) NOT NULL, -- webserver, mobile, browser, service, batch
    client_secret        VARCHAR(1024) NOT NULL,
    client_scope         VARCHAR(4000),
    custom_claim         VARCHAR(4000), -- custom claim in json format that will be included in the jwt token
    redirect_uri         VARCHAR(1024),
    authenticate_class   VARCHAR(256),
    deref_client_id      UUID, -- only this client calls AS to deref token to JWT for external client type
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, client_id)
);


CREATE TABLE auth_provider_client_t (
    host_id              UUID NOT NULL,
    client_id            UUID NOT NULL,
    provider_id          VARCHAR(22) NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, client_id, provider_id),
    FOREIGN KEY(provider_id) REFERENCES auth_provider_t (provider_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, client_id) REFERENCES auth_client_t(host_id, client_id) ON DELETE CASCADE
);

CREATE TABLE auth_code_t (
    auth_code            VARCHAR(22) NOT NULL,
    host_id              UUID NOT NULL,
    provider_id          VARCHAR(22) NOT NULL,
    user_id              UUID NOT NULL,
    entity_id            VARCHAR(50) NOT NULL,
    user_type            CHAR(1) NOT NULL,
    email                VARCHAR(126) NOT NULL,
    roles                VARCHAR(4096),
    groups               VARCHAR(4096),
    positions            VARCHAR(4096),
    attributes           VARCHAR(4096),
    redirect_uri         VARCHAR(2048),
    scope                VARCHAR(1024),
    remember             CHAR(1),
    code_challenge       VARCHAR(126),
    challenge_method     VARCHAR(64),
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (auth_code),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (provider_id) REFERENCES auth_provider_t(provider_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);

CREATE TABLE auth_refresh_token_t (
    refresh_token        UUID NOT NULL,
    host_id              UUID NOT NULL,
    provider_id          VARCHAR(22) NOT NULL,
    user_id              UUID NOT NULL,
    entity_id            VARCHAR(50) NOT NULL,
    user_type            CHAR(1) NOT NULL,
    email                VARCHAR(126) NOT NULL,    
    roles                VARCHAR(4096),
    groups               VARCHAR(4096),
    positions            VARCHAR(4096),
    attributes           VARCHAR(4096),
    client_id            UUID NOT NULL,
    scope                VARCHAR(1024),
    csrf                 VARCHAR(36),
    custom_claim         VARCHAR(2000),
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (refresh_token),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);

CREATE TABLE auth_ref_token_t (
    host_id              UUID NOT NULL,
    ref_token            VARCHAR(22) NOT NULL,
    jwt_token            VARCHAR(40960) NOT NULL,
    client_id            UUID NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (ref_token),
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, client_id) REFERENCES auth_client_t(host_id, client_id) ON DELETE CASCADE
);

CREATE TABLE notification_t (
    id                        UUID NOT NULL,
    host_id                   UUID NOT NULL,
    user_id                   UUID NOT NULL,
    nonce                     INTEGER NOT NULL,
    event_class               VARCHAR(255) NOT NULL,
    event_json                TEXT NOT NULL,
    process_ts                TIMESTAMP WITH TIME ZONE NOT NULL,
    is_processed              BOOLEAN NOT NULL,
    error                     VARCHAR(1024) NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE
);


CREATE TABLE message_t (
    from_id    VARCHAR(64) NOT NULL,
    nonce      BIGINT NOT NULL,
    to_email   VARCHAR(64) NOT NULL,
    subject    VARCHAR(256) NOT NULL,
    content    VARCHAR(65536) NOT NULL,
    send_time  TIMESTAMP WITH TIME ZONE NOT NULL
);

ALTER TABLE message_t ADD CONSTRAINT message_pk PRIMARY KEY ( from_id, nonce );

CREATE INDEX message_idx ON message_t (to_email, send_time);


CREATE TABLE config_snapshot_t (
    snapshot_id                 UUID NOT NULL, -- Primary Key, maybe UUIDv7 for time ordering
    snapshot_ts                 TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    snapshot_type               VARCHAR(32) NOT NULL, -- e.g., 'DEPLOYMENT', 'USER_SAVE', 'SCHEDULED_BACKUP'
    description                 TEXT,                 -- User-provided description or system-generated info
    user_id                     UUID,                 -- User who triggered it (if applicable)
    deployment_id               UUID,                 -- FK to deployment_t if snapshot_type is 'DEPLOYMENT'
    -- Scope columns define WHAT this snapshot represents:
    scope_host_id               UUID NOT NULL,      -- Host context (always needed)
    scope_environment           VARCHAR(16),        -- Environment context (if snapshot is env-specific)
    scope_product_id            VARCHAR(8),         -- Product id context
    scope_product_version       VARCHAR(12),        -- Product version context
    scope_service_id            VARCHAR(512),       -- Service id context
    scope_api_id                VARCHAR(16),        -- Api id context
    scope_api_version           VARCHAR(16),        -- Api version context
    -- tag, 
    PRIMARY KEY(snapshot_id),
    FOREIGN KEY(scope_host_id, deployment_id) REFERENCES deployment_t(host_id, deployment_id) ON DELETE SET NULL,
    FOREIGN KEY(user_id) REFERENCES user_t(user_id) ON DELETE SET NULL,
    FOREIGN KEY(scope_host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);

-- Index for finding snapshots by type or scope
CREATE INDEX idx_config_snapshot_scope ON config_snapshot_t (scope_host_id, scope_environment, scope_product_id, 
    scope_product_version, scope_service_id, scope_api_id, scope_api_version, snapshot_type, snapshot_ts);
CREATE INDEX idx_config_snapshot_deployment ON config_snapshot_t (deployment_id);


CREATE TABLE config_snapshot_property_t (
    snapshot_property_id        UUID NOT NULL,         -- Surrogate primary key for easier referencing/updates if needed
    snapshot_id                 UUID NOT NULL,         -- FK to config_snapshot_t
    config_phase                CHAR(1) NOT NULL,      -- Move config phase to this table so that one snapshot can cover all phases
    config_id                   UUID NOT NULL,         -- The config id
    property_id                 UUID NOT NULL,         -- The final property id 
    property_name               VARCHAR(64) NOT NULL,  -- The final property name
    property_type               VARCHAR(32) NOT NULL,  -- The property type
    property_value              TEXT,                  -- The effective property value at snapshot time
    value_type                  VARCHAR(32),           -- Optional: Store the type (string, int, bool...) for easier parsing later
    source_level                VARCHAR(32),           -- e.g., 'instance', 'product_version', 'environment', 'default'
    PRIMARY KEY(snapshot_property_id),
    FOREIGN KEY(snapshot_id) REFERENCES config_snapshot_t(snapshot_id) ON DELETE CASCADE
);

-- Unique constraint to ensure one value per key within a snapshot
ALTER TABLE config_snapshot_property_t
    ADD CONSTRAINT config_snapshot_property_uk UNIQUE (snapshot_id, config_phase, config_id, property_id);

-- Index for quickly retrieving all properties for a snapshot
CREATE INDEX idx_config_snapshot_property_snap_phase ON config_snapshot_property_t (snapshot_id, config_phase);


-- Snapshot of Instance API Overrides
CREATE TABLE snapshot_instance_api_property_t (
    snapshot_id          UUID NOT NULL,
    host_id              UUID NOT NULL,
    instance_api_id      UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY(snapshot_id, host_id, instance_api_id, property_id), -- Composite PK matches original structure + snapshot_id
    FOREIGN KEY(snapshot_id) REFERENCES config_snapshot_t(snapshot_id) ON DELETE CASCADE
);
CREATE INDEX idx_snap_iapi_prop ON snapshot_instance_api_property_t (snapshot_id);


-- Snapshot of Instance App Overrides
CREATE TABLE snapshot_instance_app_property_t (
    snapshot_id          UUID NOT NULL,
    host_id              UUID NOT NULL,
    instance_app_id      UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY(snapshot_id, host_id, instance_app_id, property_id),
    FOREIGN KEY(snapshot_id) REFERENCES config_snapshot_t(snapshot_id) ON DELETE CASCADE
);
CREATE INDEX idx_snap_iapp_prop ON snapshot_instance_app_property_t (snapshot_id);

-- Snapshot of Instance App API Overrides
CREATE TABLE snapshot_instance_app_api_property_t (
    snapshot_id          UUID NOT NULL,
    host_id              UUID NOT NULL,
    instance_app_id      UUID NOT NULL,
    instance_api_id      UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY(snapshot_id, host_id, instance_app_id, instance_api_id, property_id),
    FOREIGN KEY(snapshot_id) REFERENCES config_snapshot_t(snapshot_id) ON DELETE CASCADE
);
CREATE INDEX idx_snap_iaappi_prop ON snapshot_instance_app_api_property_t (snapshot_id);


-- Snapshot of Instance Overrides
CREATE TABLE snapshot_instance_property_t (
    snapshot_id          UUID NOT NULL,
    host_id              UUID NOT NULL,
    instance_id          UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY(snapshot_id, host_id, instance_id, property_id),
    FOREIGN KEY(snapshot_id) REFERENCES config_snapshot_t(snapshot_id) ON DELETE CASCADE
);
CREATE INDEX idx_snap_inst_prop ON snapshot_instance_property_t (snapshot_id);


-- Snapshot of Environment Overrides (If needed for rollback)
CREATE TABLE snapshot_environment_property_t (
    snapshot_id          UUID NOT NULL,
    host_id              UUID NOT NULL,
    environment          VARCHAR(16) NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY(snapshot_id, host_id, environment, property_id),
    FOREIGN KEY(snapshot_id) REFERENCES config_snapshot_t(snapshot_id) ON DELETE CASCADE
);
CREATE INDEX idx_snap_env_prop ON snapshot_environment_property_t (snapshot_id);

CREATE TABLE snapshot_product_property_t (
    snapshot_id          UUID NOT NULL,
    product_id           VARCHAR(8) NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY(snapshot_id, product_id, property_id),
    FOREIGN KEY(snapshot_id) REFERENCES config_snapshot_t(snapshot_id) ON DELETE CASCADE
);
CREATE INDEX idx_snap_prd_prop ON snapshot_product_property_t (snapshot_id);

CREATE TABLE snapshot_product_version_property_t (
    snapshot_id          UUID NOT NULL,
    host_id              UUID NOT NULL,
    product_version_id   UUID NOT NULL,
    property_id          UUID NOT NULL,
    property_value       TEXT,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY(snapshot_id, host_id, product_version_id, property_id),
    FOREIGN KEY(snapshot_id) REFERENCES config_snapshot_t(snapshot_id) ON DELETE CASCADE
);
CREATE INDEX idx_snap_pv_prop ON snapshot_product_version_property_t (snapshot_id);


CREATE TABLE worklist_t (
    assignee_id          VARCHAR(126) NOT NULL,
    category_id          VARCHAR(126) DEFAULT '(all)' NOT NULL,
    status_code          VARCHAR(10) DEFAULT 'Active' NOT NULL,
    app_id               VARCHAR(512) DEFAULT 'global' NOT NULL,
    aggregate_version    BIGINT DEFAULT 1 NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(assignee_id, category_id)
);

CREATE TABLE worklist_column_t (
  assignee_id           VARCHAR(126) NOT NULL,
  category_id           VARCHAR(126) DEFAULT '(all)' NOT NULL,
  sequence_id           INTEGER NOT NULL,
  column_id             VARCHAR(126) NOT NULL,
  PRIMARY KEY(assignee_id, category_id, sequence_id),
  FOREIGN KEY(assignee_id, category_id) REFERENCES worklist_t(assignee_id, category_id) ON DELETE CASCADE
);

CREATE TABLE process_info_t (
  process_id                 UUID NOT NULL, -- generated uuid
  wf_instance_id             VARCHAR(126)       NOT NULL, -- workflow intance id
  app_id                     VARCHAR(512)       NOT NULL, -- application id
  process_type               VARCHAR(126)      NOT NULL,
  status_code                CHAR(1)            NOT NULL, -- process status code 'A', 'C'
  started_ts                 TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
  ex_trigger_ts              TIMESTAMP WITH TIME ZONE          NOT NULL,
  custom_status_code         VARCHAR(126),
  completed_ts               TIMESTAMP WITH TIME ZONE,
  result_code                VARCHAR(126),
  source_id                  VARCHAR(126),
  branch_code                VARCHAR(126),
  rr_code                    VARCHAR(126),
  party_id                   VARCHAR(126),
  party_name                 VARCHAR(126),
  counter_party_id           VARCHAR(126),
  counter_party_name         VARCHAR(126),
  txn_id                     VARCHAR(126),
  txn_name                   VARCHAR(126),
  product_id                 VARCHAR(126),
  product_name               VARCHAR(126),
  product_type               VARCHAR(126),
  group_name                 VARCHAR(126),
  subgroup_name              VARCHAR(126),
  event_start_ts             TIMESTAMP WITH TIME ZONE,
  event_end_ts               TIMESTAMP WITH TIME ZONE,
  event_other_ts             TIMESTAMP WITH TIME ZONE,
  event_other                VARCHAR(126),
  risk                       NUMERIC,
  risk_scale                 INTEGER,
  price                      NUMERIC,
  price_scale                INTEGER, -- Scale (number of digits to the right of the decimal) of the risk column. NULL implies zero
  product_qy                 NUMERIC,
  currency_code              CHAR(3),
  ex_ref_id                  VARCHAR(126),
  ex_ref_code                VARCHAR(126),
  product_qy_scale           INTEGER,
  parent_process_id          VARCHAR(22),
  deadline_ts                TIMESTAMP WITH TIME ZONE,
  parent_group_id            NUMERIC,
  process_subtype_code       VARCHAR(126),
  owning_group_name          VARCHAR(126), -- Name of the group that owns the process
  PRIMARY KEY(process_id)
);

CREATE TABLE task_info_t
(
    task_id             UUID NOT NULL,
    task_type           VARCHAR(126) NOT NULL,
    process_id          UUID NOT NULL,
    wf_instance_id      VARCHAR(126) NOT NULL,
    wf_task_id          VARCHAR(126) NOT NULL,
    status_code         CHAR(1)       NOT NULL, -- U, A, C 
    started_ts          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    locked              CHAR(1)       NOT NULL,
    priority            INTEGER        NOT NULL,
    completed_ts        TIMESTAMP WITH TIME ZONE      NULL,
    completed_user      VARCHAR(126)     NULL,
    result_code         VARCHAR(126)     NULL,
    locking_user        VARCHAR(126)     NULL,
    locking_role        VARCHAR(126)     NULL,
    deadline_ts         TIMESTAMP WITH TIME ZONE      NULL,
    lock_group          VARCHAR(126)     NULL,
    PRIMARY KEY(task_id),
    FOREIGN KEY (process_id) REFERENCES process_info_t(process_id) ON DELETE CASCADE
);

CREATE TABLE task_asst_t 
(
    task_asst_id         UUID NOT NULL,
    task_id              UUID NOT NULL,
    assigned_ts          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    assignee_id          VARCHAR(126) NOT NULL,
    reason_code          VARCHAR(126) NOT NULL,
    ACTIVE               CHAR(1)      DEFAULT 'Y' NOT NULL,
    unassigned_ts        TIMESTAMP WITH TIME ZONE      NULL,
    unassigned_reason    VARCHAR(126)     NULL,
    category_code        VARCHAR(126)     NULL,
    PRIMARY KEY(task_asst_id),
    FOREIGN KEY(task_id) REFERENCES task_info_t(task_id) ON DELETE CASCADE
);

CREATE TABLE audit_log_t 
(
    audit_log_id         UUID NOT NULL,
    source_type_id       VARCHAR(126)      NULL,
    correlation_id       VARCHAR(126)      NULL,
    user_id              VARCHAR(126)     NULL,
    event_ts             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    success              CHAR(1)           NULL,
    message0             VARCHAR(126)     NULL,
    message1             VARCHAR(126)     NULL,
    message2             VARCHAR(126)     NULL,
    message3             VARCHAR(126)     NULL,
    message              VARCHAR(500)     NULL,
    user_comment         VARCHAR(500)     NULL,
    PRIMARY KEY(audit_log_id)
);

CREATE INDEX audit_log_idx1 ON audit_log_t (source_type_id, correlation_id, event_ts, user_id);


ALTER TABLE product_version_t
    ADD CONSTRAINT host_id_fk FOREIGN KEY (host_id)
        REFERENCES host_t (host_id)
            ON DELETE CASCADE;


ALTER TABLE api_endpoint_scope_t
    ADD CONSTRAINT api_ver_fk FOREIGN KEY (host_id, endpoint_id)
        REFERENCES api_endpoint_t (host_id, endpoint_id)
            ON DELETE CASCADE;

ALTER TABLE api_endpoint_rule_t
    ADD CONSTRAINT api_fkr FOREIGN KEY (host_id, endpoint_id)
        REFERENCES api_endpoint_t (host_id, endpoint_id )
            ON DELETE CASCADE;

ALTER TABLE api_endpoint_rule_t
    ADD CONSTRAINT rule_fk FOREIGN KEY ( rule_id )
        REFERENCES rule_t ( rule_id )
            ON DELETE CASCADE;

ALTER TABLE api_version_t
    ADD CONSTRAINT api_fkv2 FOREIGN KEY (host_id, api_id )
        REFERENCES api_t (host_id, api_id )
            ON DELETE CASCADE;

ALTER TABLE instance_api_t
    ADD CONSTRAINT instance_fk FOREIGN KEY ( host_id, instance_id )
        REFERENCES instance_t (host_id, instance_id )
            ON DELETE CASCADE;

ALTER TABLE instance_app_t
    ADD CONSTRAINT instance_fkv1 FOREIGN KEY (host_id, instance_id )
        REFERENCES instance_t (host_id, instance_id )
            ON DELETE CASCADE;

ALTER TABLE instance_property_t
    ADD CONSTRAINT instance_fkv2 FOREIGN KEY (host_id, instance_id )
        REFERENCES instance_t (host_id, instance_id )
            ON DELETE CASCADE;


ALTER TABLE app_api_t
    ADD CONSTRAINT api_scope_fk FOREIGN KEY (host_id, endpoint_id, scope )
        REFERENCES api_endpoint_scope_t (host_id, endpoint_id, scope )
            ON DELETE CASCADE;

ALTER TABLE api_endpoint_rule_t
    ADD CONSTRAINT api_fk FOREIGN KEY (host_id, endpoint_id)
        REFERENCES api_endpoint_t (host_id, endpoint_id)
            ON DELETE CASCADE;

ALTER TABLE api_endpoint_t
    ADD CONSTRAINT api_version_fk FOREIGN KEY (host_id, api_version_id)
        REFERENCES api_version_t ( host_id, api_version_id)
            ON DELETE CASCADE;

ALTER TABLE instance_api_t
    ADD CONSTRAINT api_version_fkv1 FOREIGN KEY (host_id, api_version_id)
        REFERENCES api_version_t ( host_id, api_version_id )
            ON DELETE CASCADE;

ALTER TABLE app_api_t
    ADD CONSTRAINT app_fk FOREIGN KEY ( host_id, app_id )
        REFERENCES app_t ( host_id, app_id )
            ON DELETE CASCADE;

ALTER TABLE instance_app_t
    ADD CONSTRAINT app_fkv1 FOREIGN KEY ( host_id, app_id )
        REFERENCES app_t ( host_id, app_id )
            ON DELETE CASCADE;


ALTER TABLE chain_handler_t
    ADD CONSTRAINT configuration_fk FOREIGN KEY ( configuration_id )
        REFERENCES config_t ( config_id )
            ON DELETE CASCADE;

ALTER TABLE config_property_t
    ADD CONSTRAINT config_fkv2 FOREIGN KEY ( config_id )
        REFERENCES config_t ( config_id )
            ON DELETE CASCADE;


ALTER TABLE environment_property_t
    ADD CONSTRAINT host_fk FOREIGN KEY (host_id)
        REFERENCES host_t (host_id)
            ON DELETE CASCADE;

ALTER TABLE instance_property_t
    ADD CONSTRAINT config_property_fkv1 FOREIGN KEY (property_id)
        REFERENCES config_property_t (property_id)
            ON DELETE CASCADE;

ALTER TABLE product_property_t
    ADD CONSTRAINT config_property_fkv2 FOREIGN KEY (property_id)
        REFERENCES config_property_t (property_id)
            ON DELETE CASCADE;

ALTER TABLE product_version_property_t
    ADD CONSTRAINT config_property_fkv3 FOREIGN KEY (property_id)
        REFERENCES config_property_t (property_id)
            ON DELETE CASCADE;

ALTER TABLE instance_api_property_t
    ADD CONSTRAINT config_property_fkv5 FOREIGN KEY (property_id)
        REFERENCES config_property_t (property_id)
            ON DELETE CASCADE;

ALTER TABLE instance_app_property_t
    ADD CONSTRAINT config_property_fkv6 FOREIGN KEY (property_id)
        REFERENCES config_property_t (property_id)
            ON DELETE CASCADE;


ALTER TABLE instance_app_property_t
    ADD CONSTRAINT instance_app_fk FOREIGN KEY ( host_id, instance_app_id)
        REFERENCES instance_app_t ( host_id, instance_app_id)
            ON DELETE CASCADE;


ALTER TABLE instance_t
    ADD CONSTRAINT product_version_fk FOREIGN KEY (host_id, product_version_id)
        REFERENCES product_version_t (host_id, product_version_id)
            ON DELETE CASCADE;

ALTER TABLE product_version_property_t
    ADD CONSTRAINT product_version_fkv1 FOREIGN KEY (host_id, product_version_id)
        REFERENCES product_version_t (host_id, product_version_id )
            ON DELETE CASCADE;



-- bootstrap org lightapi.net domain by default.
INSERT INTO org_t (domain, org_name, org_desc) VALUES ('lightapi.net', 'Light API Portal', 'Light API Portal');

-- bootstrap host. insert the dev.lightapi.net as the default host. 
INSERT INTO host_t (host_id, domain, sub_domain) VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'lightapi.net', 'dev');

-- bootstrap OAuth provider to support user login
INSERT INTO auth_provider_t (host_id, provider_id, provider_name, provider_desc, jwk) VALUES (
'01964b05-552a-7c4b-9184-6857e7f3dc5f', 'AZZRJE52eXu3t1hseacnGQ', 'A generic auth provider for lightapi.net dev', 'This is the single provider for the lightapi.net dev environment',
'{"keys":[{"kty":"RSA","kid":"AZZRNu8YfBSkvP9bWcrq1g","n":"h25ydNVptrcDlUiixNtcdsjDUyTT2ZlarxIyRpsOZNWpQ_kXjn723j9YnyePeQkC88K-MPWYhRHKp9w_HwZvWvGgQNk5wlGW3PbOAldbW_5-j5gizPDM8d5mTAThbjsve5wVWwN51utQoqFNdkCQ8sJ5mHbaiSTTUHIDhbKriIlFhsNdLZEHj0yO3awnH8KYxzvbrGzqKse4bDNu7a-dYcjmEbmZ0qGuLYbNeHN4vc-1QukFlnnLD9XNmbh9Gurv52box-Sx2VcU1EY_PaFae2p2BgVBbqLJhcv176vIpKAnIFnyb1aNtP19wOB3JbZDhXhXdG9QhEjUYzLOiV5HnQ","e":"AQAB"},{"kty":"RSA","kid":"AZZRN46Seu265eHZsejgmA","n":"0YRbWAb1FGDpPUUcrIpJC6BwlswlKMS-z2wMAobdo0BNxNa7hG_gIHVPkXu14Jfo1JhUhS4wES3DdY3a6olqPcRN1TCCUVHd-1TLd1BBS-yq9tdJ6HCewhe5fXonaRRKwutvoH7i_eR4m3fQ1GoVzVAA3IngpTr4ptnM3Ef3fj-5wZYmitzrRUyQtfARTl3qGaXP_g8pHFAP0zrNVvOnV-jcNMKm8YZNcgcs1SuLSFtUDXpf7Nr2_xOhiNM-biES6Dza1sMLrlxULFuctudO9lykB7yFh3LHMxtIZyIUHuy0RbjuOGC5PmDowLttZpPI_j4ynJHAaAWr8Ddz764WdQ","e":"AQAB"}]}'
);

-- bootstrap provider long-lived current key to support user login
INSERT INTO auth_provider_key_t (provider_id, kid, public_key, private_key, key_type) VALUES (
'AZZRJE52eXu3t1hseacnGQ',
'AZZRNu8YfBSkvP9bWcrq1g',
'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAh25ydNVptrcDlUiixNtcdsjDUyTT2ZlarxIyRpsOZNWpQ/kXjn723j9YnyePeQkC88K+MPWYhRHKp9w/HwZvWvGgQNk5wlGW3PbOAldbW/5+j5gizPDM8d5mTAThbjsve5wVWwN51utQoqFNdkCQ8sJ5mHbaiSTTUHIDhbKriIlFhsNdLZEHj0yO3awnH8KYxzvbrGzqKse4bDNu7a+dYcjmEbmZ0qGuLYbNeHN4vc+1QukFlnnLD9XNmbh9Gurv52box+Sx2VcU1EY/PaFae2p2BgVBbqLJhcv176vIpKAnIFnyb1aNtP19wOB3JbZDhXhXdG9QhEjUYzLOiV5HnQIDAQAB',
'MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCHbnJ01Wm2twOVSKLE21x2yMNTJNPZmVqvEjJGmw5k1alD+ReOfvbeP1ifJ495CQLzwr4w9ZiFEcqn3D8fBm9a8aBA2TnCUZbc9s4CV1tb/n6PmCLM8Mzx3mZMBOFuOy97nBVbA3nW61CioU12QJDywnmYdtqJJNNQcgOFsquIiUWGw10tkQePTI7drCcfwpjHO9usbOoqx7hsM27tr51hyOYRuZnSoa4ths14c3i9z7VC6QWWecsP1c2ZuH0a6u/nZujH5LHZVxTURj89oVp7anYGBUFuosmFy/Xvq8ikoCcgWfJvVo20/X3A4HcltkOFeFd0b1CESNRjMs6JXkedAgMBAAECggEAMcLTKzp+7TOxjVhy9gHjp4F8wz/01y8RsuHstySh1UrsNp1/mkvsSRzdYx0WClLVUttrJnIW6E3xOFwklTG4GKJPT4SBRHTWCbplV1bhqpuHxRsRLlwL8ZLV43inm+kDOVfQQPC2A9HSfu7ll12B5LCwHOUOxvVQ7230/Vr4y+GacYHDO0aL7tWAC2fH8hXzvgSc+sosg/gIRro7aasP5GMuFZjtPANzwhovE8vq71ZQTCzEEm890NuzOOYLUCmkE+FDL6Fjg9lckcosmfPuBpqMjAMMAhIHLEwmWBX6najTcuxpzDT6H+4cmU8+TyX2OwBlyAWpFNTLp3ta05tAAQKBgQDRgSxGB83hx5IL1u1gvDsEfS2sKgRDE5ZEeNDOrxI+U6dhgKj7ae11as83AZnA+sAQrHPZowoRAnAlqNFTQKMLxQfocs2sl5pG5xkL7DrlteUtG6gDvjsbtL64wiy6WrfTJvcICiAw9skgSFX+ZTy9GhcvQVrrjrHrjMl2b+uHAQKBgQClfN7SdW9hxKbKzHzpJ4G74Vr0JqYmr2JPu5DezL/Mxnx+sKEA2ByqVAEO6pJKGR5GfwPh91BBc1sRA4PzWtLRR5Dve6dm1puhaXKeREwBgIoDnXvGDfsOnwHQcGJzSgqBmycTTDiBmjnYX8AkZkbHN5lIFriy7G063XsuGIh8nQKBgDpEVb7oXr9DlP/L99smnrdh5Tjzupm5Mdq7Sz+ge09wTqYUdWrvDAbS/OyMemmsk4xPmizWZm9SoUQoDoe7+1zDoK5qd39f7p13moSxX7QRgbqo7XKVDrVm8IBMKMpvfp6wQJYw0sErccaTt674Ewt43SfcYmAPILalQka5W+UBAoGAQpom83zf/vEuT6BNBWkpBXyFJo4HgLpFTuGmRIUTDE81+6cKpVRU9Rgp9N7jUX8aeDTWUzM90ZmjpQ1NJbv/7Mpownl5viHRMP1Ha/sAu/oHkbzn+6XUzOWhzUnt1YiPAep3p4SdmUuAzFx88ClZgwQVZLYAT8Jnk7FfygWFqOECgYBOox0DFatEqB/7MNMoLMZCacSrylZ1NYHJYAdWkxOvahrppAMbDVFDlwvH7i8gVvzcfFxQtOxSJBlUKlamDd5i76O2N+fIPO8P+iyqKz2Uh/emVwWCWlijSOnXvKRUOiujVufGP0OGxi1GKSUaIXnvMQqYF9M/Igi0BQiCn+pFzw==',
'LC'
);


-- bootstrap provider token current key to support user login
INSERT INTO auth_provider_key_t (provider_id, kid, public_key, private_key, key_type) VALUES
(
'AZZRJE52eXu3t1hseacnGQ',
'AZZRN46Seu265eHZsejgmA',
'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0YRbWAb1FGDpPUUcrIpJC6BwlswlKMS+z2wMAobdo0BNxNa7hG/gIHVPkXu14Jfo1JhUhS4wES3DdY3a6olqPcRN1TCCUVHd+1TLd1BBS+yq9tdJ6HCewhe5fXonaRRKwutvoH7i/eR4m3fQ1GoVzVAA3IngpTr4ptnM3Ef3fj+5wZYmitzrRUyQtfARTl3qGaXP/g8pHFAP0zrNVvOnV+jcNMKm8YZNcgcs1SuLSFtUDXpf7Nr2/xOhiNM+biES6Dza1sMLrlxULFuctudO9lykB7yFh3LHMxtIZyIUHuy0RbjuOGC5PmDowLttZpPI/j4ynJHAaAWr8Ddz764WdQIDAQAB',
'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDRhFtYBvUUYOk9RRysikkLoHCWzCUoxL7PbAwCht2jQE3E1ruEb+AgdU+Re7Xgl+jUmFSFLjARLcN1jdrqiWo9xE3VMIJRUd37VMt3UEFL7Kr210nocJ7CF7l9eidpFErC62+gfuL95Hibd9DUahXNUADcieClOvim2czcR/d+P7nBliaK3OtFTJC18BFOXeoZpc/+DykcUA/TOs1W86dX6Nw0wqbxhk1yByzVK4tIW1QNel/s2vb/E6GI0z5uIRLoPNrWwwuuXFQsW5y25072XKQHvIWHcsczG0hnIhQe7LRFuO44YLk+YOjAu21mk8j+PjKckcBoBavwN3PvrhZ1AgMBAAECggEBAMuDYGLqJydLV2PPfSHQFVH430RrOfEW4y2CC0xtCl8n+CKqXm0vaqq8qLRtUWa+yEexS/AtxDz7ke/fAfVt00f6JYxe2Ub6WcBnRlg4GaURV6P7zWu98UghWWkbvaphLpmVrdFdT0pFoi2JvcyG23SaMKwINbDpzlvsFgUm1q3GoCIZXRc8iAKT+Iil1QmGdacGni/D2WzPTLSf1/acZU2TsPBWLS/jsjPe4ac4IDpxssDC+w6QArZ8U64DKJ531C4tK9o+RArQzBrEaZc1mAlw7xAPr36tXvOTUycux6k07ERSIIze2okVmmewL6tX1cb7tY1F8T+ebKGD3xGEAYUCgYEA9Lpy4593uTBww7AupcZq2YL8qHUfnvxIWiFbeIznUezyYyRbjyLDYj+g7QfQJHk579UckDZZDcT3H+wdh1LxQ7HKDlYQn2zt8Kdufs5cvSObeGkSqSY26g4QDRcRcRO3xFs8bQ/CnPNT7hsWSY+8wnuRvjUTstMA1vx1+/HHZfMCgYEA2yq8yFogdd2/wUcFlqjPgbJ98X9ZNbZ06uUCur4egseVlSVE+R2pigVVwFCDQpseGu2GVgW5q8kgDGsaJuEVWIhGZvS9IHONBz/WB0PmOZjXlXOhmT6iT6m/9bAQk8MtOee77lUVvgf7FO8XDKtuPh6VGJpr+YJHxHoEX/dbo/cCgYAjwy9Q1hffxxVjc1aNwR4SJRMY5uy1BfbovOEqD6UqEq8lD8YVd6YHsHaqzK589f4ibwkaheajnXnjf1SdVuCM3OlDCQ6qzXdD6KO8AhoJRa/Ne8VPVJdHwsBTuWBCHviGyDJfWaM93k0QiYLLQyb5YKdenVEAm9cOk5wGMkHKQwKBgH050CASDxYJm/UNZY4N6nLKz9da0lg0Zl2IeKTG2JwU+cz8PIqyfhqUrchyuG0oQG1WZjlkkBAtnRg7YffxB8dMJh3RnPabz2ri+KGyFCu4vwVvylfLR+aIsVvqO66SCJdbZy/ogcHQwY/WhK8CjL0FsF8cbLFl1SfYKAPFTCFFAoGANmOKonyafvWqsSkcl6vUTYYq53IN+qt0IJTDB2cEIEqLXtNth48HvdQkxDF3y4cNLZevhyuIy0Z3yWGbZM2yWbDNn8Q2W5RTyajofQu1mIv2EBzLeOoaSBPLX4G6r4cODSwWbjOdaNxcXd0+uYeAWDuQUSnHpHFJ2r1cpL/9Nbs=',
'TC'
);


INSERT INTO product_version_t (host_id, product_version_id, product_id, product_version, light4j_version, version_desc, release_type, current, version_status)
VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '019664eb-b824-7bc2-9624-68d7ff111810', 'lg', '1.4.5', '2.1.38','This is incremental release to first major release of light gateway', 'Alpha Version', true, 'Supported');


INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('01964b05-5532-7c79-8cde-191dcbd421b8', 'EN', 'Steve', 'Hu', 'steve.hu@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');


INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('01964b05-5532-7ca1-8cdf-2b4e4d655dcf', 'EN', 'Sophia', 'Fung', 'sophia.fung@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');
INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('01964b05-5532-7cdd-8ce0-61ccb92e9bd2', 'EN', 'Jacob', 'Miller', 'jacob.miller@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');
INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('01964b05-5532-7cec-8ce1-d6bb90cbb543', 'EN', 'Michael', 'Carter', 'michael.carter@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');
INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('01964b05-5532-7cfe-8ce2-5f115ef4ca3b', 'EN', 'Kevin', 'Grant', 'kevin.grant@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');
INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('01964b05-5532-7d19-8ce3-28bf63425ba8', 'EN', 'Anthony', 'Riley', 'anthony.riley@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');

INSERT INTO user_host_t (host_id, user_id)  values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '01964b05-5532-7c79-8cde-191dcbd421b8');


INSERT INTO user_host_t (host_id, user_id)  values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '01964b05-5532-7ca1-8cdf-2b4e4d655dcf');
INSERT INTO user_host_t (host_id, user_id)  values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '01964b05-5532-7cdd-8ce0-61ccb92e9bd2');
INSERT INTO user_host_t (host_id, user_id)  values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '01964b05-5532-7cec-8ce1-d6bb90cbb543');
INSERT INTO user_host_t (host_id, user_id)  values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '01964b05-5532-7cfe-8ce2-5f115ef4ca3b');
INSERT INTO user_host_t (host_id, user_id)  values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '01964b05-5532-7d19-8ce3-28bf63425ba8');

INSERT INTO position_t (host_id, position_id, position_desc, inherit_to_ancestor, inherit_to_sibling) VALUES
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'APIPlatformOperations', 'API Platform Operations', 'N', 'N'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', '01964b05-5532-7d6f-8ce4-c218089d41d8', 'API Platform Engineering', 'N', 'N'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'APIPlatformDelivery', 'API Platform Delivery', 'Y', 'Y'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'APIPlatformQA', 'API Platform QA', 'N', 'N');


INSERT INTO employee_t (host_id, employee_id, user_id, title, manager_id, hire_date) VALUES
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'sf32', '01964b05-5532-7ca1-8cdf-2b4e4d655dcf', 'AVP API Platform', NULL, '2023-01-15'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'sh35', '01964b05-5532-7c79-8cde-191dcbd421b8', 'Consulant API Platform', 'sf32', '2023-06-18'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'jm43', '01964b05-5532-7cdd-8ce0-61ccb92e9bd2', 'Director', 'sf32', '2023-02-20'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'mc87', '01964b05-5532-7cec-8ce1-d6bb90cbb543', 'Senior API Platform Solutions Design Engineer', 'jm43', '2023-03-10'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'kg17', '01964b05-5532-7cfe-8ce2-5f115ef4ca3b', 'Senior API Platform Solutions Design Engineer', 'jm43', '2023-04-05'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'ar96', '01964b05-5532-7d19-8ce3-28bf63425ba8', 'Senior Reliability Engineer', 'jm43','2023-05-12');


INSERT INTO employee_position_t (host_id, employee_id, position_id, position_type, start_ts, end_ts) VALUES
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'sh35', 'APIPlatformDelivery', 'P', CURRENT_TIMESTAMP, NULL), -- APIPlatformDelivery
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'jm43', 'APIPlatformDelivery', 'D', CURRENT_TIMESTAMP, NULL),  -- APIPlatformDelivery D from mc87
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'mc87', '01964b05-5532-7d6f-8ce4-c218089d41d8', 'P', CURRENT_TIMESTAMP, NULL),  -- APIPlatformEngineering
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'mc87', 'APIPlatformDelivery', 'P', CURRENT_TIMESTAMP, NULL), -- APIPlatformDelivery
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'kg17', '01964b05-5532-7d6f-8ce4-c218089d41d8', 'P', CURRENT_TIMESTAMP, NULL), -- APIPlatformEngineering
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'kg17', 'APIPlatformDelivery', 'S', CURRENT_TIMESTAMP, NULL), -- APIPlatformDelivery S from mc87
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'ar96', 'APIPlatformQA', 'P', CURRENT_TIMESTAMP, NULL), -- APIPlatformQA
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'ar96', 'APIPlatformDelivery', 'S', CURRENT_TIMESTAMP, NULL); -- APIPlatformDelivery S from mc87


INSERT INTO role_t (host_id, role_id, role_desc) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'user', 'logged in user with an identification in the application');
INSERT INTO role_t (host_id, role_id, role_desc) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'admin', 'logged in admin that can do all admin activities');


INSERT INTO role_user_t (host_id, role_id, user_id) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'user', '01964b05-5532-7c79-8cde-191dcbd421b8');
INSERT INTO role_user_t (host_id, role_id, user_id) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'admin', '01964b05-5532-7c79-8cde-191dcbd421b8');

INSERT INTO attribute_t (host_id, attribute_id, attribute_type, attribute_desc) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'country', 'string', 'The three-letter country code of the user');
INSERT INTO attribute_t (host_id, attribute_id, attribute_type, attribute_desc) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'security_clearance_level', 'integer', 'The security clearance level 1, 2, 3');
INSERT INTO attribute_t (host_id, attribute_id, attribute_type, attribute_desc) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'peranent_employee', 'boolean', 'Indicate if the user is a permanent employee');

INSERT INTO attribute_user_t (host_id, attribute_id, user_id, attribute_value) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'country', '01964b05-5532-7c79-8cde-191dcbd421b8', 'CAN');
INSERT INTO attribute_user_t (host_id, attribute_id, user_id, attribute_value) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'security_clearance_level', '01964b05-5532-7c79-8cde-191dcbd421b8', '2');
INSERT INTO attribute_user_t (host_id, attribute_id, user_id, attribute_value) values ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'peranent_employee', '01964b05-5532-7c79-8cde-191dcbd421b8', 'true');

INSERT INTO group_t (host_id, group_id, group_desc) VALUES
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'select', 'Users with select or view privileges'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'insert', 'Users with insert or add privileges'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'update', 'Users with update or edit privileges'),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'delete', 'Users with delete or remove privileges');

INSERT INTO group_user_t (host_id, group_id, user_id, start_ts) VALUES
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'select', '01964b05-5532-7c79-8cde-191dcbd421b8', CURRENT_TIMESTAMP),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'insert', '01964b05-5532-7c79-8cde-191dcbd421b8', CURRENT_TIMESTAMP),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'update', '01964b05-5532-7c79-8cde-191dcbd421b8', CURRENT_TIMESTAMP),
('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'delete', '01964b05-5532-7c79-8cde-191dcbd421b8', CURRENT_TIMESTAMP);

INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'APM000100', 'Admin Client', 'Access the adm endpoints of light-portal services', false, null, null);


INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'admin client', 'APM000100', 'f7d42348-c647-4efb-a52d-4c5787421e70', 'trusted', 'mobile', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'admin', null, 'https://localhost:3000/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);

INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'APM000123', 'PetStore Web Server', 'PetStore Web Server that calls PetStore API', false, null, null);

INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'petstore server', 'APM000123', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'trusted', 'mobile', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'portal.r portal.w ref.r ref.w', '{"c1": "361", "c2": "67"}', 'https://localhost:3000/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);


INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'APM000124', 'Light Portal Test Web Application', 'Light Portal Test React Single Page Application', false, null, null);

INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'portal web test', 'APM000124', 'f7d42348-c647-4efb-a52d-4c5787421e73', 'trusted', 'browser', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'portal.r portal.w ref.r ref.w', null, 'https://dev.lightapi.net/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);


INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'APM000126', 'Light Portal Test Web Application', 'Light Portal Test React Single Page Application', false, null, null);


INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'portal web app', 'APM000126', 'f7d42348-c647-4efb-a52d-4c5787421e75', 'trusted', 'browser', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'portal.r portal.w ref.r ref.w', null, 'https://dev.lightapi.net/authorization', 'com.networknt.oauth.auth.DefaultAuth', null);

INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'APM000127', 'Petstore Client Application', 'An example application that is used to demo access to openapi-petstore', false, null, null);


INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'petstore app', 'APM000127', 'f7d42348-c647-4efb-a52d-4c5787421e76', 'trusted', 'browser', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'read:pets write:pets', null, 'https://dev.lightapi.net/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);

INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'AZZRJE52eXu3t1hseacnGQ', 'f7d42348-c647-4efb-a52d-4c5787421e70');
INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'AZZRJE52eXu3t1hseacnGQ', 'f7d42348-c647-4efb-a52d-4c5787421e72');
INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'AZZRJE52eXu3t1hseacnGQ', 'f7d42348-c647-4efb-a52d-4c5787421e73');
INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'AZZRJE52eXu3t1hseacnGQ', 'f7d42348-c647-4efb-a52d-4c5787421e75');
INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('01964b05-552a-7c4b-9184-6857e7f3dc5f', 'AZZRJE52eXu3t1hseacnGQ', 'f7d42348-c647-4efb-a52d-4c5787421e76');

INSERT INTO
    api_t (
        host_id,
        api_id,
        api_name,
        api_desc,
        operation_owner,
        delivery_owner,
        region,
        business_group,
        lob,
        platform,
        capability,
        git_repo,
        api_tags,
        api_status
    )
VALUES
    ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '0100', 'Petstore Rest API', 'Petstore Rest API', '01964b05-5532-7c79-8cde-191dcbd421b8', '01964b05-5532-7c79-8cde-191dcbd421b8', null, null, null, null, null, 'https://bitbucket.networknt.com/projects/repos/petstore-api', null, 'onboarded' ),
    ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '0239', 'Petstore GraphQL API', 'Petstore GraphQL API', '01964b05-5532-7c79-8cde-191dcbd421b8', '01964b05-5532-7c79-8cde-191dcbd421b8', null, null, null, null, null, 'https://bitbucket.networknt.com/projects/repos/petstore-graphql', NULL, 'onboarded');


INSERT INTO api_version_t
    (host_id, api_version_id, api_id, api_version, api_type, service_id, api_version_desc, spec_link)
VALUES
    ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '019664ec-c3e4-71f0-9b6c-3c0893ee688e', '0100', '1.0.0', 'openapi', 'com.networknt.petstore-1.0.0', 'First Major release', null),
    ('01964b05-552a-7c4b-9184-6857e7f3dc5f', '019664ec-ebf0-7bf8-a49b-9e6b355baa99', '0239', '1.0.0', 'graphql', 'com.networknt.petstore-2.0.0', 'Second Major release', null);




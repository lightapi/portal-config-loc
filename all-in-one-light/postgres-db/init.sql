CREATE DATABASE configserver;
\c configserver;

DROP TABLE IF EXISTS rule_host_t CASCADE;

DROP TABLE IF EXISTS rule_group_host_t CASCADE;

DROP TABLE IF EXISTS rule_group_t CASCADE;

DROP TABLE IF EXISTS rule_t CASCADE;

DROP TABLE IF EXISTS api_endpoint_rule_t CASCADE;

DROP TABLE IF EXISTS api_endpoint_t CASCADE;

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

DROP TABLE IF EXISTS instance_api_property_t CASCADE;

DROP TABLE IF EXISTS instance_api_t CASCADE;

DROP TABLE IF EXISTS instance_app_property_t CASCADE;

DROP TABLE IF EXISTS instance_app_t CASCADE;

DROP TABLE IF EXISTS instance_path_t CASCADE;

DROP TABLE IF EXISTS instance_property_t CASCADE;

DROP TABLE IF EXISTS network_zone_t CASCADE;


DROP TABLE IF EXISTS product_property_t CASCADE;

DROP TABLE IF EXISTS product_version_property_t CASCADE;

DROP TABLE IF EXISTS product_version_t CASCADE;

DROP TABLE IF EXISTS platform_t CASCADE;

DROP TABLE IF EXISTS pipeline_t CASCADE;

DROP TABLE IF EXISTS deployment_t CASCADE;

DROP TABLE IF EXISTS runtime_instance_t CASCADE;

DROP TABLE IF EXISTS api_endpoint_scope_t CASCADE;

DROP TABLE IF EXISTS tag_t CASCADE;

DROP TABLE IF EXISTS host_t CASCADE;

DROP TABLE IF EXISTS org_t CASCADE;

DROP table IF EXISTS relation_t CASCADE;;

DROP table IF EXISTS relation_type_t CASCADE;;

DROP table IF EXISTS value_locale_t CASCADE;;

DROP table IF EXISTS ref_value_t CASCADE;;

DROP table IF EXISTS ref_host_t CASCADE;;

DROP table IF EXISTS ref_table_t CASCADE;;

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

-- all entities that can potentially share between hosts will not have host_id column.

-- rule_t doesn't have host_id so that it can be duplicated for all nodes for share across hosts.
CREATE TABLE rule_t (
    rule_id              VARCHAR(255) NOT NULL,  -- com.networknt.rule01. or rule01.networknt.com.
    rule_name            VARCHAR(128) NOT NULL, -- easy to remember name.
    rule_version         VARCHAR(32) NOT NULL,  -- version that follows major.minor.patch pattern.
    rule_type            VARCHAR(32) NOT NULL,
    rule_group           VARCHAR(64),
    rule_desc            VARCHAR(1024),
    rule_body            VARCHAR(65535) NOT NULL,
    rule_owner           VARCHAR(64) NOT NULL,
    common               CHAR(1) NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (rule_id)
);

ALTER TABLE rule_t
    ADD CHECK ( common IN ('Y', 'N'));

CREATE INDEX rule_group_idx ON rule_t(rule_group) WHERE rule_group IS NOT NULL;


CREATE TABLE rule_host_t (
    host_id               VARCHAR(22) NOT NULL,
    rule_id               VARCHAR(255) NOT NULL,
    update_user           VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, rule_id)
);

-- define a list of rules that needs to be executed together in sequence.
CREATE TABLE rule_group_t (
    group_id             VARCHAR(64) NOT NULL,
    rule_id              VARCHAR(255) NOT NULL,
    group_name           VARCHAR(128) NOT NULL,
    execute_sequence     INT NOT NULL,         -- execute sequence for the rule_id in the group.
    group_desc           VARCHAR(4000),
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(group_id, rule_id)
);

CREATE TABLE rule_group_host_t (
    host_id                   VARCHAR(22) NOT NULL,
    group_id                  VARCHAR(64) NOT NULL,
    rule_id                   VARCHAR(255) NOT NULL,
    PRIMARY KEY (host_id, group_id, rule_id)
);

-- api must associate with a host, so host_id is in this table.
CREATE TABLE api_endpoint_rule_t (
    host_id              VARCHAR(22) NOT NULL,
    api_id               VARCHAR(22) NOT NULL,
    api_version          VARCHAR(16) NOT NULL,
    endpoint             VARCHAR(1024) NOT NULL,
    rule_id              VARCHAR(255) NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL

);
ALTER TABLE api_endpoint_rule_t ADD CONSTRAINT api_rule_pk PRIMARY KEY ( host_id, api_id, api_version, endpoint, rule_id );


CREATE TABLE api_t (
    host_id                 VARCHAR(22) NOT NULL,
    api_id                  VARCHAR(6) NOT NULL,    -- unique identifier within the org/host.
    api_name                VARCHAR(128) NOT NULL,
    api_desc                VARCHAR(1024),
    operation_owner         VARCHAR(22),
    delivery_owner          VARCHAR(22),
    region                  VARCHAR(2),
    business_group          VARCHAR(64),
    lob                     VARCHAR(16),
    platform                VARCHAR(20),
    capability              VARCHAR(20),
    git_repo                VARCHAR(1024),
    api_tags                VARCHAR(1024),          -- single word separated with comma.
    api_status              VARCHAR(32) NOT NULL,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE api_t ADD CONSTRAINT api_pk PRIMARY KEY (host_id, api_id);



CREATE TABLE api_version_t (
    host_id                 VARCHAR(22) NOT NULL,
    api_id                  VARCHAR(22) NOT NULL,
    api_version             VARCHAR(16) NOT NULL,
    api_type                VARCHAR(7) NOT NULL,    -- openapi, graphql, hybrid
    service_id              VARCHAR(64) NOT NULL,   -- several api version can have one service_id
    api_version_desc        VARCHAR(1024),
    spec_link               VARCHAR(1024),
    spec                    TEXT,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE api_version_t ADD CONSTRAINT api_version_pk PRIMARY KEY (host_id, api_id, api_version );


CREATE TABLE api_endpoint_t (
    host_id              VARCHAR(22) NOT NULL,
    api_id               VARCHAR(22) NOT NULL,
    api_version          VARCHAR(16) NOT NULL,
    endpoint             VARCHAR(1024) NOT NULL,  -- endpoint path@method
    http_method          VARCHAR(10),
    endpoint_path        VARCHAR(1024),
    endpoint_name        VARCHAR(128) NOT NULL,
    endpoint_desc        VARCHAR(1024),
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE api_endpoint_t
    ADD CHECK ( http_method IN ( 'delete', 'get', 'patch', 'post', 'put' ) );

ALTER TABLE api_endpoint_t ADD CONSTRAINT api_endpoint_pk PRIMARY KEY (host_id, api_id, api_version, endpoint );


CREATE TABLE api_endpoint_scope_t (
    host_id                 VARCHAR(22) NOT NULL,
    api_id                  VARCHAR(22) NOT NULL,
    api_version             VARCHaR(16) NOT NULL,
    endpoint                VARCHAR(1024) NOT NULL,
    scope                   VARCHAR(128) NOT NULL,
    scope_desc              VARCHAR(1024),
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE api_endpoint_scope_t ADD CONSTRAINT api_endpoint_scope_pk PRIMARY KEY (host_id, api_id, api_version, endpoint, scope );


-- The calling relationship between app and api with scope.
CREATE TABLE app_api_t (
    host_id                 VARCHAR(22) NOT NULL,
    app_id                  VARCHAR(22) NOT NULL,
    api_id                  VARCHAR(22) NOT NULL,
    api_version             VARCHAR(16) NOT NULL,
    endpoint                VARCHAR(1024) NOT NULL,
    scope                   VARCHAR(128) NOT NULL,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE app_api_t ADD CONSTRAINT app_api_pk PRIMARY KEY ( host_id, app_id, api_id, api_version, endpoint, scope );


CREATE TABLE app_t (
    host_id                 VARCHAR(22) NOT NULL,
    app_id                  VARCHAR(22) NOT NULL,
    app_name                VARCHAR(128) NOT NULL,
    app_desc                VARCHAR(2048),
    is_kafka_app            BOOLEAN DEFAULT false,
    operation_owner         VARCHAR(22),
    delivery_owner          VARCHAR(22),
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE app_t ADD CONSTRAINT app_pk PRIMARY KEY ( host_id, app_id);




CREATE TABLE chain_handler_t (
    chain_id          VARCHAR(22) NOT NULL,
    configuration_id  VARCHAR(22) NOT NULL,
    sequence_id       INTEGER NOT NULL,
    update_user       VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE chain_handler_t ADD CONSTRAINT chain_handler_pk PRIMARY KEY ( chain_id,
                                                                          configuration_id );



-- each config file will have an entry in this table including the deployment files.
CREATE TABLE config_t (
    config_id                 VARCHAR(22) NOT NULL,
    config_name               VARCHAR(128) NOT NULL,
    config_phase              CHAR(1) NOT NULL DEFAULT 'R', -- D deployment R runtime
    config_type               VARCHAR(32) DEFAULT 'Handler',
    light4j_version           VARCHAR(12), -- initial population has no version. Each new config file introduced willl have a version
    class_path                VARCHAR(1024),
    config_desc               VARCHAR(4096),
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE config_t
    ADD CHECK ( config_type IN ( 'Handler', 'Module', 'Template') );

ALTER TABLE config_t
    ADD CHECK ( config_phase IN ( 'D', 'R') );

ALTER TABLE config_t ADD CONSTRAINT config_pk PRIMARY KEY ( config_id );

-- each config file will have a config_id reference and this table contains all the properties including default. 
CREATE TABLE config_property_t (
    config_id                 VARCHAR(22) NOT NULL,
    property_name             VARCHAR(64) NOT NULL,
    property_type             VARCHAR(32) DEFAULT 'Config' NOT NULL,
    light4j_version           VARCHAR(12), -- only newly introduced property has a version.
    display_order             INTEGER,
    required                  BOOLEAN DEFAULT false NOT NULL,
    property_desc             VARCHAR(1024),
    property_value            TEXT,
    value_type                VARCHAR(32),
    property_file             TEXT,
    resource_type             VARCHAR(30) DEFAULT 'none',
    update_user               VARCHAR(255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE config_property_t
    ADD CHECK ( property_type IN ( 'Cert', 'Config', 'File') );


COMMENT ON COLUMN config_property_t.property_value IS
    'Property Default Value';

COMMENT ON COLUMN config_property_t.value_type IS
    'One of string, boolean, integer, map, list';

COMMENT ON COLUMN config_property_t.resource_type IS
  'One of none, api, app, app_api, api|app_api, app|app_api, all';

ALTER TABLE config_property_t ADD CONSTRAINT config_property_pk PRIMARY KEY ( config_id, property_name );




CREATE TABLE environment_property_t (
    environment      VARCHAR(16) NOT NULL,
    config_id        VARCHAR(22) NOT NULL,
    property_name    VARCHAR(64) NOT NULL,
    property_value   TEXT,
    property_file    TEXT,
    update_user      VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE environment_property_t ADD CONSTRAINT environment_property_pk PRIMARY KEY ( environment,
                                                                                        config_id,
                                                                                        property_name);

-- for each platform like jenkins, ansible etc. 
CREATE TABLE platform_t (
    host_id                     VARCHAR(22) NOT NULL,
    platform_id                 VARCHAR(22) NOT NULL,
    platform_name               VARCHAR(126) NOT NULL,
    platform_version            VARCHAR(8) NOT NULL,
    client_type                 VARCHAR(10)NOT NULL,
    client_url                  VARCHAR(255) NOT NULL,
    credentials                 VARCHAR(255) NOT NULL,
    proxy_url                   VARCHAR(255),
    proxy_port                  INTEGER,
    console_url                 VARCHAR(255), -- the url pattern that we can access the console logs. 
    environment                 VARCHAR(16),
    system_env                  VARCHAR(16),
    runtime_env                 VARCHAR(16),
    zone                        VARCHAR(16),
    region                      VARCHAR(16),
    lob                         VARCHAR(16),
    update_user                 VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, platform_id)
);

--  each platform will have multiple pipelines. 
CREATE TABLE pipeline_t (
    host_id                     VARCHAR(22) NOT NULL,
    pipeline_id                 VARCHAR(22) NOT NULL,
    platform_id                 VARCHAR(22) NOT NULL,
    endpoint                    VARCHAR(1024) NOT NULL,
    request_schema              TEXT NOT NULL,
    response_schema             TEXT NOT NULL,
    update_user                 VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, pipeline_id),
    FOREIGN KEY(host_id, platform_id) REFERENCES platform_t(host_id, platform_id) ON DELETE CASCADE
);


CREATE TABLE instance_t (
    host_id              VARCHAR(22) NOT NULL,
    instance_id          VARCHAR(22) NOT NULL,
    instance_name        VARCHAR(126) NOT NULL,
    product_id           VARCHAR(8) NOT NULL,
    product_version      VARCHAR(12) NOT NULL,
    service_id           VARCHAR(128) NOT NULL, -- for a standalone product, use service_id for query.
    api_id               VARCHAR(22),  -- for sidecar, lpc, lps etc. that related to an api.
    api_version          VARCHAR(16),  -- use api_id and api_version.
    environment          VARCHAR(16),
    pipeline_id          VARCHAR(22) NOT NULL, -- each instance will map to a pipeline for deployment.
    service_desc         VARCHAR(1024),
    instance_desc        VARCHAR(1024),
    tag_id               VARCHAR(22),
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, instance_id),
    FOREIGN KEY(host_id, pipeline_id) REFERENCES pipeline_t(host_id, pipeline_id) ON DELETE CASCADE
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
    ADD CONSTRAINT instance_uk UNIQUE ( service_id,
                                                     product_id,
                                                     product_version,
                                                     tag_id );


-- one gateway instance can have multiple APIs managed by it. 
CREATE TABLE instance_api_t (
    host_id          VARCHAR(22) NOT NULL,
    instance_id      VARCHAR(22) NOT NULL,
    api_id           VARCHAR(22) NOT NULL,
    api_version      VARCHAR(22) NOT NULL,
    active           BOOLEAN DEFAULT true,
    update_user      VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_api_t ADD CONSTRAINT instance_api_pk PRIMARY KEY ( host_id, instance_id, api_id, api_version );



CREATE TABLE instance_api_property_t (
    host_id          VARCHAR(22) NOT NULL,
    instance_id      VARCHAR(22) NOT NULL,
    api_id           VARCHAR(22) NOT NULL,
    api_version      VARCHAR(16) NOT NULL,
    config_id        VARCHAR(22) NOT NULL,
    property_name    VARCHAR(64) NOT NULL,
    property_value   TEXT,
    property_file    TEXT,
    update_user      VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_api_property_t ADD CONSTRAINT instance_api_property_pk
PRIMARY KEY ( host_id, instance_id, api_id, api_version, config_id, property_name);




-- one gateway instance may have many applications connecting to it to consume APIs.
CREATE TABLE instance_app_t (
    host_id                 VARCHAR(22) NOT NULL,
    instance_id             VARCHAR(22) NOT NULL,
    app_id                  VARCHAR(64) NOT NULL,
    app_version             VARCHAR(16) NOT NULL,
    active                  BOOLEAN DEFAULT true,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_app_t ADD CONSTRAINT instance_app_pk PRIMARY KEY ( host_id, instance_id, app_id, app_version);



CREATE TABLE instance_app_property_t (
    host_id                 VARCHAR(22) NOT NULL,
    instance_id             VARCHAR(22) NOT NULL,
    app_id                  VARCHAR(22) NOT NULL,
    app_version             VARCHAR(16) NOT NULL,
    config_id               VARCHAR(22) NOT NULL,
    property_name           VARCHAR(64) NOT NULL,
    property_value          TEXT,
    property_file           TEXT,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE instance_app_property_t ADD CONSTRAINT instance_app_property_pk PRIMARY KEY (host_id, instance_id, app_id,
                                                                                         app_version, config_id, property_name);



CREATE TABLE instance_property_t (
    host_id           VARCHAR(22) NOT NULL,
    instance_id       VARCHAR(22) NOT NULL,
    config_id         VARCHAR(22) NOT NULL,
    property_name     VARCHAR(64) NOT NULL,
    property_value    TEXT,
    property_file     TEXT,
    update_user       VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts         TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_property_t ADD CONSTRAINT instance_property_pk PRIMARY KEY ( host_id, instance_id,
                                                                                  config_id, property_name );




-- product level customized properties which is generic or common for the product. 
CREATE TABLE product_property_t (
    product_id       VARCHAR(8) NOT NULL,
    config_id        VARCHAR(22) NOT NULL,
    property_name    VARCHAR(64) NOT NULL,
    property_value   TEXT,
    property_file    TEXT,
    update_user      VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE product_property_t ADD CONSTRAINT product_property_pk PRIMARY KEY ( product_id,
                                                                                config_id,
                                                                                property_name);

CREATE TABLE product_version_t (
    host_id                     VARCHAR(22) NOT NULL,
    product_id                  VARCHAR(8) NOT NULL,
    product_version             VARCHAR(12) NOT NULL, -- internal product version 
    light4j_version             VARCHAR(12) NOT NULL, -- open source release version
    break_code                  BOOLEAN DEFAULT false, -- breaking code change to upgrade to this version.
    break_config                BOOLEAN DEFAULT false, -- config server need this to decide if clone is allowed for this version. 
    release_note                TEXT,
    version_desc                VARCHAR(1024),
    release_type                VARCHAR(24) NOT NULL, -- Alpha Version, Beta Version, Release Candidate, General Availability, Production Release
    current                     BOOLEAN DEFAULT false,
    version_status              VARCHAR(16) NOT NULL, 
    update_user                 VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, product_id, product_version)
);


-- customized property for product version within the host.
CREATE TABLE product_version_property_t (
    host_id          VARCHAR(22) NOT NULL,
    product_id       VARCHAR(8) NOT NULL,
    product_version  VARCHAR(12) NOT NULL,
    config_id        VARCHAR(22) NOT NULL,
    property_name    VARCHAR(64) NOT NULL,
    property_value   TEXT,
    property_file    TEXT,
    update_user      VARCHAR (126) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE product_version_property_t
    ADD CONSTRAINT product_version_property_pk PRIMARY KEY ( host_id, 
                                                             product_id,
                                                             product_version,
                                                             config_id,
                                                             property_name);



CREATE TABLE deployment_t (
    host_id                     VARCHAR(22) NOT NULL,
    deployment_id               VARCHAR(22) NOT NULL,
    instance_id                 VARCHAR(22) NOT NULL,
    deployment_status           VARCHAR(16) NOT NULL,
    deployment_type             VARCHAR(16) NOT NULL,
    schedule_ts                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    platform_job_id             VARCHAR(126),           -- update by the executor once it is started
    update_user                 VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, deployment_id),
    FOREIGN KEY(host_id, instance_id) REFERENCES instance_t(host_id, instance_id) ON DELETE CASCADE
);

-- runtime instance created by the control pane or deployment executor.
CREATE TABLE runtime_instance_t (
    host_id                     VARCHAR(22) NOT NULL,
    runtime_instance_id         VARCHAR(22) NOT NULL,  -- auto generated uuid as part of pk
    deployment_id               VARCHAR(22) NOT NULL,  -- which deployment created this instance
    instance_id                 VARCHAR(126) NOT NULL, -- which logical instance in instance_t
    instance_status             VARCHAR(16) NOT NULL,  -- deployed, running, shutdown, starting 
    update_user                 VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, runtime_instance_id),
    FOREIGN KEY(host_id, deployment_id) REFERENCES deployment_t(host_id, deployment_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, instance_id) REFERENCES instance_t(host_id, instance_id) ON DELETE CASCADE
);


-- tag is per host and the id is UUID.
CREATE TABLE tag_t (
    host_id                   VARCHAR(22) NOT NULL,
    tag_id                    VARCHAR(22) NOT NULL,
    tag_name                  VARCHAR(128) NOT NULL,
    tag_type                  VARCHAR(30) NOT NULL DEFAULT 'User',
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE tag_t ADD CONSTRAINT tag_pk PRIMARY KEY ( host_id, tag_id );

ALTER TABLE tag_t ADD CONSTRAINT tag_uk UNIQUE ( tag_name );

ALTER TABLE tag_t ADD CHECK ( tag_type IN ( 'System', 'User' ) );

CREATE TABLE org_t (
    domain                    VARCHAR(64) NOT NULL,  -- networknt.com lightapi.net
    org_name                  VARCHAR(128) NOT NULL,
    org_desc                  VARCHAR(4096) NOT NULL,
    org_owner                 VARCHAR(22),
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(domain)
);


CREATE TABLE host_t (
    host_id                   VARCHAR(22) NOT NULL, -- a generated unique identifier.
    domain                    VARCHAR(64) NOT NULL,
    sub_domain                VARCHAR(64) NOT NULL, -- dev, sit, stg, prd, pre-sit, sit-green, sit-ca, sit-us etc.
    host_desc                 VARCHAR(4096),
    host_owner                VARCHAR(22),
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id),
    FOREIGN KEY(domain) REFERENCES org_t(domain) ON DELETE CASCADE
);


ALTER TABLE host_t ADD CONSTRAINT domain_uk UNIQUE ( domain, sub_domain );



CREATE TABLE ref_table_t (
  table_id             VARCHAR(22) NOT NULL, -- UUID genereated by Util
  table_name           VARCHAR(80) NOT NULL, -- Name of the ref table for lookup.
  table_desc           VARCHAR(1024) NULL,
  active               CHAR(1) NOT NULL DEFAULT 'Y', -- Only active table returns values
  editable             CHAR(1) NOT NULL DEFAULT 'Y', -- Table value and locale can be updated via ref admin
  common               CHAR(1) NOT NULL DEFAULT 'Y', -- The drop down shared across hosts
  PRIMARY KEY(table_id)
);

CREATE TABLE ref_host_t (
  table_id             VARCHAR(22) NOT NULL,
  host_id              VARCHAR(22) NOT NULL,
  PRIMARY KEY (table_id, host_id),
  FOREIGN KEY (table_id) REFERENCES ref_table_t (table_id) ON DELETE CASCADE,
  FOREIGN KEY (host_id) REFERENCES host_t (host_id) ON DELETE CASCADE
);

CREATE TABLE ref_value_t (
  value_id              VARCHAR(22) NOT NULL,
  table_id              VARCHAR(22) NOT NULL,
  value_code            VARCHAR(80) NOT NULL, -- The dropdown value
  start_time            TIMESTAMP NULL,
  end_time              TIMESTAMP NULL,
  display_order         INT,                  -- for editor and dropdown list.
  active                VARCHAR(1) NOT NULL DEFAULT 'Y',
  PRIMARY KEY(value_id),
  FOREIGN KEY (table_id) REFERENCES ref_table_t (table_id) ON DELETE CASCADE
);


CREATE TABLE value_locale_t (
  value_id              VARCHAR(22) NOT NULL,
  language              VARCHAR(2) NOT NULL,
  value_desc            VARCHAR(256) NULL, -- The drop label in language.
  PRIMARY KEY(value_id,language),
  FOREIGN KEY (value_id) REFERENCES ref_value_t (value_id) ON DELETE CASCADE
);



CREATE TABLE relation_type_t (
  relation_id           VARCHAR(22) NOT NULL,
  relation_name         VARCHAR(32) NOT NULL, -- The lookup keyword for the relation.
  relation_desc         VARCHAR(1024) NOT NULL,
  PRIMARY KEY(relation_id)
);



CREATE TABLE relation_t (
  relation_id           VARCHAR(22) NOT NULL,
  value_id_from         VARCHAR(22) NOT NULL,
  value_id_to           VARCHAR(22) NOT NULL,
  active                VARCHAR(1) NOT NULL DEFAULT 'Y',
  PRIMARY KEY (relation_id, value_id_from, value_id_to),
  FOREIGN KEY (relation_id) REFERENCES relation_type_t (relation_id) ON DELETE CASCADE,
  FOREIGN KEY (value_id_from) REFERENCES ref_value_t (value_id) ON DELETE CASCADE,
  FOREIGN KEY (value_id_to) REFERENCES ref_value_t (value_id) ON DELETE CASCADE
);


CREATE TABLE user_t (
    user_id                   VARCHAR(22) NOT NULL,
    email                     VARCHAR(255) NOT NULL,
    password                  VARCHAR(1024) NOT NULL,
    language                  CHAR(2) NOT NULL,
    first_name                VARCHAR(32) NULL,
    last_name                 VARCHAR(32) NULL,
    user_type                 CHAR(1) NULL, -- E employee C customer or E employee P personal B business
    phone_number              VARCHAR(20) NULL,
    gender                    CHAR(1) NULL,
    birthday                  DATE NULL,
    country                   VARCHAR(3) NULL,
    province                  VARCHAR(32) NULL,
    city                      VARCHAR(32) NULL,
    address                   VARCHAR(128) NULL,
    post_code                 VARCHAR(16) NULL,
    verified                  BOOLEAN NOT NULL DEFAULT false,
    token                     VARCHAR(64) NULL,
    locked                    BOOLEAN NOT NULL DEFAULT false,
    nonce                     BIGINT NOT NULL DEFAULT 0,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE user_t ADD CONSTRAINT user_pk PRIMARY KEY ( user_id );

ALTER TABLE user_t ADD CONSTRAINT user_email_uk UNIQUE ( email );

CREATE TABLE user_host_t (
    host_id                   VARCHAR(22) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL,
    -- other relationship-specific attributes (e.g., roles within the host)
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, user_id),
    FOREIGN KEY (user_id) REFERENCES user_t (user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id) REFERENCES host_t (host_id) ON DELETE CASCADE
);

CREATE TABLE user_crypto_wallet_t (
    user_id                   VARCHAR(22) NOT NULL,
    crypto_type               VARCHAR(32) NOT NULL,
    crypto_address            VARCHAR(128) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, crypto_type, crypto_address),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE
);

CREATE TABLE customer_t (
    host_id                   VARCHAR(24) NOT NULL,
    customer_id               VARCHAR(50) NOT NULL,
    user_id                   VARCHAR(24) NOT NULL,
    -- Other customer-specific attributes
    referral_id               VARCHAR(22), -- the customer_id who refers this customer.
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, customer_id),
    -- make sure that the user_host_t host_id update is cascaded
    FOREIGN KEY (host_id, user_id) REFERENCES user_host_t(host_id, user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (host_id, referral_id) REFERENCES customer_t(host_id, customer_id) ON DELETE CASCADE
);

CREATE TABLE employee_t (
    host_id                   VARCHAR(22) NOT NULL,
    employee_id               VARCHAR(50) NOT NULL,  -- Employee ID or number or ACF2 ID. Unique within the host.
    user_id                   VARCHAR(22) NOT NULL,
    title                     VARCHAR(126),
    manager_id                VARCHAR(50), -- manager's employee_id if there is one.
    hire_date                 DATE,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, employee_id),
    -- make sure that the user_host_t host_id update is cascaded
    FOREIGN KEY (host_id, user_id) REFERENCES user_host_t(host_id, user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (host_id, manager_id) REFERENCES employee_t(host_id, employee_id) ON DELETE CASCADE
);

CREATE TABLE position_t (
    host_id                   VARCHAR(22) NOT NULL,
    position_id               VARCHAR(128) NOT NULL,
    position_desc             VARCHAR(2048),
    inherit_to_ancestor       CHAR(1) DEFAULT 'N',
    inherit_to_sibling        CHAR(1) DEFAULT 'N',
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, position_id)
);

CREATE TABLE employee_position_t (
    host_id                   VARCHAR(22) NOT NULL,
    employee_id               VARCHAR(50) NOT NULL,
    position_id               VARCHAR(128) NOT NULL,
    position_type             CHAR(1) NOT NULL, -- P position of own, D inherited from a decendant, S inherited from a sibling.
    start_ts                  TIMESTAMP WITH TIME ZONE,
    end_ts                    TIMESTAMP WITH TIME ZONE,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, employee_id, position_id),
    FOREIGN KEY (host_id, position_id) REFERENCES position_t(host_id, position_id) ON DELETE CASCADE
);

CREATE TABLE position_permission_t (
    host_id                   VARCHAR(22) NOT NULL,
    position_id               VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, position_id, api_id, api_version, endpoint),
    FOREIGN KEY (host_id, position_id) REFERENCES position_t(host_id, position_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);

CREATE TABLE position_row_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    position_id               VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    col_name                  VARCHAR(128) NOT NULL,
    operator                  VARCHAR(32) NOT NULL,
    col_value                 VARCHAR(1024) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, position_id, api_id, api_version, endpoint, col_name),
    FOREIGN KEY (host_id, position_id) REFERENCES position_t(host_id, position_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);

CREATE TABLE position_col_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    position_id               VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    columns                   VARCHAR(1024) NOT NULL, -- list of columns to keep for the position in json string array format.
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, position_id, api_id, api_version, endpoint),
    FOREIGN KEY (host_id, position_id) REFERENCES position_t(host_id, position_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);

CREATE TABLE role_t (
    host_id                   VARCHAR(22) NOT NULL,
    role_id                   VARCHAR(128) NOT NULL,
    role_desc                 VARCHAR(1024),
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id),
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);

CREATE TABLE role_permission_t (
    host_id                   VARCHAR(22) NOT NULL,
    role_id                   VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id, api_id, api_version, endpoint),
    FOREIGN KEY (host_id, role_id) REFERENCES role_t(host_id, role_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);

CREATE TABLE role_row_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    role_id                   VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    col_name                  VARCHAR(128) NOT NULL,
    operator                  VARCHAR(32) NOT NULL,
    col_value                 VARCHAR(1024) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id, api_id, api_version, endpoint, col_name),
    FOREIGN KEY (host_id, role_id) REFERENCES role_t(host_id, role_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);

CREATE TABLE role_col_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    role_id                   VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    columns                   VARCHAR(1024) NOT NULL, -- list of columns to keep for the role in json string array format.
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id, api_id, api_version, endpoint),
    FOREIGN KEY (host_id, role_id) REFERENCES role_t(host_id, role_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);


CREATE TABLE role_user_t (
    host_id                   VARCHAR(22) NOT NULL,
    role_id                   VARCHAR(128) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL,
    start_ts                  TIMESTAMP WITH TIME ZONE,
    end_ts                    TIMESTAMP WITH TIME ZONE,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, role_id, user_id),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, role_id) REFERENCES role_t(host_id, role_id) ON DELETE CASCADE
);

CREATE TABLE user_permission_t (
    host_id                   VARCHAR(22) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    start_ts                  TIMESTAMP WITH TIME ZONE,
    end_ts                    TIMESTAMP WITH TIME ZONE,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, host_id, api_id, api_version, endpoint),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);


CREATE TABLE user_row_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    col_name                  VARCHAR(128) NOT NULL,
    operator                  VARCHAR(32) NOT NULL,
    col_value                 VARCHAR(1024) NOT NULL,
    start_ts                  TIMESTAMP WITH TIME ZONE,
    end_ts                    TIMESTAMP WITH TIME ZONE,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, host_id, api_id, api_version, endpoint, col_name),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);

CREATE TABLE user_col_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    columns                   VARCHAR(1024) NOT NULL, -- list of columns to keep for the user in json string array format.
    start_ts                  TIMESTAMP WITH TIME ZONE,
    end_ts                    TIMESTAMP WITH TIME ZONE,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, host_id, api_id, api_version, endpoint),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);


CREATE TABLE group_t (
    host_id                   VARCHAR(22) NOT NULL,
    group_id                  VARCHAR(128) NOT NULL,
    group_desc                VARCHAR(2048),
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id)
);

CREATE TABLE group_permission_t (
    host_id                   VARCHAR(22) NOT NULL,
    group_id                  VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id, api_id, api_version, endpoint),
    FOREIGN KEY (host_id, group_id) REFERENCES group_t(host_id, group_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);

CREATE TABLE group_row_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    group_id                  VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    col_name                  VARCHAR(128) NOT NULL,
    operator                  VARCHAR(32) NOT NULL,
    col_value                 VARCHAR(1024) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id, api_id, api_version, endpoint, col_name),
    FOREIGN KEY (host_id, group_id) REFERENCES group_t(host_id, group_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);

CREATE TABLE group_col_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    group_id                  VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    columns                   VARCHAR(1024) NOT NULL, -- list of columns to keep for the group in json string array format.
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id, api_id, api_version, endpoint),
    FOREIGN KEY (host_id, group_id) REFERENCES group_t(host_id, group_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE
);


CREATE TABLE group_user_t (
    host_id                   VARCHAR(22) NOT NULL,
    group_id                  VARCHAR(128) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL,
    start_ts                  TIMESTAMP WITH TIME ZONE,
    end_ts                    TIMESTAMP WITH TIME ZONE,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, group_id, user_id),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, group_id) REFERENCES group_t(host_id, group_id) ON DELETE CASCADE
);

-- attribute
CREATE TABLE attribute_t (
    host_id                   VARCHAR(22) NOT NULL,
    attribute_id              VARCHAR(128) NOT NULL,
    attribute_type            VARCHAR(50) CHECK (attribute_type IN ('string', 'integer', 'boolean', 'date', 'float', 'list')), -- Define allowed data types
    attribute_desc            VARCHAR(2048),
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id)
);

CREATE TABLE attribute_user_t (
    host_id                   VARCHAR(22) NOT NULL,
    attribute_id              VARCHAR(128) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL, -- References users_t
    attribute_value           VARCHAR(1024) NOT NULL, -- Store values as strings; you can cast later
    start_ts                  TIMESTAMP WITH TIME ZONE,
    end_ts                    TIMESTAMP WITH TIME ZONE,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id, user_id),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id, attribute_id) REFERENCES attribute_t(host_id, attribute_id) ON DELETE CASCADE
);


CREATE TABLE attribute_permission_t (
    host_id                   VARCHAR(22) NOT NULL,
    attribute_id              VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    attribute_value           VARCHAR(1024) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id, api_id, api_version, endpoint),
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE,
    FOREIGN KEY (host_id, attribute_id) REFERENCES attribute_t(host_id, attribute_id) ON DELETE CASCADE
);

CREATE TABLE attribute_row_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    attribute_id              VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    attribute_value           VARCHAR(1024) NOT NULL,
    col_name                  VARCHAR(128) NOT NULL,
    operator                  VARCHAR(32) NOT NULL,
    col_value                 VARCHAR(1024) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id, api_id, api_version, endpoint, col_name),
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE,
    FOREIGN KEY (host_id, attribute_id) REFERENCES attribute_t(host_id, attribute_id) ON DELETE CASCADE
);

CREATE TABLE attribute_col_filter_t (
    host_id                   VARCHAR(22) NOT NULL,
    attribute_id              VARCHAR(128) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    api_version               VARCHAR(16) NOT NULL,
    endpoint                  VARCHAR(128) NOT NULL,
    attribute_value           VARCHAR(1024) NOT NULL,
    columns                   VARCHAR(1024) NOT NULL, -- list of columns to keep for the attribute in json string array format.
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, attribute_id, api_id, api_version, endpoint),
    FOREIGN KEY (host_id, api_id, api_version, endpoint) REFERENCES api_endpoint_t(host_id, api_id, api_version, endpoint) ON DELETE CASCADE,
    FOREIGN KEY (host_id, attribute_id) REFERENCES attribute_t(host_id, attribute_id) ON DELETE CASCADE
);


CREATE TABLE auth_provider_t (
    provider_id               VARCHAR(22) NOT NULL,
    host_id                   VARCHAR(22) NOT NULL,  -- host that the provider belong to.
    provider_name             VARCHAR(126) NOT NULL,
    provider_desc             VARCHAR(4096),
    operation_owner           VARCHAR(22),
    delivery_owner            VARCHAR(22),
    jwk                       VARCHAR(65535) NOT NULL, -- json web key that contains current and previous public keys
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (provider_id),
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);


CREATE TABLE auth_provider_key_t (
    provider_id               VARCHAR(22) NOT NULL,
    kid                       VARCHAR(22) NOT NULL,
    public_key                VARCHAR(65535) NOT NULL,
    private_key               VARCHAR(65535) NOT NULL,
    key_type                  CHAR(2) NOT NULL, -- LC long live current LP long live previous TC token current, TP token previous
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(provider_id, kid),
    FOREIGN KEY(provider_id) REFERENCES auth_provider_t (provider_id) ON DELETE CASCADE
);

-- multiple apis can share the same auth provider. 
CREATE TABLE auth_provider_api_t(
    host_id                   VARCHAR(22) NOT NULL,
    api_id                    VARCHAR(22) NOT NULL,
    provider_id               VARCHAR(22) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, api_id, provider_id),
    FOREIGN KEY(provider_id) REFERENCES auth_provider_t (provider_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, api_id) REFERENCES api_t(host_id, api_id) ON DELETE CASCADE
);


-- a client can associate with an api or app.
CREATE TABLE auth_client_t (
    host_id                 VARCHAR(22) NOT NULL,
    client_id               VARCHAR(36) NOT NULL,
    client_name             VARCHAR(126) NOT NULL,
    app_id                  VARCHAR(22), -- this client is owned by an app
    api_id                  VARCHAR(22), -- this client is owned by an api
    client_type             VARCHAR(12) NOT NULL, -- public, confidential, trusted, external
    client_profile          VARCHAR(10) NOT NULL, -- webserver, mobile, browser, service, batch
    client_secret           VARCHAR(1024) NOT NULL,
    client_scope            VARCHAR(4000),
    custom_claim            VARCHAR(4000), -- custom claim in json format that will be included in the jwt token
    redirect_uri            VARCHAR(1024),
    authenticate_class      VARCHAR(256),
    deref_client_id         VARCHAR(36), -- only this client calls AS to deref token to JWT for external client type
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, client_id)
);


CREATE TABLE auth_provider_client_t (
    host_id                   VARCHAR(22) NOT NULL,
    client_id                 VARCHAR(36) NOT NULL,
    provider_id               VARCHAR(22) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, client_id, provider_id),
    FOREIGN KEY(provider_id) REFERENCES auth_provider_t (provider_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, client_id) REFERENCES auth_client_t(host_id, client_id) ON DELETE CASCADE
);

CREATE TABLE auth_code_t (
    auth_code                 VARCHAR(22) NOT NULL,
    host_id                   VARCHAR(22) NOT NULL,
    provider_id               VARCHAR(22) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL,
    entity_id                 VARCHAR(50) NOT NULL,
    user_type                 CHAR(1) NOT NULL,
    email                     VARCHAR(126) NOT NULL,
    roles                     VARCHAR(4096),
    groups                    VARCHAR(4096),
    positions                 VARCHAR(4096),
    attributes                VARCHAR(4096),
    redirect_uri              VARCHAR(2048),
    scope                     VARCHAR(1024),
    remember                  CHAR(1),
    code_challenge            VARCHAR(126),
    challenge_method          VARCHAR(64),
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (auth_code),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (provider_id) REFERENCES auth_provider_t(provider_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);

CREATE TABLE auth_refresh_token_t (
    refresh_token             VARCHAR(36) NOT NULL,
    host_id                   VARCHAR(22) NOT NULL,
    provider_id               VARCHAR(22) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL,
    entity_id                 VARCHAR(50) NOT NULL,
    user_type                 CHAR(1) NOT NULL,
    email                     VARCHAR(126) NOT NULL,    
    roles                     VARCHAR(4096),
    groups                    VARCHAR(4096),
    positions                 VARCHAR(4096),
    attributes                VARCHAR(4096),
    client_id                 VARCHAR(36) NOT NULL,
    scope                     VARCHAR(1024),
    csrf                      VARCHAR(36),
    custom_claim              VARCHAR(2000),
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (refresh_token),
    FOREIGN KEY (user_id) REFERENCES user_t(user_id) ON DELETE CASCADE,
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);

CREATE TABLE auth_ref_token_t (
    host_id                   VARCHAR(22) NOT NULL,
    ref_token                 VARCHAR(40) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (ref_token),
    FOREIGN KEY (host_id) REFERENCES host_t(host_id) ON DELETE CASCADE
);

CREATE TABLE notification_t (
    id                        VARCHAR(22) NOT NULL,
    host_id                   VARCHAR(22) NOT NULL,
    user_id                   VARCHAR(22) NOT NULL,
    nonce                     INTEGER NOT NULL,
    event_class               VARCHAR(255) NOT NULL,
    event_json                TEXT NOT NULL,
    process_ts                TIMESTAMP NOT NULL,
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
    send_time  TIMESTAMP NOT NULL
);

ALTER TABLE message_t ADD CONSTRAINT message_pk PRIMARY KEY ( from_id, nonce );

CREATE INDEX message_idx ON message_t (to_email, send_time);


CREATE TABLE worklist_t (
  assignee_id           VARCHAR(126) NOT NULL,
  category_id           VARCHAR(126) DEFAULT '(all)' NOT NULL,
  status_code           VARCHAR(10) DEFAULT 'Active' NOT NULL,
  app_id                VARCHAR(126) DEFAULT 'global' NOT NULL,
  update_user           VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
  update_ts             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
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
  process_id                 VARCHAR(22)        NOT NULL, -- generated uuid
  wf_instance_id             VARCHAR(126)       NOT NULL, -- workflow intance id
  app_id                     VARCHAR(22)       NOT NULL, -- application id
  process_type               VARCHAR(126)      NOT NULL,
  status_code                CHAR(1)            NOT NULL, -- process status code 'A', 'C'
  started_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  ex_trigger_ts              TIMESTAMP          NOT NULL,
  custom_status_code         VARCHAR(126),
  completed_ts               TIMESTAMP,
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
  event_start_ts             TIMESTAMP,
  event_end_ts               TIMESTAMP,
  event_other_ts             TIMESTAMP,
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
  deadline_ts                TIMESTAMP,
  parent_group_id            NUMERIC,
  process_subtype_code       VARCHAR(126),
  owning_group_name          VARCHAR(126), -- Name of the group that owns the process
  PRIMARY KEY(process_id)
);

CREATE TABLE task_info_t
(
    task_id             VARCHAR(22)  NOT NULL,
    task_type           VARCHAR(126) NOT NULL,
    process_id          VARCHAR(22)  NOT NULL,
    wf_instance_id      VARCHAR(126) NOT NULL,
    wf_task_id          VARCHAR(126) NOT NULL,
    status_code         CHAR(1)       NOT NULL, -- U, A, C 
    started_ts          TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    locked              CHAR(1)       NOT NULL,
    priority            INTEGER        NOT NULL,
    completed_ts        TIMESTAMP      NULL,
    completed_user      VARCHAR(126)     NULL,
    result_code         VARCHAR(126)     NULL,
    locking_user        VARCHAR(126)     NULL,
    locking_role        VARCHAR(126)     NULL,
    deadline_ts         TIMESTAMP      NULL,
    lock_group          VARCHAR(126)     NULL,
    PRIMARY KEY(task_id),
    FOREIGN KEY (process_id) REFERENCES process_info_t(process_id) ON DELETE CASCADE
);

CREATE TABLE task_asst_t 
(
    task_asst_id         VARCHAR(22)   NOT NULL,
    task_id              VARCHAR(22)   NOT NULL,
    assigned_ts          TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    assignee_id          VARCHAR(126) NOT NULL,
    reason_code          VARCHAR(126) NOT NULL,
    ACTIVE               CHAR(1)      DEFAULT 'Y' NOT NULL,
    unassigned_ts        TIMESTAMP      NULL,
    unassigned_reason    VARCHAR(126)     NULL,
    category_code        VARCHAR(126)     NULL,
    PRIMARY KEY(task_asst_id),
    FOREIGN KEY(task_id) REFERENCES task_info_t(task_id) ON DELETE CASCADE
);

CREATE TABLE audit_log_t 
(
    audit_log_id         VARCHAR(22)       NOT NULL,
    source_type_id       VARCHAR(126)      NULL,
    correlation_id       VARCHAR(126)      NULL,
    user_id              VARCHAR(126)     NULL,
    event_ts             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
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

ALTER TABLE rule_group_host_t
    ADD CONSTRAINT rule_group_fk FOREIGN KEY ( group_id, rule_id )
        REFERENCES rule_group_t ( group_id, rule_id )
            ON DELETE CASCADE;


ALTER TABLE rule_group_host_t
    ADD CONSTRAINT host_id_fk FOREIGN KEY ( host_id )
        REFERENCES host_t ( host_id )
            ON DELETE CASCADE;

ALTER TABLE product_version_t
    ADD CONSTRAINT host_id_fk FOREIGN KEY (host_id)
        REFERENCES host_t (host_id)
            ON DELETE CASCADE;

ALTER TABLE rule_host_t
    ADD CONSTRAINT rule_id_fk FOREIGN KEY ( rule_id )
        REFERENCES rule_t ( rule_id )
            ON DELETE CASCADE;

ALTER TABLE rule_host_t
    ADD CONSTRAINT host_id_fk FOREIGN KEY ( host_id )
        REFERENCES host_t ( host_id )
            ON DELETE CASCADE;


ALTER TABLE api_endpoint_scope_t
    ADD CONSTRAINT api_ver_fk FOREIGN KEY (host_id, api_id, api_version )
        REFERENCES api_version_t (host_id, api_id, api_version )
            ON DELETE CASCADE;

ALTER TABLE api_endpoint_rule_t
    ADD CONSTRAINT api_fkr FOREIGN KEY (host_id, api_id, api_version, endpoint )
        REFERENCES api_endpoint_t (host_id, api_id, api_version, endpoint )
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
    ADD CONSTRAINT api_scope_fk FOREIGN KEY (host_id, api_id, api_version, endpoint, scope )
        REFERENCES api_endpoint_scope_t (host_id, api_id, api_version, endpoint, scope )
            ON DELETE CASCADE;

ALTER TABLE api_endpoint_rule_t
    ADD CONSTRAINT api_fk FOREIGN KEY (host_id, api_id, api_version, endpoint )
        REFERENCES api_endpoint_t (host_id, api_id, api_version, endpoint )
            ON DELETE CASCADE;

ALTER TABLE api_endpoint_t
    ADD CONSTRAINT api_version_fk FOREIGN KEY (host_id, api_id, api_version )
        REFERENCES api_version_t ( host_id, api_id, api_version )
            ON DELETE CASCADE;

ALTER TABLE instance_api_t
    ADD CONSTRAINT api_version_fkv1 FOREIGN KEY (host_id, api_id, api_version )
        REFERENCES api_version_t ( host_id, api_id, api_version )
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
    ADD CONSTRAINT config_property_fk FOREIGN KEY ( config_id, property_name )
        REFERENCES config_property_t ( config_id, property_name )
            ON DELETE CASCADE;

ALTER TABLE instance_property_t
    ADD CONSTRAINT config_property_fkv1 FOREIGN KEY ( config_id, property_name)
        REFERENCES config_property_t (config_id, property_name)
            ON DELETE CASCADE;

ALTER TABLE product_property_t
    ADD CONSTRAINT config_property_fkv2 FOREIGN KEY ( config_id, property_name)
        REFERENCES config_property_t ( config_id, property_name)
            ON DELETE CASCADE;

ALTER TABLE product_version_property_t
    ADD CONSTRAINT config_property_fkv3 FOREIGN KEY (config_id, property_name)
        REFERENCES config_property_t (config_id, property_name)
            ON DELETE CASCADE;

ALTER TABLE instance_api_property_t
    ADD CONSTRAINT config_property_fkv5 FOREIGN KEY ( config_id, property_name)
        REFERENCES config_property_t (config_id, property_name)
            ON DELETE CASCADE;

ALTER TABLE instance_app_property_t
    ADD CONSTRAINT config_property_fkv6 FOREIGN KEY (config_id, property_name)
        REFERENCES config_property_t (config_id, property_name)
            ON DELETE CASCADE;

ALTER TABLE instance_t
    ADD CONSTRAINT tag_fk FOREIGN KEY ( host_id, tag_id )
        REFERENCES tag_t ( host_id, tag_id )
            ON DELETE CASCADE;


ALTER TABLE instance_app_property_t
    ADD CONSTRAINT instance_app_fk FOREIGN KEY ( host_id, instance_id, app_id, app_version )
        REFERENCES instance_app_t ( host_id, instance_id, app_id, app_version )
            ON DELETE CASCADE;


ALTER TABLE instance_t
    ADD CONSTRAINT product_version_fk FOREIGN KEY (host_id, product_id,
                                                    product_version )
        REFERENCES product_version_t (host_id, product_id,
                                       product_version )
            ON DELETE CASCADE;

ALTER TABLE product_version_property_t
    ADD CONSTRAINT product_version_fkv1 FOREIGN KEY (host_id, product_id,
                                                      product_version )
        REFERENCES product_version_t (host_id, product_id,
                                       product_version )
            ON DELETE CASCADE;




INSERT INTO org_t (domain, org_name, org_desc) VALUES ('lightapi.net', 'Light API Portal', 'Light API Portal');

-- insert the dev.lightapi.net as the default host. 
INSERT INTO host_t (host_id, domain, sub_domain) VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'lightapi.net', 'dev');


INSERT INTO auth_provider_t (host_id, provider_id, provider_name, provider_desc, jwk) VALUES (
'N2CMw0HGQXeLvC1wBfln2A', 'EF3wqhfWQti2DUVrvYNM7g', 'A generic auth provider for lightapi.net dev', 'This is the single provider for the lightapi.net dev environment',
'{"keys":[{"kty":"RSA","kid":"7pGHLozGRXqv2g47T1HQag","n":"h25ydNVptrcDlUiixNtcdsjDUyTT2ZlarxIyRpsOZNWpQ_kXjn723j9YnyePeQkC88K-MPWYhRHKp9w_HwZvWvGgQNk5wlGW3PbOAldbW_5-j5gizPDM8d5mTAThbjsve5wVWwN51utQoqFNdkCQ8sJ5mHbaiSTTUHIDhbKriIlFhsNdLZEHj0yO3awnH8KYxzvbrGzqKse4bDNu7a-dYcjmEbmZ0qGuLYbNeHN4vc-1QukFlnnLD9XNmbh9Gurv52box-Sx2VcU1EY_PaFae2p2BgVBbqLJhcv176vIpKAnIFnyb1aNtP19wOB3JbZDhXhXdG9QhEjUYzLOiV5HnQ","e":"AQAB"},{"kty":"RSA","kid":"Tj_l_tIBTginOtQbL0Pv5w","n":"0YRbWAb1FGDpPUUcrIpJC6BwlswlKMS-z2wMAobdo0BNxNa7hG_gIHVPkXu14Jfo1JhUhS4wES3DdY3a6olqPcRN1TCCUVHd-1TLd1BBS-yq9tdJ6HCewhe5fXonaRRKwutvoH7i_eR4m3fQ1GoVzVAA3IngpTr4ptnM3Ef3fj-5wZYmitzrRUyQtfARTl3qGaXP_g8pHFAP0zrNVvOnV-jcNMKm8YZNcgcs1SuLSFtUDXpf7Nr2_xOhiNM-biES6Dza1sMLrlxULFuctudO9lykB7yFh3LHMxtIZyIUHuy0RbjuOGC5PmDowLttZpPI_j4ynJHAaAWr8Ddz764WdQ","e":"AQAB"}]}'
);

INSERT INTO auth_provider_key_t (provider_id, kid, public_key, private_key, key_type) VALUES (
'EF3wqhfWQti2DUVrvYNM7g',
'7pGHLozGRXqv2g47T1HQag',
'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAh25ydNVptrcDlUiixNtcdsjDUyTT2ZlarxIyRpsOZNWpQ/kXjn723j9YnyePeQkC88K+MPWYhRHKp9w/HwZvWvGgQNk5wlGW3PbOAldbW/5+j5gizPDM8d5mTAThbjsve5wVWwN51utQoqFNdkCQ8sJ5mHbaiSTTUHIDhbKriIlFhsNdLZEHj0yO3awnH8KYxzvbrGzqKse4bDNu7a+dYcjmEbmZ0qGuLYbNeHN4vc+1QukFlnnLD9XNmbh9Gurv52box+Sx2VcU1EY/PaFae2p2BgVBbqLJhcv176vIpKAnIFnyb1aNtP19wOB3JbZDhXhXdG9QhEjUYzLOiV5HnQIDAQAB',
'MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCHbnJ01Wm2twOVSKLE21x2yMNTJNPZmVqvEjJGmw5k1alD+ReOfvbeP1ifJ495CQLzwr4w9ZiFEcqn3D8fBm9a8aBA2TnCUZbc9s4CV1tb/n6PmCLM8Mzx3mZMBOFuOy97nBVbA3nW61CioU12QJDywnmYdtqJJNNQcgOFsquIiUWGw10tkQePTI7drCcfwpjHO9usbOoqx7hsM27tr51hyOYRuZnSoa4ths14c3i9z7VC6QWWecsP1c2ZuH0a6u/nZujH5LHZVxTURj89oVp7anYGBUFuosmFy/Xvq8ikoCcgWfJvVo20/X3A4HcltkOFeFd0b1CESNRjMs6JXkedAgMBAAECggEAMcLTKzp+7TOxjVhy9gHjp4F8wz/01y8RsuHstySh1UrsNp1/mkvsSRzdYx0WClLVUttrJnIW6E3xOFwklTG4GKJPT4SBRHTWCbplV1bhqpuHxRsRLlwL8ZLV43inm+kDOVfQQPC2A9HSfu7ll12B5LCwHOUOxvVQ7230/Vr4y+GacYHDO0aL7tWAC2fH8hXzvgSc+sosg/gIRro7aasP5GMuFZjtPANzwhovE8vq71ZQTCzEEm890NuzOOYLUCmkE+FDL6Fjg9lckcosmfPuBpqMjAMMAhIHLEwmWBX6najTcuxpzDT6H+4cmU8+TyX2OwBlyAWpFNTLp3ta05tAAQKBgQDRgSxGB83hx5IL1u1gvDsEfS2sKgRDE5ZEeNDOrxI+U6dhgKj7ae11as83AZnA+sAQrHPZowoRAnAlqNFTQKMLxQfocs2sl5pG5xkL7DrlteUtG6gDvjsbtL64wiy6WrfTJvcICiAw9skgSFX+ZTy9GhcvQVrrjrHrjMl2b+uHAQKBgQClfN7SdW9hxKbKzHzpJ4G74Vr0JqYmr2JPu5DezL/Mxnx+sKEA2ByqVAEO6pJKGR5GfwPh91BBc1sRA4PzWtLRR5Dve6dm1puhaXKeREwBgIoDnXvGDfsOnwHQcGJzSgqBmycTTDiBmjnYX8AkZkbHN5lIFriy7G063XsuGIh8nQKBgDpEVb7oXr9DlP/L99smnrdh5Tjzupm5Mdq7Sz+ge09wTqYUdWrvDAbS/OyMemmsk4xPmizWZm9SoUQoDoe7+1zDoK5qd39f7p13moSxX7QRgbqo7XKVDrVm8IBMKMpvfp6wQJYw0sErccaTt674Ewt43SfcYmAPILalQka5W+UBAoGAQpom83zf/vEuT6BNBWkpBXyFJo4HgLpFTuGmRIUTDE81+6cKpVRU9Rgp9N7jUX8aeDTWUzM90ZmjpQ1NJbv/7Mpownl5viHRMP1Ha/sAu/oHkbzn+6XUzOWhzUnt1YiPAep3p4SdmUuAzFx88ClZgwQVZLYAT8Jnk7FfygWFqOECgYBOox0DFatEqB/7MNMoLMZCacSrylZ1NYHJYAdWkxOvahrppAMbDVFDlwvH7i8gVvzcfFxQtOxSJBlUKlamDd5i76O2N+fIPO8P+iyqKz2Uh/emVwWCWlijSOnXvKRUOiujVufGP0OGxi1GKSUaIXnvMQqYF9M/Igi0BQiCn+pFzw==',
'LC'
);


INSERT INTO auth_provider_key_t (provider_id, kid, public_key, private_key, key_type) VALUES
(
'EF3wqhfWQti2DUVrvYNM7g',
'Tj_l_tIBTginOtQbL0Pv5w',
'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0YRbWAb1FGDpPUUcrIpJC6BwlswlKMS+z2wMAobdo0BNxNa7hG/gIHVPkXu14Jfo1JhUhS4wES3DdY3a6olqPcRN1TCCUVHd+1TLd1BBS+yq9tdJ6HCewhe5fXonaRRKwutvoH7i/eR4m3fQ1GoVzVAA3IngpTr4ptnM3Ef3fj+5wZYmitzrRUyQtfARTl3qGaXP/g8pHFAP0zrNVvOnV+jcNMKm8YZNcgcs1SuLSFtUDXpf7Nr2/xOhiNM+biES6Dza1sMLrlxULFuctudO9lykB7yFh3LHMxtIZyIUHuy0RbjuOGC5PmDowLttZpPI/j4ynJHAaAWr8Ddz764WdQIDAQAB',
'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDRhFtYBvUUYOk9RRysikkLoHCWzCUoxL7PbAwCht2jQE3E1ruEb+AgdU+Re7Xgl+jUmFSFLjARLcN1jdrqiWo9xE3VMIJRUd37VMt3UEFL7Kr210nocJ7CF7l9eidpFErC62+gfuL95Hibd9DUahXNUADcieClOvim2czcR/d+P7nBliaK3OtFTJC18BFOXeoZpc/+DykcUA/TOs1W86dX6Nw0wqbxhk1yByzVK4tIW1QNel/s2vb/E6GI0z5uIRLoPNrWwwuuXFQsW5y25072XKQHvIWHcsczG0hnIhQe7LRFuO44YLk+YOjAu21mk8j+PjKckcBoBavwN3PvrhZ1AgMBAAECggEBAMuDYGLqJydLV2PPfSHQFVH430RrOfEW4y2CC0xtCl8n+CKqXm0vaqq8qLRtUWa+yEexS/AtxDz7ke/fAfVt00f6JYxe2Ub6WcBnRlg4GaURV6P7zWu98UghWWkbvaphLpmVrdFdT0pFoi2JvcyG23SaMKwINbDpzlvsFgUm1q3GoCIZXRc8iAKT+Iil1QmGdacGni/D2WzPTLSf1/acZU2TsPBWLS/jsjPe4ac4IDpxssDC+w6QArZ8U64DKJ531C4tK9o+RArQzBrEaZc1mAlw7xAPr36tXvOTUycux6k07ERSIIze2okVmmewL6tX1cb7tY1F8T+ebKGD3xGEAYUCgYEA9Lpy4593uTBww7AupcZq2YL8qHUfnvxIWiFbeIznUezyYyRbjyLDYj+g7QfQJHk579UckDZZDcT3H+wdh1LxQ7HKDlYQn2zt8Kdufs5cvSObeGkSqSY26g4QDRcRcRO3xFs8bQ/CnPNT7hsWSY+8wnuRvjUTstMA1vx1+/HHZfMCgYEA2yq8yFogdd2/wUcFlqjPgbJ98X9ZNbZ06uUCur4egseVlSVE+R2pigVVwFCDQpseGu2GVgW5q8kgDGsaJuEVWIhGZvS9IHONBz/WB0PmOZjXlXOhmT6iT6m/9bAQk8MtOee77lUVvgf7FO8XDKtuPh6VGJpr+YJHxHoEX/dbo/cCgYAjwy9Q1hffxxVjc1aNwR4SJRMY5uy1BfbovOEqD6UqEq8lD8YVd6YHsHaqzK589f4ibwkaheajnXnjf1SdVuCM3OlDCQ6qzXdD6KO8AhoJRa/Ne8VPVJdHwsBTuWBCHviGyDJfWaM93k0QiYLLQyb5YKdenVEAm9cOk5wGMkHKQwKBgH050CASDxYJm/UNZY4N6nLKz9da0lg0Zl2IeKTG2JwU+cz8PIqyfhqUrchyuG0oQG1WZjlkkBAtnRg7YffxB8dMJh3RnPabz2ri+KGyFCu4vwVvylfLR+aIsVvqO66SCJdbZy/ogcHQwY/WhK8CjL0FsF8cbLFl1SfYKAPFTCFFAoGANmOKonyafvWqsSkcl6vUTYYq53IN+qt0IJTDB2cEIEqLXtNth48HvdQkxDF3y4cNLZevhyuIy0Z3yWGbZM2yWbDNn8Q2W5RTyajofQu1mIv2EBzLeOoaSBPLX4G6r4cODSwWbjOdaNxcXd0+uYeAWDuQUSnHpHFJ2r1cpL/9Nbs=',
'TC'
);


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('z-Xv-uQfTXu_KRf7uP_n1g', 'user_type', 'User Type', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('iK1f9oYIT8m2Ew4m_W7z8w', 'z-Xv-uQfTXu_KRf7uP_n1g', 'E', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('tQ8tT1fWS0-j6x0kR-91BA', 'z-Xv-uQfTXu_KRf7uP_n1g', 'C', 200, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('iK1f9oYIT8m2Ew4m_W7z8w', 'en', 'Employee');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('tQ8tT1fWS0-j6x0kR-91BA', 'en', 'Customer');
INSERT INTO ref_host_t(table_id, host_id) values ('z-Xv-uQfTXu_KRf7uP_n1g', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('dFGZj8DKQr6Ll6q4H-mB3w', 'language', 'Language', 'N');
-- Add language values
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('VQzuTjCpTI-elK-DlpaB3Q', 'dFGZj8DKQr6Ll6q4H-mB3w', 'en', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('um3QAmbcTRqLw68ua2Iwug', 'dFGZj8DKQr6Ll6q4H-mB3w', 'fr', 101, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('zh', 'language', 'zh', 102, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('es', 'language', 'es', 103, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ja', 'language', 'ja', 104, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ko', 'language', 'ko', 105, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('pt', 'language', 'pt', 106, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ru', 'language', 'ru', 107, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('VQzuTjCpTI-elK-DlpaB3Q', 'en', 'English');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('um3QAmbcTRqLw68ua2Iwug', 'en', 'French');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('zh', 'en', 'Chinese');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('es', 'en', 'Spanish');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ja', 'en', 'Japanese');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ko', 'en', 'Korean');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('pt', 'en', 'Portuguese');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ru', 'en', 'Russian');
INSERT INTO ref_host_t(table_id, host_id) values ('dFGZj8DKQr6Ll6q4H-mB3w', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('xMdMXLh8TgmjLScSH49q_Q', 'environment', 'Environment', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('UcPJHc_VT-a90F-rQZd9Yg', 'xMdMXLh8TgmjLScSH49q_Q', 'DEV', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('TK_KMCsjT_2frEnVHgpoYw', 'xMdMXLh8TgmjLScSH49q_Q', 'SIT', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('8tgHiB3TRW6VhRnmT4x7Tw', 'xMdMXLh8TgmjLScSH49q_Q', 'UAT', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Bx0GoUhvTgSaoJfQn95vhw', 'xMdMXLh8TgmjLScSH49q_Q', 'STG', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('oqbeOE0SSjClTN3P6mP_MA', 'xMdMXLh8TgmjLScSH49q_Q', 'RPD', 500, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('UcPJHc_VT-a90F-rQZd9Yg', 'en', 'DEV');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('TK_KMCsjT_2frEnVHgpoYw', 'en', 'SIT');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('8tgHiB3TRW6VhRnmT4x7Tw', 'en', 'UAT');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Bx0GoUhvTgSaoJfQn95vhw', 'en', 'STAGING');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('oqbeOE0SSjClTN3P6mP_MA', 'en', 'PRODUCTION');
INSERT INTO ref_host_t(table_id, host_id) values ('xMdMXLh8TgmjLScSH49q_Q', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('FuPRs3DUStaROblPpO5XRw', 'light4j_version', 'Light-4j Version', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ugGbnVDGQG27kDogOoieiw', 'FuPRs3DUStaROblPpO5XRw', '2.1.37', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('WwsR5Ki1R4OaampHzqWgvw', 'FuPRs3DUStaROblPpO5XRw', '2.1.38', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('H4DcO139SaWsK1ZqrqJUQg', 'FuPRs3DUStaROblPpO5XRw', '2.2.0', 300, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ugGbnVDGQG27kDogOoieiw', 'en', '2.1.37');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('WwsR5Ki1R4OaampHzqWgvw', 'en', '2.1.38');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('H4DcO139SaWsK1ZqrqJUQg', 'en', '2.2.0');
INSERT INTO ref_host_t(table_id, host_id) values ('FuPRs3DUStaROblPpO5XRw', 'N2CMw0HGQXeLvC1wBfln2A');



INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('Erd8-pD3TBG7-vwPtgsWFg', 'platform_product', 'Platform Product', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Pbwy3xh2Sz2WfAbW9JcJ8Q', 'Erd8-pD3TBG7-vwPtgsWFg', 'lg', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('XB4iKkb4QUqwgAZsDh83DA', 'Erd8-pD3TBG7-vwPtgsWFg', 'lps', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('UicQpEFZQYGk4rc6ky-LMQ', 'Erd8-pD3TBG7-vwPtgsWFg', 'lpc', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('EMINj3sSSr6e19_zt14CjA', 'Erd8-pD3TBG7-vwPtgsWFg', 'lp', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('_NR9tmVPQ1OWib2Dz6j3Qw', 'Erd8-pD3TBG7-vwPtgsWFg', 'lpl', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Tld_5HmWQI67jK1MNIO9HA', 'Erd8-pD3TBG7-vwPtgsWFg', 'lks', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('yyLPTpsJTXStY5DSuQTzFg', 'Erd8-pD3TBG7-vwPtgsWFg', 'lb', 700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('CndphT7PSweprG9uHC-kmQ', 'Erd8-pD3TBG7-vwPtgsWFg', 'lnl', 800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('HxEbiZ-ASNOqGjzI1X_3-Q', 'Erd8-pD3TBG7-vwPtgsWFg', 'bff', 900, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Pbwy3xh2Sz2WfAbW9JcJ8Q', 'en', 'Light Gateway');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('XB4iKkb4QUqwgAZsDh83DA', 'en', 'Light Proxy Server');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('UicQpEFZQYGk4rc6ky-LMQ', 'en', 'Light Proxy Client');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('EMINj3sSSr6e19_zt14CjA', 'en', 'Light Proxy Sidecar');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('_NR9tmVPQ1OWib2Dz6j3Qw', 'en', 'Light Proxy Lambda');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Tld_5HmWQI67jK1MNIO9HA', 'en', 'Light Kafka Sidecar');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('yyLPTpsJTXStY5DSuQTzFg', 'en', 'Light Balancer');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('CndphT7PSweprG9uHC-kmQ', 'en', 'Light Native Lambda');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('HxEbiZ-ASNOqGjzI1X_3-Q', 'en', 'Light BFF');
INSERT INTO ref_host_t(table_id, host_id) values ('Erd8-pD3TBG7-vwPtgsWFg', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('2A3um2OJSiK4bZ4h10jOww', 'product_version_status', 'Product Version Status', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('RbkF7LnvStqGqeRHC004GA', '2A3um2OJSiK4bZ4h10jOww', 'Supported', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('SV8tVtegSt6balvd3uolog', '2A3um2OJSiK4bZ4h10jOww', 'Outdated', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('lRtAcENcTLWzLaSaNxuTPA', '2A3um2OJSiK4bZ4h10jOww', 'Deprecated', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('HeT7oBcTSmOXJesV0tQWwA', '2A3um2OJSiK4bZ4h10jOww', 'Removed', 400, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('RbkF7LnvStqGqeRHC004GA', 'en', 'Supported');  -- there might be serveral supported versions
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('SV8tVtegSt6balvd3uolog', 'en', 'Outdated'); -- not supported but still usable, allow to deploy with warnning.
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('lRtAcENcTLWzLaSaNxuTPA', 'en', 'Deprecated'); -- not supported and use at your risk, don't allow to deploy
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('HeT7oBcTSmOXJesV0tQWwA', 'en', 'Removed'); -- borken version, please don't use, soft delete. 
INSERT INTO ref_host_t(table_id, host_id) values ('2A3um2OJSiK4bZ4h10jOww', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('HKyo60IcSF2o1UwwfvNUAw', 'deployment_status', 'Deployment Status', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Bi7sT6SIRGGF_5km4kqRWA', 'HKyo60IcSF2o1UwwfvNUAw', 'Scheduled', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('rRySKKIcTjaBH9w9OYXT0A', 'HKyo60IcSF2o1UwwfvNUAw', 'InProgress', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('bcMA9qwRQcG4l1jXFRtFug', 'HKyo60IcSF2o1UwwfvNUAw', 'Completed', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('6g8nx1uqQ3qZUVlCjADhtw', 'HKyo60IcSF2o1UwwfvNUAw', 'Failed', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('vSd2Mji_SWCKn0cfE9XYKg', 'HKyo60IcSF2o1UwwfvNUAw', 'Timeout', 500, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Bi7sT6SIRGGF_5km4kqRWA', 'en', 'Scheduled');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('rRySKKIcTjaBH9w9OYXT0A', 'en', 'InProgress');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('bcMA9qwRQcG4l1jXFRtFug', 'en', 'Completed');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('6g8nx1uqQ3qZUVlCjADhtw', 'en', 'Failed');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('vSd2Mji_SWCKn0cfE9XYKg', 'en', 'Timeout');
INSERT INTO ref_host_t(table_id, host_id) values ('HKyo60IcSF2o1UwwfvNUAw', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('4ZFXtWBMQwOISJUkXFbOWQ', 'instance_status', 'Instance Status', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('PaAlX0XfQH6FiVaAhgeH5w', '4ZFXtWBMQwOISJUkXFbOWQ', 'Created', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('2NgkC8NLSia_l0pV2mP8Eg', '4ZFXtWBMQwOISJUkXFbOWQ', 'Deploying', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('JX2MfDS9TzOvqDI6GLnTgQ', '4ZFXtWBMQwOISJUkXFbOWQ', 'Deployed', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('oTePZ34bRieBIGtrKKvL8g', '4ZFXtWBMQwOISJUkXFbOWQ', 'Running', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('aaAzQq9WSQey0JF76FhC5w', '4ZFXtWBMQwOISJUkXFbOWQ', 'Shutdown', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('vJEgLQX8RCiaC7nL2bsYbg', '4ZFXtWBMQwOISJUkXFbOWQ', 'Undeployed', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('sCxrboQESyuoS_CWfiSbzw', '4ZFXtWBMQwOISJUkXFbOWQ', 'Decomissioned', 700, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('PaAlX0XfQH6FiVaAhgeH5w', 'en', 'Created');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('2NgkC8NLSia_l0pV2mP8Eg', 'en', 'Deploying');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('JX2MfDS9TzOvqDI6GLnTgQ', 'en', 'Deployed');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('oTePZ34bRieBIGtrKKvL8g', 'en', 'Running');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('aaAzQq9WSQey0JF76FhC5w', 'en', 'Shutdown');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('vJEgLQX8RCiaC7nL2bsYbg', 'en', 'Undeployed');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('sCxrboQESyuoS_CWfiSbzw', 'en', 'Decomissioned');
INSERT INTO ref_host_t(table_id, host_id) values ('4ZFXtWBMQwOISJUkXFbOWQ', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('9IF1kYNDQOanvnNojIBMLA', 'deployment_type', 'Deployment Type', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('HWJoOtkYT_ijL4zSIAEMKg', '9IF1kYNDQOanvnNojIBMLA', 'First', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('msx7fa4SScaV4Gmy9B4XHA', '9IF1kYNDQOanvnNojIBMLA', 'Update', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('no1d49VCQy2Adfs9qKuOfQ', '9IF1kYNDQOanvnNojIBMLA', 'Rollback', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('X0RSjZMYQk2ApWn1dabW0g', '9IF1kYNDQOanvnNojIBMLA', 'Remove', 400, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('HWJoOtkYT_ijL4zSIAEMKg', 'en', 'First');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('msx7fa4SScaV4Gmy9B4XHA', 'en', 'Update');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('no1d49VCQy2Adfs9qKuOfQ', 'en', 'Rollback');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('X0RSjZMYQk2ApWn1dabW0g', 'en', 'Remove');
INSERT INTO ref_host_t(table_id, host_id) values ('9IF1kYNDQOanvnNojIBMLA', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('VNyDLBfkQjGfNHjgh5WPdg', 'deploy_client_type', 'Deploy Client Type', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('BEj4HlHoTAKZd3ATIczrBA', 'VNyDLBfkQjGfNHjgh5WPdg', 'http', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('BkrjzNMQR6CS3FZCMKEy_w', 'VNyDLBfkQjGfNHjgh5WPdg', 'aws', 200, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('BEj4HlHoTAKZd3ATIczrBA', 'en', 'http');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('BkrjzNMQR6CS3FZCMKEy_w', 'en', 'aws');
INSERT INTO ref_host_t(table_id, host_id) values ('VNyDLBfkQjGfNHjgh5WPdg', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('LADMEBrNSMGNVP4ezLdSEQ', 'system_env', 'System Environment', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('CA8bwCiASRWG6gyXeLqxhg', 'LADMEBrNSMGNVP4ezLdSEQ', 'VM Windows 2019', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('X816H3TSQVOk3ub0Pkq6WQ', 'LADMEBrNSMGNVP4ezLdSEQ', 'VM Ubuntu 24.04', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('DjsMrxh3Q869U2udMd7rMQ', 'LADMEBrNSMGNVP4ezLdSEQ', 'VM Ubuntu 22.04', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('h5f8lKfqQv2b_kVyOa25SA', 'LADMEBrNSMGNVP4ezLdSEQ', 'VM Ubuntu 20.04', 400, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('CA8bwCiASRWG6gyXeLqxhg', 'en', 'VM Windows 2019');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('X816H3TSQVOk3ub0Pkq6WQ', 'en', 'VM Ubuntu 24.04');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('DjsMrxh3Q869U2udMd7rMQ', 'en', 'VM Ubuntu 22.04');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('h5f8lKfqQv2b_kVyOa25SA', 'en', 'VM Ubuntu 20.04');
INSERT INTO ref_host_t(table_id, host_id) values ('LADMEBrNSMGNVP4ezLdSEQ', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('EJg629SCT1OQpqZwoTghoA', 'runtime_env', 'Runtime Environment', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Qbt5W3iPQSmDjBbq58BoYg', 'EJg629SCT1OQpqZwoTghoA', 'OpenJDK 11', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('dzLZv25uRrm4Jrilqylaxg', 'EJg629SCT1OQpqZwoTghoA', 'OpenJDK 17', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('cC9KXTcnSqCBibfMxNMU9w', 'EJg629SCT1OQpqZwoTghoA', 'OpenJDK 21', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('9N8smvo4R8qOsvZpbIiobg', 'EJg629SCT1OQpqZwoTghoA', 'GraalVM 17', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('vCnnnYLVQamBfwHCxg9B5A', 'EJg629SCT1OQpqZwoTghoA', 'GraalVM 21', 500, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Qbt5W3iPQSmDjBbq58BoYg', 'en', 'OpenJDK 11');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('dzLZv25uRrm4Jrilqylaxg', 'en', 'OpenJDK 17');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('cC9KXTcnSqCBibfMxNMU9w', 'en', 'OpenJDK 21');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('9N8smvo4R8qOsvZpbIiobg', 'en', 'GraalVM 17');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('vCnnnYLVQamBfwHCxg9B5A', 'en', 'GraalVM 21');
INSERT INTO ref_host_t(table_id, host_id) values ('EJg629SCT1OQpqZwoTghoA', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('LrXDFX8zRCa69fcth_oyZA', 'api_type', 'API Type', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('wXlCi_bnQTi0j2Q0LcIxDA', 'LrXDFX8zRCa69fcth_oyZA', 'openapi', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('sBxy6InFTVO5BeDpvEuBOA', 'LrXDFX8zRCa69fcth_oyZA', 'graphql', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('J40TUdG4Q7WZ4jH44ONjNg', 'LrXDFX8zRCa69fcth_oyZA', 'hybrid', 300, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('wXlCi_bnQTi0j2Q0LcIxDA', 'en', 'OpenAPI');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('sBxy6InFTVO5BeDpvEuBOA', 'en', 'GraphQL');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('J40TUdG4Q7WZ4jH44ONjNg', 'en', 'Hybrid');
INSERT INTO ref_host_t(table_id, host_id) values ('LrXDFX8zRCa69fcth_oyZA', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('xACNHRyOTmuJAjrEaTKUCw', 'api_status', 'API Status', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('qdUehMN8TlCPfPGPTkQyrA', 'xACNHRyOTmuJAjrEaTKUCw', 'onboarded', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('wWsHmB3MTd2M3Cn27fMRGw', 'xACNHRyOTmuJAjrEaTKUCw', 'published', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('NKr6uYb2Tqa2uR2PrStpAw', 'xACNHRyOTmuJAjrEaTKUCw', 'implemented', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('QOvTlKDJQYWXyet8MDy2lQ', 'xACNHRyOTmuJAjrEaTKUCw', 'deployed', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('88MrqFb7TfylpAE0sIDYQQ', 'xACNHRyOTmuJAjrEaTKUCw', 'decommissioned', 500, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('qdUehMN8TlCPfPGPTkQyrA', 'en', 'Onboarded');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('wWsHmB3MTd2M3Cn27fMRGw', 'en', 'Published');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('NKr6uYb2Tqa2uR2PrStpAw', 'en', 'Implemented');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('QOvTlKDJQYWXyet8MDy2lQ', 'en', 'Deployed');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('88MrqFb7TfylpAE0sIDYQQ', 'en', 'Decommissioned');
INSERT INTO ref_host_t(table_id, host_id) values ('xACNHRyOTmuJAjrEaTKUCw', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('Zp1Vd8dpTAK33ZzQyq4CRQ', 'region', 'Region', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('HnYlmIyHTHO3rfZOQRczXw', 'Zp1Vd8dpTAK33ZzQyq4CRQ', 'CA', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('6EDMRBWDT2efA3omlz5Nug', 'Zp1Vd8dpTAK33ZzQyq4CRQ', 'US', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('isf3UhdxSqeoBMI64mdltQ', 'Zp1Vd8dpTAK33ZzQyq4CRQ', 'HK', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('hLo4AAGIQamSSgj7j9x3Cg', 'Zp1Vd8dpTAK33ZzQyq4CRQ', 'ID', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('2iXBeuGpRlGsjhrT6T2G1Q', 'Zp1Vd8dpTAK33ZzQyq4CRQ', 'MY', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('umk9ETMnTaS_yJuELopC1g', 'Zp1Vd8dpTAK33ZzQyq4CRQ', 'PH', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('i8t8BXyDQrWvGp9CdAbNuA', 'Zp1Vd8dpTAK33ZzQyq4CRQ', 'VN', 700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('JiHCHAeoQAuI1SDDO1ZK9Q', 'Zp1Vd8dpTAK33ZzQyq4CRQ', 'EN', 800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('zAOdjCwoSwCwswsEIH7OVw', 'Zp1Vd8dpTAK33ZzQyq4CRQ', 'AS', 900, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('HnYlmIyHTHO3rfZOQRczXw', 'en', 'Canada');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('6EDMRBWDT2efA3omlz5Nug', 'en', 'United States');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('isf3UhdxSqeoBMI64mdltQ', 'en', 'Hong Kong');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('hLo4AAGIQamSSgj7j9x3Cg', 'en', 'Indonesia');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('2iXBeuGpRlGsjhrT6T2G1Q', 'en', 'Malaysia');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('umk9ETMnTaS_yJuELopC1g', 'en', 'Philippines');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('i8t8BXyDQrWvGp9CdAbNuA', 'en', 'Vietnam');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('JiHCHAeoQAuI1SDDO1ZK9Q', 'en', 'Enterprise');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('zAOdjCwoSwCwswsEIH7OVw', 'en', 'Asia');
INSERT INTO ref_host_t(table_id, host_id) values ('Zp1Vd8dpTAK33ZzQyq4CRQ', 'N2CMw0HGQXeLvC1wBfln2A');



INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('TsuustoPSyuHvah1gdImxA', 'business_group', 'Business Group', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('b3Ycy2nIQZiIw7giSukUmw', 'TsuustoPSyuHvah1gdImxA', 'Corp', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('8930ix4WRFC7DFmkxS5AzA', 'TsuustoPSyuHvah1gdImxA', 'CA', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('DviWnbp9QLWJWsP53BnLTQ', 'TsuustoPSyuHvah1gdImxA', 'DBTS', 200, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('b3Ycy2nIQZiIw7giSukUmw', 'en', 'Corporate');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('8930ix4WRFC7DFmkxS5AzA', 'en', 'Canada');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('DviWnbp9QLWJWsP53BnLTQ', 'en', 'Digital Business and Technology Solutions');
INSERT INTO ref_host_t(table_id, host_id) values ('TsuustoPSyuHvah1gdImxA', 'N2CMw0HGQXeLvC1wBfln2A');


-- relationship between region and business_group
INSERT INTO relation_type_t(relation_id, relation_name, relation_desc) VALUES ('FuwDobt6TraMxSIgSmLrqA', 'region-bgrp', 'business group dropdown filtered by region');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('FuwDobt6TraMxSIgSmLrqA', 'HnYlmIyHTHO3rfZOQRczXw', '8930ix4WRFC7DFmkxS5AzA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('FuwDobt6TraMxSIgSmLrqA', 'JiHCHAeoQAuI1SDDO1ZK9Q', 'b3Ycy2nIQZiIw7giSukUmw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('FuwDobt6TraMxSIgSmLrqA', 'JiHCHAeoQAuI1SDDO1ZK9Q', 'DviWnbp9QLWJWsP53BnLTQ');



INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('X7G8q4KyRXeyd4nTUlcM9A', 'lob', 'Line of Business', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Oaf4RXjsRnuDsMwZAVGYXw', 'X7G8q4KyRXeyd4nTUlcM9A', 'Ops', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Xx0aBMEmQMWrpEEHHh4zuA', 'X7G8q4KyRXeyd4nTUlcM9A', 'CXO', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('GPE28Q0WTN69vpOlzHCiRw', 'X7G8q4KyRXeyd4nTUlcM9A', 'GB', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Ll6zys0kRleqJfJbel3qpg', 'X7G8q4KyRXeyd4nTUlcM9A', 'GRS', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('z2kfddsQQdCRrt8AazpjWg', 'X7G8q4KyRXeyd4nTUlcM9A', 'Insurance', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Rb9u3bbvQnaAXZS0G42U5g', 'X7G8q4KyRXeyd4nTUlcM9A', 'Lumino', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('sKLc3RLmQOCCt0Nn7Hr6ew', 'X7G8q4KyRXeyd4nTUlcM9A', 'FD', 700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('VIq9jzscQeCOrCfQkP6HsQ', 'X7G8q4KyRXeyd4nTUlcM9A', 'GI', 800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('3nL26qLwS8qZJB1MxWt_Sw', 'X7G8q4KyRXeyd4nTUlcM9A', 'Tax', 900, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('rRntRNrcRzKz1mBZCsttsw', 'X7G8q4KyRXeyd4nTUlcM9A', 'Risk', 1000, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Ic6EhqUFQoSjIac_Rszpmw', 'X7G8q4KyRXeyd4nTUlcM9A', 'Audit', 1100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('2V27Fd1SQsqRwfUwRGI6Cg', 'X7G8q4KyRXeyd4nTUlcM9A', 'Legal', 1200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Ep32sEmNRimXwYJbbr62Bg', 'X7G8q4KyRXeyd4nTUlcM9A', 'CoreIT', 1300, 'Y');


INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Oaf4RXjsRnuDsMwZAVGYXw', 'en', 'Canadian Operations');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Xx0aBMEmQMWrpEEHHh4zuA', 'en', 'Client Experience Office');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('GPE28Q0WTN69vpOlzHCiRw', 'en', 'Group Benefits');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Ll6zys0kRleqJfJbel3qpg', 'en', 'Group Retirement Services');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('z2kfddsQQdCRrt8AazpjWg', 'en', 'Insurance Solutions');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Rb9u3bbvQnaAXZS0G42U5g', 'en', 'Health Solutions');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('sKLc3RLmQOCCt0Nn7Hr6ew', 'en', 'Financial Distribution');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('VIq9jzscQeCOrCfQkP6HsQ', 'en', 'Global Investments');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('3nL26qLwS8qZJB1MxWt_Sw', 'en', 'Tax');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('rRntRNrcRzKz1mBZCsttsw', 'en', 'Risk');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Ic6EhqUFQoSjIac_Rszpmw', 'en', 'Audit');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('2V27Fd1SQsqRwfUwRGI6Cg', 'en', 'Legal');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Ep32sEmNRimXwYJbbr62Bg', 'en', 'Core IT Platforms');
INSERT INTO ref_host_t(table_id, host_id) values ('X7G8q4KyRXeyd4nTUlcM9A', 'N2CMw0HGQXeLvC1wBfln2A');


-- relationship between business_group and lob
INSERT INTO relation_type_t(relation_id, relation_name, relation_desc) VALUES ('MHIyE2lyR5GfWSO3xYINsA', 'bgrp-lob', 'lob dropdown filtered by buisiness group');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', 'b3Ycy2nIQZiIw7giSukUmw', '3nL26qLwS8qZJB1MxWt_Sw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', 'b3Ycy2nIQZiIw7giSukUmw', 'rRntRNrcRzKz1mBZCsttsw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', 'b3Ycy2nIQZiIw7giSukUmw', 'Ic6EhqUFQoSjIac_Rszpmw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', 'b3Ycy2nIQZiIw7giSukUmw', '2V27Fd1SQsqRwfUwRGI6Cg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', '8930ix4WRFC7DFmkxS5AzA', 'Oaf4RXjsRnuDsMwZAVGYXw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', '8930ix4WRFC7DFmkxS5AzA', 'Xx0aBMEmQMWrpEEHHh4zuA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', '8930ix4WRFC7DFmkxS5AzA', 'GPE28Q0WTN69vpOlzHCiRw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', '8930ix4WRFC7DFmkxS5AzA', 'Ll6zys0kRleqJfJbel3qpg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', '8930ix4WRFC7DFmkxS5AzA', 'z2kfddsQQdCRrt8AazpjWg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', '8930ix4WRFC7DFmkxS5AzA', 'Rb9u3bbvQnaAXZS0G42U5g');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', '8930ix4WRFC7DFmkxS5AzA', 'sKLc3RLmQOCCt0Nn7Hr6ew');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', '8930ix4WRFC7DFmkxS5AzA', 'VIq9jzscQeCOrCfQkP6HsQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('MHIyE2lyR5GfWSO3xYINsA', 'DviWnbp9QLWJWsP53BnLTQ', 'Ep32sEmNRimXwYJbbr62Bg');




INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('0Me3LTosT4aZjjZhY_1IGw', 'platform_journer', 'Platform Journey', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('hWJlP0g6QNyKv6t93V6vEA', '0Me3LTosT4aZjjZhY_1IGw', 'API Platform', 100, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('hWJlP0g6QNyKv6t93V6vEA', 'en', 'API Platform');
INSERT INTO ref_host_t(table_id, host_id) values ('0Me3LTosT4aZjjZhY_1IGw', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO relation_type_t(relation_id, relation_name, relation_desc) VALUES ('8pJZIyKTRiC5Ez90VRQDXA', 'lob-platform', 'platform dropdown filtered by lob');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('8pJZIyKTRiC5Ez90VRQDXA', 'Ep32sEmNRimXwYJbbr62Bg', 'hWJlP0g6QNyKv6t93V6vEA');



INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('7tXfGxC5Q2CgwA41B1u9Mw', 'capability', 'Capability', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('0soMPJ72QvGlHAvWDj5IyQ', '7tXfGxC5Q2CgwA41B1u9Mw', 'Awareness', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('cJzekpbUS0GPnVHQ1eQEKQ', '7tXfGxC5Q2CgwA41B1u9Mw', 'Onboarding', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('nSutiP3UTkS6Z7PqwtOZRQ', '7tXfGxC5Q2CgwA41B1u9Mw', 'Usage', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('AOxvpSr1STSR9pf1pZTjgg', '7tXfGxC5Q2CgwA41B1u9Mw', 'Maintenance', 400, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('0soMPJ72QvGlHAvWDj5IyQ', 'en', 'Awareness');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('cJzekpbUS0GPnVHQ1eQEKQ', 'en', 'Onboarding');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('nSutiP3UTkS6Z7PqwtOZRQ', 'en', 'Usage');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('AOxvpSr1STSR9pf1pZTjgg', 'en', 'Maintenance');
INSERT INTO ref_host_t(table_id, host_id) values ('7tXfGxC5Q2CgwA41B1u9Mw', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO relation_type_t(relation_id, relation_name, relation_desc) VALUES ('7M4lC6YiTf67H3K97QOkgA', 'platform-capability', 'capability dropdown filtered by platform');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('7M4lC6YiTf67H3K97QOkgA', 'hWJlP0g6QNyKv6t93V6vEA', '0soMPJ72QvGlHAvWDj5IyQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('7M4lC6YiTf67H3K97QOkgA', 'hWJlP0g6QNyKv6t93V6vEA', 'cJzekpbUS0GPnVHQ1eQEKQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('7M4lC6YiTf67H3K97QOkgA', 'hWJlP0g6QNyKv6t93V6vEA', 'nSutiP3UTkS6Z7PqwtOZRQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('7M4lC6YiTf67H3K97QOkgA', 'hWJlP0g6QNyKv6t93V6vEA', 'AOxvpSr1STSR9pf1pZTjgg');



INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('xq5ACm57TwKdLzWdpzT9kQ', 'marketplace_team', 'Marketplace Team', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('oLsy42DXSLataEp0Lacimw', 'xq5ACm57TwKdLzWdpzT9kQ', 'API Platform', 100, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('oLsy42DXSLataEp0Lacimw', 'en', 'API Platform');
INSERT INTO ref_host_t(table_id, host_id) values ('xq5ACm57TwKdLzWdpzT9kQ', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('Tml7tZktQiy_KWP5c9iwzQ', 'network_zone', 'Network Zone', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('yEqFvPF5SmSDB1nOHCs6mg', 'Tml7tZktQiy_KWP5c9iwzQ', 'AIZ', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('D0Kf6_DHQTOAgeAXcCauhw', 'Tml7tZktQiy_KWP5c9iwzQ', 'Corp', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('8TjiaGCNTJi_uxaofxCn1A', 'Tml7tZktQiy_KWP5c9iwzQ', 'DMZ', 300, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('yEqFvPF5SmSDB1nOHCs6mg', 'en', 'Application Isolation Zone');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('D0Kf6_DHQTOAgeAXcCauhw', 'en', 'Corporate Zone');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('8TjiaGCNTJi_uxaofxCn1A', 'en', 'Demilitarized zone');
INSERT INTO ref_host_t(table_id, host_id) values ('Tml7tZktQiy_KWP5c9iwzQ', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('DBetTyPQQOqtlefWrVDk9w', 'infrastructure_type', 'Infrastructure Type', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('O8NFnUFvT7SNDtk26LmfYw', 'DBetTyPQQOqtlefWrVDk9w', 'Generic', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('L1gD5USHQ1W74Bfe-YP6NA', 'DBetTyPQQOqtlefWrVDk9w', 'Linux', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('vl18FrEzQ5-fmlYkWBdk-w', 'DBetTyPQQOqtlefWrVDk9w', 'Windows', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('tg5sInwbRRyoPcr5eGlKPg', 'DBetTyPQQOqtlefWrVDk9w', 'Kubernetes', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ZhpAb072QWqraJFDn1fKlg', 'DBetTyPQQOqtlefWrVDk9w', 'OpenShift', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('dsQs9-dgSWmpQVTWaayj5A', 'DBetTyPQQOqtlefWrVDk9w', 'AWS', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('o8Co_5JAQkiDIo8Njr3HmA', 'DBetTyPQQOqtlefWrVDk9w', 'Azure', 700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('_zCCGPAlSMCevhublBzswQ', 'DBetTyPQQOqtlefWrVDk9w', 'GCP', 800, 'Y');

INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('O8NFnUFvT7SNDtk26LmfYw', 'en', 'Generic');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('L1gD5USHQ1W74Bfe-YP6NA', 'en', 'Linux');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('vl18FrEzQ5-fmlYkWBdk-w', 'en', 'Windows');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('tg5sInwbRRyoPcr5eGlKPg', 'en', 'Kubernetes');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ZhpAb072QWqraJFDn1fKlg', 'en', 'OpenShift');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('dsQs9-dgSWmpQVTWaayj5A', 'en', 'AWS');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('o8Co_5JAQkiDIo8Njr3HmA', 'en', 'Azure');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('_zCCGPAlSMCevhublBzswQ', 'en', 'GCP');
INSERT INTO ref_host_t(table_id, host_id) values ('DBetTyPQQOqtlefWrVDk9w', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('Z0_qeZzCQiOhGawpSZgRFw', 'api_tag', 'API Tag', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('IT1CpXtHQ2ODanl4jURFIA', 'Z0_qeZzCQiOhGawpSZgRFw', 'experience', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('9FT7NC0cQJaQhqP5ek5F7Q', 'Z0_qeZzCQiOhGawpSZgRFw', 'process', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('cV9bZszAQzqLGD8GhmOL9g', 'Z0_qeZzCQiOhGawpSZgRFw', 'system', 300, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('IT1CpXtHQ2ODanl4jURFIA', 'en', 'experience');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('9FT7NC0cQJaQhqP5ek5F7Q', 'en', 'process');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('cV9bZszAQzqLGD8GhmOL9g', 'en', 'system');
INSERT INTO ref_host_t(table_id, host_id) values ('Z0_qeZzCQiOhGawpSZgRFw', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('abdaJhLYREKDdRm_KvkfFQ', 'instance_tag', 'Instance Tag', 'N');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('bzKMKUpwSpeCRZIjBZyWCQ', 'abdaJhLYREKDdRm_KvkfFQ', 'blue', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('DVbvuJKvQg2ZDpLgXxYaIw', 'abdaJhLYREKDdRm_KvkfFQ', 'green', 200, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('bzKMKUpwSpeCRZIjBZyWCQ', 'en', 'Blue');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('DVbvuJKvQg2ZDpLgXxYaIw', 'en', 'Green');
INSERT INTO ref_host_t(table_id, host_id) values ('abdaJhLYREKDdRm_KvkfFQ', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('hcvu8qScQo2OfowMN5ugtg', 'rule_type', 'Rule Type', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('t0wTzmbLRtqPNdP28BqQcA', 'hcvu8qScQo2OfowMN5ugtg', 'generic', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('8_RJ8uyeSXma7KdlhnwRzQ', 'hcvu8qScQo2OfowMN5ugtg', 'req-acc', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('GE9KgK9HSByrybH1sPR7hA', 'hcvu8qScQo2OfowMN5ugtg', 'res-fil', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('76if75FLQCGTMiml5tfwEw', 'hcvu8qScQo2OfowMN5ugtg', 'req-tra', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('O3ocrQ4mTCiG4DIOneFMTg', 'hcvu8qScQo2OfowMN5ugtg', 'res-tra', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('UkC5OiDbS9iNRvanNqwFvQ', 'hcvu8qScQo2OfowMN5ugtg', 'req-val', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('GfDXhwj9RyqqpZi62O0usw', 'hcvu8qScQo2OfowMN5ugtg', 'res-val', 700, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('t0wTzmbLRtqPNdP28BqQcA', 'en', 'Generic');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('8_RJ8uyeSXma7KdlhnwRzQ', 'en', 'Request Access');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('GE9KgK9HSByrybH1sPR7hA', 'en', 'Response Filter');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('76if75FLQCGTMiml5tfwEw', 'en', 'Request Tranform');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('O3ocrQ4mTCiG4DIOneFMTg', 'en', 'Response Transform');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('UkC5OiDbS9iNRvanNqwFvQ', 'en', 'Request Validation');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('GfDXhwj9RyqqpZi62O0usw', 'en', 'Response Validation');
INSERT INTO ref_host_t(table_id, host_id) values ('hcvu8qScQo2OfowMN5ugtg', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('PuGG7Le9QRmWdT8eIuNbEA', 'attribute_type', 'Attribute Type', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('icLGGVxPQTK9vKtG7y7XVw', 'PuGG7Le9QRmWdT8eIuNbEA', 'string', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('izWRPxBgQK6V2I8eLM2vwQ', 'PuGG7Le9QRmWdT8eIuNbEA', 'integer', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ZLb4OODcTT6D62yc4fNzqw', 'PuGG7Le9QRmWdT8eIuNbEA', 'boolean', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('0lTzqXrLQaKV8wry5WEg5A', 'PuGG7Le9QRmWdT8eIuNbEA', 'date', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ihdx0HDnQomjKrqhTIwDRw', 'PuGG7Le9QRmWdT8eIuNbEA', 'time', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('z5OcUYfOROWwoYjloC1isA', 'PuGG7Le9QRmWdT8eIuNbEA', 'timestamp', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('7oZ0aMkxSmOYRdNuWkdqRw', 'PuGG7Le9QRmWdT8eIuNbEA', 'float', 700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('hrMKcaOxTXWeA4wwwhllPA', 'PuGG7Le9QRmWdT8eIuNbEA', 'list', 800, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('icLGGVxPQTK9vKtG7y7XVw', 'en', 'string');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('izWRPxBgQK6V2I8eLM2vwQ', 'en', 'integer');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ZLb4OODcTT6D62yc4fNzqw', 'en', 'boolean');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('0lTzqXrLQaKV8wry5WEg5A', 'en', 'date');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ihdx0HDnQomjKrqhTIwDRw', 'en', 'time');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('z5OcUYfOROWwoYjloC1isA', 'en', 'timestamp');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('7oZ0aMkxSmOYRdNuWkdqRw', 'en', 'float');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('hrMKcaOxTXWeA4wwwhllPA', 'en', 'list');
INSERT INTO ref_host_t(table_id, host_id) values ('PuGG7Le9QRmWdT8eIuNbEA', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('ymOpyDEeQ6ud9lPwZnCAPg', 'filter_operator', 'Filter Operator', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('UfYCIyShS1eaZoYpq5BkwQ', 'ymOpyDEeQ6ud9lPwZnCAPg', '=', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('XYrazGqmT8KVjsAI6uG59A', 'ymOpyDEeQ6ud9lPwZnCAPg', '!=', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('mGBB8xEIQJSc8ymmKyqKHg', 'ymOpyDEeQ6ud9lPwZnCAPg', '<', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('xcohSmkWQbeL192E1tcSWg', 'ymOpyDEeQ6ud9lPwZnCAPg', '>', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('3Yh_Xz7cR7qZ4l7kldKLQQ', 'ymOpyDEeQ6ud9lPwZnCAPg', '<=', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('pEnjY5YvRde8FhM7jarlgA', 'ymOpyDEeQ6ud9lPwZnCAPg', '>=', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('NvZZSIIVQ868pCWjxdqU3g', 'ymOpyDEeQ6ud9lPwZnCAPg', 'in', 700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ncL02GjkSySSF85auAQ2yw', 'ymOpyDEeQ6ud9lPwZnCAPg', 'not in', 800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('QrchwHxBStyxBzmvUg3rAg', 'ymOpyDEeQ6ud9lPwZnCAPg', 'range', 800, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('UfYCIyShS1eaZoYpq5BkwQ', 'en', '=');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('XYrazGqmT8KVjsAI6uG59A', 'en', '!=');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('mGBB8xEIQJSc8ymmKyqKHg', 'en', '<');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('xcohSmkWQbeL192E1tcSWg', 'en', '>');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('3Yh_Xz7cR7qZ4l7kldKLQQ', 'en', '<=');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('pEnjY5YvRde8FhM7jarlgA', 'en', '>=');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('NvZZSIIVQ868pCWjxdqU3g', 'en', 'in');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ncL02GjkSySSF85auAQ2yw', 'en', 'not in');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('QrchwHxBStyxBzmvUg3rAg', 'en', 'range');
INSERT INTO ref_host_t(table_id, host_id) values ('ymOpyDEeQ6ud9lPwZnCAPg', 'N2CMw0HGQXeLvC1wBfln2A');

INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('lEeqoalEQRGPhv5u6jXxyQ', 'country', 'ISO country', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('RKuBaSNPRKiAHOrEhe2wsA', 'lEeqoalEQRGPhv5u6jXxyQ', 'CAN', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('mI3Uw8gISvGe9DXpQemJ5g', 'lEeqoalEQRGPhv5u6jXxyQ', 'USA', 200, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('RKuBaSNPRKiAHOrEhe2wsA', 'en', 'Canada');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('mI3Uw8gISvGe9DXpQemJ5g', 'en', 'USA');
INSERT INTO ref_host_t(table_id, host_id) values ('lEeqoalEQRGPhv5u6jXxyQ', 'N2CMw0HGQXeLvC1wBfln2A');


INSERT INTO ref_table_t(table_id, table_name, table_desc, common) values ('IqtHTASySmmzSVQqYYVy3w', 'province', 'Province or State', 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('4SySR33wS06JMfIsszcRXw', 'IqtHTASySmmzSVQqYYVy3w', 'ON', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('gdcXdRvKTRCTPfXLbwwxAw', 'IqtHTASySmmzSVQqYYVy3w', 'QC', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('f2nPeF5_QyCYUHLWFX_mTA', 'IqtHTASySmmzSVQqYYVy3w', 'NS', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('o1lZHlYJTyevnO8hxgJGBQ', 'IqtHTASySmmzSVQqYYVy3w', 'NB', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('I_w5C08tTKOzmjtKuuBQ4g', 'IqtHTASySmmzSVQqYYVy3w', 'MB', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('p6kiWsTxRvS1YALKu_Ye9g', 'IqtHTASySmmzSVQqYYVy3w', 'BC', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('KMV1WtthTuarWAICFGu4VA', 'IqtHTASySmmzSVQqYYVy3w', 'PE', 700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Ecq4WaVkSxWY7CuAEwJWKA', 'IqtHTASySmmzSVQqYYVy3w', 'SK', 800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('pdLlXyJJRkqIEVikfpAhaA', 'IqtHTASySmmzSVQqYYVy3w', 'AB', 900, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('9ZrQHay6SWSiQzF_p9VpIw', 'IqtHTASySmmzSVQqYYVy3w', 'NL', 1000, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Gc1w4UBzQNGe_auPDAXLAQ', 'IqtHTASySmmzSVQqYYVy3w', 'NT', 1100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('1OZZ_49CSnS_LTFeXZI4FQ', 'IqtHTASySmmzSVQqYYVy3w', 'YT', 1200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('uCPK09RERTm3ePOs8fggQw', 'IqtHTASySmmzSVQqYYVy3w', 'NU', 1300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('9Rn8wW6sQp68nMML3E640Q', 'IqtHTASySmmzSVQqYYVy3w', 'AL', 100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('8eb2qqvyRIWrTloE9P5YWw', 'IqtHTASySmmzSVQqYYVy3w', 'AK', 200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('0OWbTB3yQqKEtsGqfTSIAA', 'IqtHTASySmmzSVQqYYVy3w', 'AZ', 300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('P1hW5PMiS22quKjOw_p1Qw', 'IqtHTASySmmzSVQqYYVy3w', 'AR', 400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('9FuoUVnTTEWDAbvsAls_qQ', 'IqtHTASySmmzSVQqYYVy3w', 'CA', 500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('0HR8TT7FQsOJpBQ3Ts9Q6w', 'IqtHTASySmmzSVQqYYVy3w', 'CO', 600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('axabsLmnRbCpbaVnEm5rpQ', 'IqtHTASySmmzSVQqYYVy3w', 'CT', 700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('atq5TpwqQ6yMzd7nRP2qsQ', 'IqtHTASySmmzSVQqYYVy3w', 'DE', 800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('6RicSPdnS6ulOmuBNJSLiQ', 'IqtHTASySmmzSVQqYYVy3w', 'DC', 900, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('QxUzGj8DQaamil5Ixi5Mqg', 'IqtHTASySmmzSVQqYYVy3w', 'FL', 1000, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('4WaXpgMWTWiTgKnBOBw_fA', 'IqtHTASySmmzSVQqYYVy3w', 'GA', 1100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('6kGKDmreSCepCUZPfrlNXg', 'IqtHTASySmmzSVQqYYVy3w', 'HI', 1200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('OkWLdgR6TSmaMJ4L6nN1iA', 'IqtHTASySmmzSVQqYYVy3w', 'ID', 1300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ysAvApSXQbCeXNuLEHO4MA', 'IqtHTASySmmzSVQqYYVy3w', 'IL', 1400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('KW4bcpSwT965ljf3eQ2JzQ', 'IqtHTASySmmzSVQqYYVy3w', 'IN', 1500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('q1SefWE7R7SydF9am1L0xQ', 'IqtHTASySmmzSVQqYYVy3w', 'IA', 1600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('pnMbZYLNRXCZBNgGQnjXIQ', 'IqtHTASySmmzSVQqYYVy3w', 'KS', 1700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('xOaPdIWlSxysJipep5_8Mw', 'IqtHTASySmmzSVQqYYVy3w', 'KY', 1800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('PfM2V43qRyWlE22JjN9YYg', 'IqtHTASySmmzSVQqYYVy3w', 'LA', 1900, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('75844bWyTGGcGDGUlxX1Iw', 'IqtHTASySmmzSVQqYYVy3w', 'ME', 2000, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('FI9d37HMS524eRphBcZRww', 'IqtHTASySmmzSVQqYYVy3w', 'MD', 2100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ZLRF7XBqQtGn1ocC1fAPBg', 'IqtHTASySmmzSVQqYYVy3w', 'MA', 2200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ojEJsw8kSayQLw7PnbFvQA', 'IqtHTASySmmzSVQqYYVy3w', 'MI', 2300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('XFySNM6GQJKs7ipAPvIhnQ', 'IqtHTASySmmzSVQqYYVy3w', 'MN', 2400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('p0vlgugwRu68Hz7v0PE_rQ', 'IqtHTASySmmzSVQqYYVy3w', 'MS', 2500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Z1ltK9vbSnG0yIZf1Q9Gbg', 'IqtHTASySmmzSVQqYYVy3w', 'MO', 2600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ufBZNeKGTaKP9JRmncr1Yg', 'IqtHTASySmmzSVQqYYVy3w', 'MT', 2700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('u13ZAyLMRm6jdtHv8gmouA', 'IqtHTASySmmzSVQqYYVy3w', 'NE', 2800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('L6BM3GFRQwiTb7TGKB4pUA', 'IqtHTASySmmzSVQqYYVy3w', 'NV', 2900, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('HKC5gT9LSPeCJkQ9aOCPwg', 'IqtHTASySmmzSVQqYYVy3w', 'NH', 3000, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('znDF7_FzTialWfTOcgnZqw', 'IqtHTASySmmzSVQqYYVy3w', 'NJ', 3100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('Gu_yMNh1TLOs3S_8cw_EEw', 'IqtHTASySmmzSVQqYYVy3w', 'NM', 3200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('xX1ql_tZR6S3Fi60w2f5Nw', 'IqtHTASySmmzSVQqYYVy3w', 'NY', 3300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('LaWWB1K4QMqu0oxJUWD7TQ', 'IqtHTASySmmzSVQqYYVy3w', 'NC', 3400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('hzcMPMB8QXCo9B50SnAZcw', 'IqtHTASySmmzSVQqYYVy3w', 'ND', 3500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('hTpuM1xVTTWdfRUgEkPXzg', 'IqtHTASySmmzSVQqYYVy3w', 'OH', 3600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('H_QDW2FfSMuVsQkrRORPzg', 'IqtHTASySmmzSVQqYYVy3w', 'OK', 3700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('MNV6tCAoR6KKl37yVtYfYg', 'IqtHTASySmmzSVQqYYVy3w', 'OR', 3800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('SGty6qwYRTSW4W6SETXaqQ', 'IqtHTASySmmzSVQqYYVy3w', 'PA', 3900, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('dFDbA9l5TZefJBTd15B6Sg', 'IqtHTASySmmzSVQqYYVy3w', 'RI', 4000, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ECnVlHWfRrm52sD9YMbe7Q', 'IqtHTASySmmzSVQqYYVy3w', 'SC', 4100, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('sHXjPXRdRr2zn4dHYQKiVg', 'IqtHTASySmmzSVQqYYVy3w', 'SD', 4200, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('ox9JxOmpRNGwbBR6sa7vfg', 'IqtHTASySmmzSVQqYYVy3w', 'TN', 4300, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('G81Fak4dTwCdYNKiWYyojg', 'IqtHTASySmmzSVQqYYVy3w', 'TX', 4400, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('p7rqy1fNTUOKmDrYeYm1og', 'IqtHTASySmmzSVQqYYVy3w', 'UT', 4500, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('arEz8xOKQMe5f7jqRtrkgA', 'IqtHTASySmmzSVQqYYVy3w', 'VT', 4600, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('5VBfmpLwToCdHlv8whWwgA', 'IqtHTASySmmzSVQqYYVy3w', 'VA', 4700, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('NAZNdWnQRYyEUoBVS6H8ww', 'IqtHTASySmmzSVQqYYVy3w', 'WA', 4800, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('WCZmuWsiROei0WY5mtEduA', 'IqtHTASySmmzSVQqYYVy3w', 'WV', 4900, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('grVp1z6jRzeh2Q_p7WFgIQ', 'IqtHTASySmmzSVQqYYVy3w', 'WI', 5000, 'Y');
INSERT INTO ref_value_t(value_id, table_id, value_code, display_order, active) VALUES ('GqToK4trSNWjUFQTtBnpLg', 'IqtHTASySmmzSVQqYYVy3w', 'WY', 5100, 'Y');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('4SySR33wS06JMfIsszcRXw', 'en', 'Ontario');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('gdcXdRvKTRCTPfXLbwwxAw', 'en', 'Quebec');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('f2nPeF5_QyCYUHLWFX_mTA', 'en', 'Nova Scotia');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('o1lZHlYJTyevnO8hxgJGBQ', 'en', 'New Brunswick');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('I_w5C08tTKOzmjtKuuBQ4g', 'en', 'Manitoba');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('p6kiWsTxRvS1YALKu_Ye9g', 'en', 'British Columbia');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('KMV1WtthTuarWAICFGu4VA', 'en', 'Prince Edward Island');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Ecq4WaVkSxWY7CuAEwJWKA', 'en', 'Saskatchewan');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('pdLlXyJJRkqIEVikfpAhaA', 'en', 'Alberta');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('9ZrQHay6SWSiQzF_p9VpIw', 'en', 'Newfoundland and Labrador');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Gc1w4UBzQNGe_auPDAXLAQ', 'en', 'Northwest Territories');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('1OZZ_49CSnS_LTFeXZI4FQ', 'en', 'Yukon');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('uCPK09RERTm3ePOs8fggQw', 'en', 'Nunavut');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('9Rn8wW6sQp68nMML3E640Q', 'en', 'Alabama');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('8eb2qqvyRIWrTloE9P5YWw', 'en', 'Alaska');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('0OWbTB3yQqKEtsGqfTSIAA', 'en', 'Arizona');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('P1hW5PMiS22quKjOw_p1Qw', 'en', 'Arkansas');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('9FuoUVnTTEWDAbvsAls_qQ', 'en', 'California');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('0HR8TT7FQsOJpBQ3Ts9Q6w', 'en', 'Colorado');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('axabsLmnRbCpbaVnEm5rpQ', 'en', 'Connecticut');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('atq5TpwqQ6yMzd7nRP2qsQ', 'en', 'Delaware');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('6RicSPdnS6ulOmuBNJSLiQ', 'en', 'District of Columbia');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('QxUzGj8DQaamil5Ixi5Mqg', 'en', 'Florida');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('4WaXpgMWTWiTgKnBOBw_fA', 'en', 'Georgia');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('6kGKDmreSCepCUZPfrlNXg', 'en', 'Hawaii');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('OkWLdgR6TSmaMJ4L6nN1iA', 'en', 'Idaho');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ysAvApSXQbCeXNuLEHO4MA', 'en', 'Illinois');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('KW4bcpSwT965ljf3eQ2JzQ', 'en', 'Indiana');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('q1SefWE7R7SydF9am1L0xQ', 'en', 'Iowa');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('pnMbZYLNRXCZBNgGQnjXIQ', 'en', 'Kansas');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('xOaPdIWlSxysJipep5_8Mw', 'en', 'Kentucky');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('PfM2V43qRyWlE22JjN9YYg', 'en', 'Louisiana');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('75844bWyTGGcGDGUlxX1Iw', 'en', 'Maine');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('FI9d37HMS524eRphBcZRww', 'en', 'Maryland');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ZLRF7XBqQtGn1ocC1fAPBg', 'en', 'Massachusetts');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ojEJsw8kSayQLw7PnbFvQA', 'en', 'Michigan');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('XFySNM6GQJKs7ipAPvIhnQ', 'en', 'Minnesota');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('p0vlgugwRu68Hz7v0PE_rQ', 'en', 'Mississippi');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Z1ltK9vbSnG0yIZf1Q9Gbg', 'en', 'Missouri');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ufBZNeKGTaKP9JRmncr1Yg', 'en', 'Montana');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('u13ZAyLMRm6jdtHv8gmouA', 'en', 'Nebraska');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('L6BM3GFRQwiTb7TGKB4pUA', 'en', 'Nevada');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('HKC5gT9LSPeCJkQ9aOCPwg', 'en', 'New Hampshire');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('znDF7_FzTialWfTOcgnZqw', 'en', 'New Jersey');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('Gu_yMNh1TLOs3S_8cw_EEw', 'en', 'New Mexico');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('xX1ql_tZR6S3Fi60w2f5Nw', 'en', 'New York');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('LaWWB1K4QMqu0oxJUWD7TQ', 'en', 'North Carolina');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('hzcMPMB8QXCo9B50SnAZcw', 'en', 'North Dakota');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('hTpuM1xVTTWdfRUgEkPXzg', 'en', 'Ohio');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('H_QDW2FfSMuVsQkrRORPzg', 'en', 'Oklahoma');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('MNV6tCAoR6KKl37yVtYfYg', 'en', 'Oregon');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('SGty6qwYRTSW4W6SETXaqQ', 'en', 'Pennsylvania');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('dFDbA9l5TZefJBTd15B6Sg', 'en', 'Rhode Island');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ECnVlHWfRrm52sD9YMbe7Q', 'en', 'South Carolina');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('sHXjPXRdRr2zn4dHYQKiVg', 'en', 'South Dakota');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('ox9JxOmpRNGwbBR6sa7vfg', 'en', 'Tennessee');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('G81Fak4dTwCdYNKiWYyojg', 'en', 'Texas');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('p7rqy1fNTUOKmDrYeYm1og', 'en', 'Utah');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('arEz8xOKQMe5f7jqRtrkgA', 'en', 'Vermont');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('5VBfmpLwToCdHlv8whWwgA', 'en', 'Virginia');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('NAZNdWnQRYyEUoBVS6H8ww', 'en', 'Washington');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('WCZmuWsiROei0WY5mtEduA', 'en', 'West Virginia');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('grVp1z6jRzeh2Q_p7WFgIQ', 'en', 'Wisconsin');
INSERT INTO value_locale_t(value_id, language, value_desc) VALUES ('GqToK4trSNWjUFQTtBnpLg', 'en', 'Wyoming');
INSERT INTO ref_host_t(table_id, host_id) values ('IqtHTASySmmzSVQqYYVy3w', 'N2CMw0HGQXeLvC1wBfln2A');

-- relation type
INSERT INTO relation_type_t(relation_id, relation_name, relation_desc) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'country-province', 'country province dropdown');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', '4SySR33wS06JMfIsszcRXw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'gdcXdRvKTRCTPfXLbwwxAw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'f2nPeF5_QyCYUHLWFX_mTA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'o1lZHlYJTyevnO8hxgJGBQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'I_w5C08tTKOzmjtKuuBQ4g');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'p6kiWsTxRvS1YALKu_Ye9g');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'KMV1WtthTuarWAICFGu4VA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'Ecq4WaVkSxWY7CuAEwJWKA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'pdLlXyJJRkqIEVikfpAhaA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', '9ZrQHay6SWSiQzF_p9VpIw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'Gc1w4UBzQNGe_auPDAXLAQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', '1OZZ_49CSnS_LTFeXZI4FQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'RKuBaSNPRKiAHOrEhe2wsA', 'uCPK09RERTm3ePOs8fggQw');

INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '9Rn8wW6sQp68nMML3E640Q');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '8eb2qqvyRIWrTloE9P5YWw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '0OWbTB3yQqKEtsGqfTSIAA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'P1hW5PMiS22quKjOw_p1Qw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '9FuoUVnTTEWDAbvsAls_qQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '0HR8TT7FQsOJpBQ3Ts9Q6w');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'axabsLmnRbCpbaVnEm5rpQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'atq5TpwqQ6yMzd7nRP2qsQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '6RicSPdnS6ulOmuBNJSLiQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'QxUzGj8DQaamil5Ixi5Mqg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '4WaXpgMWTWiTgKnBOBw_fA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '6kGKDmreSCepCUZPfrlNXg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'OkWLdgR6TSmaMJ4L6nN1iA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'ysAvApSXQbCeXNuLEHO4MA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'KW4bcpSwT965ljf3eQ2JzQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'q1SefWE7R7SydF9am1L0xQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'pnMbZYLNRXCZBNgGQnjXIQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'xOaPdIWlSxysJipep5_8Mw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'PfM2V43qRyWlE22JjN9YYg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '75844bWyTGGcGDGUlxX1Iw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'FI9d37HMS524eRphBcZRww');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'ZLRF7XBqQtGn1ocC1fAPBg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'ojEJsw8kSayQLw7PnbFvQA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'XFySNM6GQJKs7ipAPvIhnQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'p0vlgugwRu68Hz7v0PE_rQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'Z1ltK9vbSnG0yIZf1Q9Gbg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'ufBZNeKGTaKP9JRmncr1Yg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'u13ZAyLMRm6jdtHv8gmouA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'L6BM3GFRQwiTb7TGKB4pUA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'HKC5gT9LSPeCJkQ9aOCPwg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'znDF7_FzTialWfTOcgnZqw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'Gu_yMNh1TLOs3S_8cw_EEw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'xX1ql_tZR6S3Fi60w2f5Nw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'LaWWB1K4QMqu0oxJUWD7TQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'hzcMPMB8QXCo9B50SnAZcw');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'hTpuM1xVTTWdfRUgEkPXzg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'H_QDW2FfSMuVsQkrRORPzg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'MNV6tCAoR6KKl37yVtYfYg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'SGty6qwYRTSW4W6SETXaqQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'dFDbA9l5TZefJBTd15B6Sg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'ECnVlHWfRrm52sD9YMbe7Q');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'sHXjPXRdRr2zn4dHYQKiVg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'ox9JxOmpRNGwbBR6sa7vfg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'G81Fak4dTwCdYNKiWYyojg');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'p7rqy1fNTUOKmDrYeYm1og');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'arEz8xOKQMe5f7jqRtrkgA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', '5VBfmpLwToCdHlv8whWwgA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'NAZNdWnQRYyEUoBVS6H8ww');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'WCZmuWsiROei0WY5mtEduA');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'grVp1z6jRzeh2Q_p7WFgIQ');
INSERT INTO relation_t(relation_id, value_id_from, value_id_to) VALUES ('ox2ZLivXSoWZPYB4R94S4w', 'mI3Uw8gISvGe9DXpQemJ5g', 'GqToK4trSNWjUFQTtBnpLg');


INSERT INTO product_version_t (host_id, product_id, product_version, light4j_version, version_desc, release_type, current, version_status)
VALUES ('N2CMw0HGQXeLvC1wBfln2A','lg', '1.4.5', '2.1.38','This is incremental release to first major release of light gateway', 'Alpha Version', true, 'Supported');


INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('utgdG50vRVOX3mL1Kf83aA', 'EN', 'Steve', 'Hu', 'steve.hu@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');
INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('fIr8iBGARDy7Hjan9M81UA', 'EN', 'Sophia', 'Fung', 'sophia.fung@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');
INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('BTXdZ4StQMSgha-6Rykuug', 'EN', 'Jacob', 'Miller', 'jacob.miller@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');
INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('yOre_kRkS2exRaUNfoCcAQ', 'EN', 'Michael', 'Carter', 'michael.carter@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');
INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('yBGV5YRMSa-nctTTXMgm9g', 'EN', 'Kevin', 'Grant', 'kevin.grant@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');
INSERT INTO user_t (user_id, language, first_name, last_name, email, user_type, verified, password)
VALUES ('MlctYlGgQXaWU3z4OTZfxA', 'EN', 'Anthony', 'Riley', 'anthony.riley@lightapi.net', 'E', true, '1000:5b39342c202d37372c203132302c202d3132302c2034372c2032332c2034352c202d34342c202d31362c2034372c202d35392c202d35362c2039302c202d352c202d38322c202d32385d:949e6fcf9c4bb8a3d6a8c141a3a9182a572fb95fe8ccdc93b54ba53df8ef2e930f7b0348590df0d53f242ccceeae03aef6d273a34638b49c559ada110ec06992');

INSERT INTO user_host_t (host_id, user_id)  values ('N2CMw0HGQXeLvC1wBfln2A', 'utgdG50vRVOX3mL1Kf83aA');
INSERT INTO user_host_t (host_id, user_id)  values ('N2CMw0HGQXeLvC1wBfln2A', 'fIr8iBGARDy7Hjan9M81UA');
INSERT INTO user_host_t (host_id, user_id)  values ('N2CMw0HGQXeLvC1wBfln2A', 'BTXdZ4StQMSgha-6Rykuug');
INSERT INTO user_host_t (host_id, user_id)  values ('N2CMw0HGQXeLvC1wBfln2A', 'yOre_kRkS2exRaUNfoCcAQ');
INSERT INTO user_host_t (host_id, user_id)  values ('N2CMw0HGQXeLvC1wBfln2A', 'yBGV5YRMSa-nctTTXMgm9g');
INSERT INTO user_host_t (host_id, user_id)  values ('N2CMw0HGQXeLvC1wBfln2A', 'MlctYlGgQXaWU3z4OTZfxA');

INSERT INTO position_t (host_id, position_id, position_desc, inherit_to_ancestor, inherit_to_sibling) VALUES
('N2CMw0HGQXeLvC1wBfln2A', 'APIPlatformOperations', 'API Platform Operations', 'N', 'N'),
('N2CMw0HGQXeLvC1wBfln2A', 'APIPlatformEngineering', 'API Platform Engineering', 'N', 'N'),
('N2CMw0HGQXeLvC1wBfln2A', 'APIPlatformDelivery', 'API Platform Delivery', 'Y', 'Y'),
('N2CMw0HGQXeLvC1wBfln2A', 'APIPlatformQA', 'API Platform QA', 'N', 'N');


INSERT INTO employee_t (host_id, employee_id, user_id, title, manager_id, hire_date) VALUES
('N2CMw0HGQXeLvC1wBfln2A', 'sf32', 'fIr8iBGARDy7Hjan9M81UA', 'AVP API Platform', NULL, '2023-01-15'),
('N2CMw0HGQXeLvC1wBfln2A', 'sh35', 'utgdG50vRVOX3mL1Kf83aA', 'Consulant API Platform', 'sf32', '2023-06-18'),
('N2CMw0HGQXeLvC1wBfln2A', 'jm43', 'BTXdZ4StQMSgha-6Rykuug', 'Director', 'sf32', '2023-02-20'),
('N2CMw0HGQXeLvC1wBfln2A', 'mc87', 'yOre_kRkS2exRaUNfoCcAQ', 'Senior API Platform Solutions Design Engineer', 'jm43', '2023-03-10'),
('N2CMw0HGQXeLvC1wBfln2A', 'kg17', 'yBGV5YRMSa-nctTTXMgm9g', 'Senior API Platform Solutions Design Engineer', 'jm43', '2023-04-05'),
('N2CMw0HGQXeLvC1wBfln2A', 'ar96', 'MlctYlGgQXaWU3z4OTZfxA', 'Senior Reliability Engineer', 'jm43','2023-05-12');


INSERT INTO employee_position_t (host_id, employee_id, position_id, position_type, start_ts, end_ts) VALUES
('N2CMw0HGQXeLvC1wBfln2A', 'sh35', 'APIPlatformDelivery', 'P', CURRENT_TIMESTAMP, NULL), -- APIPlatformDelivery
('N2CMw0HGQXeLvC1wBfln2A', 'jm43', 'APIPlatformDelivery', 'D', CURRENT_TIMESTAMP, NULL),  -- APIPlatformDelivery D from mc87
('N2CMw0HGQXeLvC1wBfln2A', 'mc87', 'APIPlatformEngineering', 'P', CURRENT_TIMESTAMP, NULL),  -- APIPlatformEngineering
('N2CMw0HGQXeLvC1wBfln2A', 'mc87', 'APIPlatformDelivery', 'P', CURRENT_TIMESTAMP, NULL), -- APIPlatformDelivery
('N2CMw0HGQXeLvC1wBfln2A', 'kg17', 'APIPlatformEngineering', 'P', CURRENT_TIMESTAMP, NULL), -- APIPlatformEngineering
('N2CMw0HGQXeLvC1wBfln2A', 'kg17', 'APIPlatformDelivery', 'S', CURRENT_TIMESTAMP, NULL), -- APIPlatformDelivery S from mc87
('N2CMw0HGQXeLvC1wBfln2A', 'ar96', 'APIPlatformQA', 'P', CURRENT_TIMESTAMP, NULL), -- APIPlatformQA
('N2CMw0HGQXeLvC1wBfln2A', 'ar96', 'APIPlatformDelivery', 'S', CURRENT_TIMESTAMP, NULL); -- APIPlatformDelivery S from mc87


INSERT INTO role_t (host_id, role_id, role_desc) values ('N2CMw0HGQXeLvC1wBfln2A', 'user', 'logged in user with an identification in the application');
INSERT INTO role_t (host_id, role_id, role_desc) values ('N2CMw0HGQXeLvC1wBfln2A', 'admin', 'logged in admin that can do all admin activities');


INSERT INTO role_user_t (host_id, role_id, user_id) values ('N2CMw0HGQXeLvC1wBfln2A', 'user', 'utgdG50vRVOX3mL1Kf83aA');
INSERT INTO role_user_t (host_id, role_id, user_id) values ('N2CMw0HGQXeLvC1wBfln2A', 'admin', 'utgdG50vRVOX3mL1Kf83aA');

INSERT INTO attribute_t (host_id, attribute_id, attribute_type, attribute_desc) values ('N2CMw0HGQXeLvC1wBfln2A', 'country', 'string', 'The three-letter country code of the user');
INSERT INTO attribute_t (host_id, attribute_id, attribute_type, attribute_desc) values ('N2CMw0HGQXeLvC1wBfln2A', 'security_clearance_level', 'integer', 'The security clearance level 1, 2, 3');
INSERT INTO attribute_t (host_id, attribute_id, attribute_type, attribute_desc) values ('N2CMw0HGQXeLvC1wBfln2A', 'peranent_employee', 'boolean', 'Indicate if the user is a permanent employee');

INSERT INTO attribute_user_t (host_id, attribute_id, user_id, attribute_value) values ('N2CMw0HGQXeLvC1wBfln2A', 'country', 'utgdG50vRVOX3mL1Kf83aA', 'CAN');
INSERT INTO attribute_user_t (host_id, attribute_id, user_id, attribute_value) values ('N2CMw0HGQXeLvC1wBfln2A', 'security_clearance_level', 'utgdG50vRVOX3mL1Kf83aA', '2');
INSERT INTO attribute_user_t (host_id, attribute_id, user_id, attribute_value) values ('N2CMw0HGQXeLvC1wBfln2A', 'peranent_employee', 'utgdG50vRVOX3mL1Kf83aA', 'true');

INSERT INTO group_t (host_id, group_id, group_desc) VALUES
('N2CMw0HGQXeLvC1wBfln2A', 'select', 'Users with select or view privileges'),
('N2CMw0HGQXeLvC1wBfln2A', 'insert', 'Users with insert or add privileges'),
('N2CMw0HGQXeLvC1wBfln2A', 'update', 'Users with update or edit privileges'),
('N2CMw0HGQXeLvC1wBfln2A', 'delete', 'Users with delete or remove privileges');

INSERT INTO group_user_t (host_id, group_id, user_id, start_ts) VALUES
('N2CMw0HGQXeLvC1wBfln2A', 'select', 'utgdG50vRVOX3mL1Kf83aA', CURRENT_TIMESTAMP),
('N2CMw0HGQXeLvC1wBfln2A', 'insert', 'utgdG50vRVOX3mL1Kf83aA', CURRENT_TIMESTAMP),
('N2CMw0HGQXeLvC1wBfln2A', 'update', 'utgdG50vRVOX3mL1Kf83aA', CURRENT_TIMESTAMP),
('N2CMw0HGQXeLvC1wBfln2A', 'delete', 'utgdG50vRVOX3mL1Kf83aA', CURRENT_TIMESTAMP);

INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'APM000100', 'Admin Client', 'Access the adm endpoints of light-portal services', false, null, null);


INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'admin client', 'APM000100', 'f7d42348-c647-4efb-a52d-4c5787421e70', 'trusted', 'mobile', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'admin', null, 'https://localhost:3000/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);

INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'APM000123', 'PetStore Web Server', 'PetStore Web Server that calls PetStore API', false, null, null);

INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'petstore server', 'APM000123', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'trusted', 'mobile', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'portal.r portal.w ref.r ref.w', '{"c1": "361", "c2": "67"}', 'https://localhost:3000/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);


INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'APM000124', 'Light Portal Test Web Application', 'Light Portal Test React Single Page Application', false, null, null);

INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'portal web test', 'APM000124', 'f7d42348-c647-4efb-a52d-4c5787421e73', 'trusted', 'browser', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'portal.r portal.w ref.r ref.w', null, 'https://dev.lightapi.net/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);


INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'APM000126', 'Light Portal Test Web Application', 'Light Portal Test React Single Page Application', false, null, null);


INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'portal web app', 'APM000126', 'f7d42348-c647-4efb-a52d-4c5787421e75', 'trusted', 'browser', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'portal.r portal.w ref.r ref.w', null, 'https://dev.lightapi.net/authorization', 'com.networknt.oauth.auth.DefaultAuth', null);

INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'APM000127', 'Petstore Client Application', 'An example application that is used to demo access to openapi-petstore', false, null, null);


INSERT INTO auth_client_t (host_id, client_name, app_id, client_id, client_type, client_profile, client_secret, 
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'petstore app', 'APM000127', 'f7d42348-c647-4efb-a52d-4c5787421e76', 'trusted', 'browser', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'read:pets write:pets', null, 'https://dev.lightapi.net/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);

INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'EF3wqhfWQti2DUVrvYNM7g', 'f7d42348-c647-4efb-a52d-4c5787421e70');
INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'EF3wqhfWQti2DUVrvYNM7g', 'f7d42348-c647-4efb-a52d-4c5787421e72');
INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'EF3wqhfWQti2DUVrvYNM7g', 'f7d42348-c647-4efb-a52d-4c5787421e73');
INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'EF3wqhfWQti2DUVrvYNM7g', 'f7d42348-c647-4efb-a52d-4c5787421e75');
INSERT INTO auth_provider_client_t (host_id, provider_id, client_id) VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'EF3wqhfWQti2DUVrvYNM7g', 'f7d42348-c647-4efb-a52d-4c5787421e76');

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
    ('N2CMw0HGQXeLvC1wBfln2A', '0100', 'Petstore Rest API', 'Petstore Rest API', 'sh35', 'sh35', null, null, null, null, null, 'https://bitbucket.networknt.com/projects/repos/petstore-api', null, 'onboarded' ),
    ('N2CMw0HGQXeLvC1wBfln2A', '0239', 'Petstore GraphQL API', 'Petstore GraphQL API', 'sh35', 'sh35', null, null, null, null, null, 'https://bitbucket.networknt.com/projects/repos/petstore-graphql', NULL, 'onboarded');


INSERT INTO api_version_t
    (host_id, api_id, api_version, api_type, service_id, api_version_desc, spec_link)
VALUES
    ('N2CMw0HGQXeLvC1wBfln2A', '0100', '1.0.0', 'openapi', 'com.networknt.petstore-1.0.0', 'First Major release', null),
    ('N2CMw0HGQXeLvC1wBfln2A', '0239', '1.0.0', 'graphql', 'com.networknt.petstore-2.0.0', 'Second Major release', null);

INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('fYhRgziBRLabCJeNrA7NqQ', 'access-control', 'Handler', 'com.networknt.openapi.AccessControlHandler', 'This configuration is for access control provided by openapi module for handler com.networknt.openapi.AccessControlHandler. This is a business middleware handler that should be put after the technical middleware handlers in the request/response chain. It handles fine-grained authorization on the business domain. In the request chain, it will check a list of conditions (rule-based authorization) at the endpoint level. In the response chain, a list of rules/conditions will be checked to filter the response to remove some rows and/or some columns. This handler is depending on the yaml-rule from light-4j of networknt and all rules for the service will be loaded during the startup time with a startup hook and this handler will use the cached rules and data to do local calculation for the best performance.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('fYhRgziBRLabCJeNrA7NqQ', 'defaultDeny', 'Config', 1, FALSE, 'If there is no access rule defined for the endpoint, default access is denied. Users can overwrite this default action by setting this config value to false. If true, the handle will force users to define the rules for each endpoint when the access control handler is enabled.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('fYhRgziBRLabCJeNrA7NqQ', 'enabled', 'Config', 2, FALSE, 'AccessControlHandler will be the last middleware handler before the proxy on the sidecar or the last one before the business handler to handle the fine-grained authorization in the business domain. Enable Access Control Handler', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('fYhRgziBRLabCJeNrA7NqQ', 'skipPathPrefixes', 'Config', 3, FALSE, 'Define a list of path prefixes to skip the access-control to ease the configuration for the handler.yml so that users can define some endpoint without fine-grained access-control security even through it uses the default chain. This is useful if some endpoints want to skip the fine-grained access control in the application. The format is a list of strings separated with commas or a JSON list in values.yml definition from config server, or you can use yaml format in externalized access-control.yml file.', NULL, 'list', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('Qr8gEApWSNCXYWjGdO8LCA', 'apikey', 'Handler', 'com.networknt.apikey.ApiKeyHandler', 'The ApiKey Authentication Security Configuration for light-4j present in apikey.yml and used by com.networknt.apikey.ApiKeyHandler. For some legacy applications to migrate from the monolithic gateway to light-gateway without changing any code, we need to support the API Key authentication on the light-gateway(LG) or light-client-proxy(LCP) to authenticate the consumer and then change the authentication from API Key to OAuth 2.0 for downstream API access. Only certain paths will have API Key set up and the header name for each application might be different. To support all use cases, we add a list of maps to the configuration apikey.yml to pathPrefixAuths property. Each config item will have pathPrefix, headerName and apiKey. The handler will try to match the path prefix first and then get the input API Key from the header. After compare with the configured API Key, the handler will return either ERR10057 API_KEY_MISMATCH or pass the control to the next handler in the chain.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Qr8gEApWSNCXYWjGdO8LCA', 'enabled', 'Config', 1, FALSE, 'Enable or Disable the ApiKey validation', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Qr8gEApWSNCXYWjGdO8LCA', 'hashEnabled', 'Config', 2, FALSE, 'If API key hash is enabled. The API key will be hashed with PBKDF2WithHmacSHA1 before it is stored in the config file. It is more secure than put the encrypted key into the config file. If you want to enable it, you need to use the following repo https://github.com/networknt/light-hash command line tool to hash the clear text key.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Qr8gEApWSNCXYWjGdO8LCA', 'pathPrefixAuths', 'Config', 3, FALSE, 'Path prefix to the api key mapping. It is a list of map between the path prefix and the api key for apikey authentication. In the handler, it loops through the list and find the matching path prefix. Once found, it will check if the apikey is equal to allow the access or return an error. The map object has three properties: pathPrefix, headerName and apiKey. Example value format : [ { pathPrefix: /some/path/prefix, headerName: header-name, apiKey: some-api-key } ]', NULL, 'list', 'app_api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'audit', 'Handler', 'com.networknt.audit.AuditHandler', 'The audit.yml configuration and used by com.networknt.audit.AuditHandler. The audit handler dumps most important info per-request basis. This handler can be used on production but be aware that it will impact the overall performance. Turning off statusCode and responseTime can make it faster as these have to be captured on the response chain instead of request chain. For most business and the majority of microservices, you don''t need to enable this handler due to performance reason. The default audit log will be the audit.log configured in the default logback.xml; however, it can be changed to syslog or Kafka with customized appender. The audit.yml can control which fields should be included in the final log. By default, the following fields are included: timestamp, serviceId (from server.yml), correlationId, traceabilityId (if available), clientId, userId (if available), scopeClientId (available if called by another API), endpoint (uriPattern@method), statusCode, responseTime.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'audit', 'Config', 1, FALSE, 'Fields to be captured from body or token and written in the output audit file', '[client_id, user_id, scope_client_id, endpoint, serviceId]', 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'auditOnError', 'Config', 2, FALSE, 'when it is true: (it will only log when status code >= 400, response body will be only logged when it is true, status detail will be only logged when it is true), when it is false: (it will log on every request, no response body will be logged, no status detail will be logged)', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'enabled', 'Config', 3, FALSE, 'Enable or Disable Audit capture', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'headers', 'Config', 4, FALSE, 'Fields to be captured from headers and written in the output audit file', '[X-Correlation-Id, X-Traceability-Id, caller_id]', 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'logLevelIsError', 'Config', 5, FALSE, 'Log level to used for audit entries; by default set to info', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'mask', 'Config', 6, FALSE, 'Enable or Disable mask of audit entries', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'requestBodyMaxSize', 'Config', 7, FALSE, 'The limit of the request body to put into the audit entry if requestBody is in the list of audit. If the request body is bigger than the max size, it will be truncated to the max size.', 4096, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'responseBodyMaxSize', 'Config', 8, FALSE, 'The limit of the response body to put into the audit entry if responseBody is in the list of audit. If the response body is bigger than the max size, it will be truncated to the max size.', 4096, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'responseTime', 'Config', 9, FALSE, 'Output response time', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'statusCode', 'Config', 10, FALSE, 'Output response status code', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('FIMMpdKpRoqp8Ab7bShYUQ', 'timestampFormat', 'Config', 11, FALSE, 'the format for outputting the timestamp, if the format is not specified or invalid, will use a long value.', NULL, 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('wFBQegSlT82UWwa4CFnHHQ', 'basic', 'Handler', 'com.networknt.basicauth.BasicAuthHandler', 'The Basic Authentication Security Configuration for light-4j present in basic-auth.yml and used by com.networknt.basicauth.BasicAuthHandler. This is a middleware handler that handles basic authentication in restful APIs. It is not used in most situations as OAuth 2.0 is the standard. In certain cases for example, the server is deployed to IoT devices, basic authentication can be used to replace OAuth 2.0 handlers. There are multiple users that can be defined in basic.yml config file. Password can be stored in plain or encrypted format in basic.yml. In case of password encryption, please remember to add corresponding com.networknt.utility.Decryptor in service.yml. And access is logged into audit.log if audit middleware is used.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('wFBQegSlT82UWwa4CFnHHQ', 'allowAnonymous', 'Config', 1, FALSE, 'Do we allow the anonymous to pass the authentication and limit it with some paths to access? Default is false, and it should only be true in client-proxy.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('wFBQegSlT82UWwa4CFnHHQ', 'allowBearerToken', 'Config', 2, FALSE, 'Allow the Bearer OAuth 2.0 token authorization to pass to the next handler with paths authorization defined under username bearer. This feature is used in proxy-client that support multiple clients with different authorizations.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('wFBQegSlT82UWwa4CFnHHQ', 'enableAD', 'Config', 3, FALSE, 'Enable Ldap Authentication', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('wFBQegSlT82UWwa4CFnHHQ', 'enabled', 'Config', 4, FALSE, 'Enable Basic Authentication Handler, default is false.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('wFBQegSlT82UWwa4CFnHHQ', 'users', 'Config', 5, FALSE, 'Usernames, passwords, applicable paths in a list (the password can be encrypted). For each user, you can specify a list of optional paths that this user is allowed to access. A special user anonymous can be used to set the paths for client without an authorization header. The paths are optional and used by proxy only to authorize. Example value format : [ { username: admin, password: CRYPT:someCryptHere, paths: [/adm/modules, /adm/server/info] } ]', NULL, 'list', 'app_api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('NkQ1vTnhR0WuelJ4Sctwew', 'body', 'Handler', 'com.networknt.body.BodyHandler', 'The Body Handler configuration present in body.yml and used by com.networknt.body.BodyHandler. This is a handler that parses the body into a Map or List if the input content type is application/json or multipart/form-data or application/x-www-form-urlencoded. For other content type, don''t parse it. In order to trigger this middleware, the content type must be set in header for post, put and patch.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NkQ1vTnhR0WuelJ4Sctwew', 'cacheRequestBody', 'Config', 1, FALSE, 'Cache request body as a string along with JSON object. The string formatted request body will be used for audit log. You should only enable this if you have configured audit.yml to log the request body as it uses extra memory.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NkQ1vTnhR0WuelJ4Sctwew', 'cacheResponseBody', 'Config', 2, FALSE, 'Cache response body as a string along with JSON object. The string formatted response body will be used for audit log. You should only enable this if you have configured audit.yml to log the response body as it uses extra memory.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NkQ1vTnhR0WuelJ4Sctwew', 'enabled', 'Config', 3, FALSE, 'Enable body parse flag', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NkQ1vTnhR0WuelJ4Sctwew', 'logFullRequestBody', 'Config', 4, FALSE, 'Log the full request body when RequestBodyInterceptor is enabled. This is useful for troubleshooting but not recommended for production. The default value is false and only 16K of the request body will be logged.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NkQ1vTnhR0WuelJ4Sctwew', 'logFullResponseBody', 'Config', 5, FALSE, 'Log the full response body when ResponseBodyInterceptor is enabled. This is useful for troubleshooting but not recommended for production. The default value is false and only 16K of the response body will be logged.', 'false', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('t6Qb2cCJRIKgKeiecOcSIw', 'cache', 'Module', 'com.networknt.cache.CacheExplorerHandler', 'This configuration is for centralized cache management which would be used by com.networknt.cache.CacheManager to configure its state.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('t6Qb2cCJRIKgKeiecOcSIw', 'caches', 'Config', 1, FALSE, 'There will be multiple caches per application and each cache should have it own name and expiryInMinutes. The caches are lists of caches. The cache name is used to identify the cache and the expiryInMinutes the expiry time. Example value format [{cacheName: responseCache, expiryInMinutes: 60, maxSize: 1000}]', NULL, 'list', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('U8Xv1GETTb6a1Fn2RhmpqQ', 'cannex', 'Module', 'com.networknt.soap.SoapSecurityTransformAction', 'The configuration for cannex.yml used by com.networknt.soap.SoapSecurityTransformAction which Transform a soap request to call the external service with a security section with username, password, nonce and timestamp. The original request body, username and password will be passed from the yaml rule. Moreover, only regex replacement is used. For further details visit soap-security section which is part of yaml-rule-engine. Please be aware that we are dealing with XML content here instead of JSON.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('U8Xv1GETTb6a1Fn2RhmpqQ', 'password', 'Config', 1, FALSE, 'The username for the CANNEX security. If we put it into the yaml rule, then we need to update the rule.', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('U8Xv1GETTb6a1Fn2RhmpqQ', 'username', 'Config', 2, FALSE, 'The password for the CANNEX security. If we put it into the yaml rule, then we need to update the rule.', 'username', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('ytYildd9QFe0orgpMp583Q', 'chaos-monkey', 'Handler', 'com.networknt.chaos.ChaosMonkeyGetHandler, com.networknt.chaos.ChaosMonkeyPostHandler ', 'Light Chaos Monkey API handlers Configuration.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ytYildd9QFe0orgpMp583Q', 'enabled', 'Config', 1, FALSE, 'Enable the handlers if set to true to allow user to get or post configurations for the assault handlers.', 'false', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('tsrtN7IRRFWXuv8CrtIZXg', 'certs', 'Module', null, 'The certificates which are needed by light-4j framework.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tsrtN7IRRFWXuv8CrtIZXg', 'client.keystore', 'Cert', 1, FALSE, 'The client.keystore', '/u3+7QAAAAIAAAABAAAAAQAGY2xpZW50AAABPFM2vYYAAAUCMIIE/jAOBgorBgEEASoCEQEBBQAEggTqPbJH0Ue8oaEPpAzRblaucN7inwO38cKxI9zIjpljNa97IyvRW894wXWPQYUdKRI6V7xFgPGxgc28HBRQWxuNbhPVP6/zgwaId+2fTKWC9NBnaLUoVcCTZNB1iiDYlxmlvwxOpUfwYFq497lUV4MjRAue8zxBKencujVO6duzaevKQ7s5LbOQ5gc40gP/6YVEhrsoFcmxa04xArH5zTJQiKVPJKrnC8QmOUWEvqcFzSfEUqhIvoh3hWNn6NRRTAx6nR2p1GKXh+zowGTb1x5LWsoBd1AmeIEmcL/MZVfJxk031+Cxs7KVuUZ5Tsnpjtyn/KWIY4z2XV35pH0g9WEA2tCTZ4hnsJDdbLnsb/0wP1cXjeNXuY9ZQ8pPFOI0IKG4NbVb7txtn1nPl8sm3HyAg2qRk0qOpicJlNHHeKTnXOAxXClssMPJ63jx7oy8f100R84iK0fUFf8QHSHp5+JkdVOU7QojsZgMJawnd3J4C4XMmXlFm6d1bHchExJM9RAPHQmZRcTTDXfGnNszkGm8rBN9MpZlbRGZJzc2+bbEDyEWslEirGv/F3S9xqEY8rUKu/VyzYjdJYJ8pYSP79fRp/63UI3cnt3XB71wXmn1fv4V9ktYBHOk+fPZo2VgEoRl5mmE3fkgSTFtguzLnINec2NRrcY5025qG41FQpVmCNiu9HiSbpVnQqTtVp7fbHfqgWFCUuh6l04lpN7ftIohf7Ovrryk+Ag2IvpYpZnZ7jMm8U2r3hkxgDSxMfJTJ5riAxJgZ6J4XbwAtKo48LkVPV3Eayeb2mMK0/CGCFxCIJZRx/boJqhIHKcfPDZpwyTxnDvUGqe332U7BcYoGOfbNMrjWbhhIsGvtCZ/Jr8yS20gZNOPDX2QlXjE8mxgSjTAmoOLCf1nyJ5NgOjUelxb37tDj9XMjfpsQPuSmeFF3wyhIhS5yJW4+ni0FfeR6yHRc2MCJYfqgcY7KsGuDV42VBo2aGt9Lvmn8ZaOdBWfdMfthkKt8QAx/NqKuoHLQfJb1Lbs8U1MKovKIiAfOic8TEZ0zQTRqkBe0tK4STh4R+qARue1j34s/o93Vj74Kx6ZKVfjJwexnaqor6tsq2BiTBFy4u+fCxfZCFLfiJ5uUcwK2b910K6srNWzlw43oZ3oVN+Ctnv8bij6JPVFeihmIUxThffAgUDYg4LZ8/wLJ7jPV6zd5xnZS1axUOkWT+opzr2jI3m7gswqCTIKfyaakkXB8vaAiK4qixBmBgwr3C5HmWqlj78QZMIgIoBvtwQIySeUM5eQX2dc31WcsmjH+7U6ExEBjhQPqfHG6GkI0d6gwLjfo3IIdUwMs5yQdRVHpkm6Dkk17znTekdWxM5AgbYz3+NTzewlMJ6KDJlEWihokbjeis4zZsg/xhAWZMYgGdPzDS0nMDa/ws9tAzDCgXiWquqfFNKDAEb2y2OvAx9evMSfc4XkIaEhAgGcYAB0FaPcnype7V7oyReC14TTD1On9fke/W7D+qvJ6f0P9w4/oCpm/IvsZwxg4nQZC1UsFB0XabXSO32BX9va55LPhtqn6uxDCqa1oSB2b9zsBfcbY01OjAcMKbmDu5BlpBfnRMjzR163u7CdyLx8Xf2HSxPNlqnY4xJy6/2+d2h0HZdtY3wdiNR0abq9u7cq84YbnvArn6aPwSrpDwAAAAEABVguNTA5AAADOjCCAzYwggIeoAMCAQICBFD6rcAwDQYJKoZIhvcNAQELBQAwXTELMAkGA1UEBhMCR0IxDjAMBgNVBAgTBVN0YXRlMQ0wCwYDVQQHEwRDaXR5MQwwCgYDVQQKEwNPcmcxCzAJBgNVBAsTAk9VMRQwEgYDVQQDEwtUZXN0IENsaWVudDAeFw0xMzAxMTkxNDI5MjBaFw0yMzAxMTcxNDI5MjBaMF0xCzAJBgNVBAYTAkdCMQ4wDAYDVQQIEwVTdGF0ZTENMAsGA1UEBxMEQ2l0eTEMMAoGA1UEChMDT3JnMQswCQYDVQQLEwJPVTEUMBIGA1UEAxMLVGVzdCBDbGllbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCBXMXJ9TOIZoKB994N6UrtJB8g9+OV7NyZNt8QPGL8ScVHmEXmaPeD3H4up5MtpoUePsBqPPgmQDDt/5KsXwXAWPzSGy2bRCkPrAAWXP9kqnNcNa9leE7MYm0Sw6XsWw/fku2iwIU06TsARSSL93kFNo8/l+EVVzO98z0QNWqH6sZeXlPz/BY/qdCVMzQUL8XfhYs68z2FJESUjCGTwgWsdbkYCfLtC+Q0OgMV3vjoEwif4IQ8rPWcC4QR2TXmr/P4odrcMHeOUaJAMNYeddfiiinCcgaRHx8qxXpWA3nFJAtGKYZT1e801q5wcSRLayysnijvqB/q71EwnsTtOwzNAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAFyREK4uVVNC8v308IThuDr0GLYocAlQMIHr/hiuv6G/w1kd7NMWFaZgLPp82hY6ohy/GAzNruBp7Obu3mNPnsn6vo0sLxI4X5lht3GA0zb2zjrhuE61zm+gFK6ki8ZugOyuj4YwaIqTVBSzsoljQn60YhTAYCR7y2XMr9CGUFy84pn4KOq2UaZl0fOXaudFGGhTi8cNpKpJ3FPFAqNODOKy9X9k+Fx2l3bbZnX9xGeaaG6wDSlDF1e/YoRfS2B/sq3OtNqVS7AbES1r1UWoMpj/MOoRoDJ8kwIFZgSFAuxTYhCsiMPf7aVaHyDSzvioa9JFQ7RmXvcR1kkuA3TXHVAF/rskSQH7cKKNthABq519AYt5Sg==', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tsrtN7IRRFWXuv8CrtIZXg', 'client.truststore', 'Cert', 2, FALSE, 'The client.truststore', '/u3+7QAAAAIAAAABAAAAAgAGc2VydmVyAAABPFM5L2YABVguNTA5AAADNjCCAzIwggIaoAMCAQICBFD6rWgwDQYJKoZIhvcNAQELBQAwWzELMAkGA1UEBhMCR0IxDjAMBgNVBAgTBVN0YXRlMQ0wCwYDVQQHEwRDaXR5MQwwCgYDVQQKEwNPcmcxCzAJBgNVBAsTAk9VMRIwEAYDVQQDEwlsb2NhbGhvc3QwHhcNMTMwMTE5MTQyNzUyWhcNMjMwMTE3MTQyNzUyWjBbMQswCQYDVQQGEwJHQjEOMAwGA1UECBMFU3RhdGUxDTALBgNVBAcTBENpdHkxDDAKBgNVBAoTA09yZzELMAkGA1UECxMCT1UxEjAQBgNVBAMTCWxvY2FsaG9zdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALpmHBbQlIm+1+hxLi8GvYjYWwEaH4UorO92qAXtiJ4EetvzSkNaBbFkRkdpYkR9F3lwDkMKqkZxu1QcvAvgDLE90ppO038JO/0XlH464XNZI3FH+EgSdvyURVAOQweZ1vIbcZaP6gHatyL+kVAZ2JUeJUhkfLB9cy1GfhkFY95Op1N/hM7Ha9/jxzwYhKrZ746XnvyHbe+mSKGZAtnoP3nMXIvV9POn5dMknRa76CQ+V6GXNmkvnw8XmwUkBJVnKSJ+Uu6BjrQXf3HvGMY+NoAiJJDqfiD7muVcvaUVuAcHfYRr2+WgVtVKa8asmdVUYCl6/Lzmi6M0HmxNg3qutTUCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAYztnUzM76vvs5BHvAEuS122oT261LxpUihrPnFNKO/IniUwZbfvM0zvBn4doHXI9bCyxFwDkq1bqmZweYbq5cVc/TavTp93hIc2TCokzgSR5tVxtOZm+FjsAytLta43H/3LTJkl5Gg0pRw9Tl9TTF6NbfSon1vMXTUgj0m8ID+BX9xjJzqIgI2q3Mp3d19QoHsm8EEEd/ZyLym6BBQfpC8DG32yfWO+sLWiSx5OV2A0ckhSPExNKbbfDVR0DV95QzXTMGt/zl05TBe5UWb844m/8kXOBJI7Qoc9AItGHb+oAFi60YONEnCwxaNhVxkQDV4jwQZL2XqIXQKBWpZwF6kf2E9yFmvykIMhxpIPaE8yXta+G', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tsrtN7IRRFWXuv8CrtIZXg', 'server.keystore', 'Cert', 3, FALSE, 'The server.keystore', '/u3+7QAAAAIAAAABAAAAAQAGc2VydmVyAAABPFM1Y0YAAAUDMIIE/zAOBgorBgEEASoCEQEBBQAEggTrhvNHoKTm6ZB65ifPqGumoXrsyxDazfcacihSrtVvm8Oya/49fAoydmEUvQas11JOE43dI8Uo2APp5dRbR5fEkGcVNngluua7IBUelH85/zcHC1PJpfXhaQChkGMXPZ+86oZclFKguhJgUCO+qrWf1wbquCUJzjOuwxGlhVAnsNb4BCyuMbS9LDW/zafhAtW8VSVHeiDGuuTAX/lCMo7vSHc6h4dofFIgpmFTRhOzF2T2Ej6Fo0AmhbMQea6Gm8IHLMuq88WUhww/z16ihmIEK8mBWsQxakfLoPIEcScPskR7ddGqCxXwCX7YLGrREzYNOWZqsN4G+E7xiBUli//o5KQcC3rTatqJ+S4Gf7Db3TeJCWIY+fNG9xtnwao1GwovZM78hs3FFfNwQudgkwcH2WjzeIrbTM6kras8o5ciW33mkE5CcfG0C9eyRdWImgLTiWoOrRzUUVeC4YnVBX+1YImASJO4chuG7/Emrel/hWhJmfJbyI8yJ/1E8BdTbGW41xFC7VSMR96Znrrs7rTSJNSiWOWTLUHa3z7d8/RrUSl8aywZbo5LAX4D2TZ6pXO8onXIcsea6EfGWwgzdyUkEkE7rTPJzVZOzSxzSLmY78XBMeys4c2kYk0MyCHEtEBfCEGKgBZvl4rcFLUS6KL426sZs1swl/qKQAaIUVgKIpsO0T9nk7HGQ6hdIsjwruzOqut/xs8sDFrIRreFGcmwfJbkDD+MJ7MPME9c1S8IkNbahT/YRg4pmWIPNkerTsjh+LurGJuzXNHjOWxk4uUiOAyv8Gx+xbYVNa67ELRiV3F1iFDxW45OZ25m+zFy5I/tJz1FS/WlT1Fu4bKABRxYuLk1gMK9x3YRj1zyM67z84N/8a0HyD2jGeJnVVfE0ahh40W1tVdxiZDtXoFs7e/XZgwk9uo3Tkf7i/6CO/rmtcrquBblqRo6EJXN3+oBE1V9V0iAYvJwnxeHm2J8wuB29gpLNb0vRmyN+nkoWdtBrKlE8EtPFOwtw9ldqOYqc9biwsFAjs+VEseXzfhLwqE3xuIUKjEOC5sE8ABi3xI4J/bhxdMh5sAV710EoVDJDpsn71+jto7oIpwpxp0qPwyQoVH0WHPmxVglRibcMH2i8NPiRD/DTWShYcP+akeqBv1tWp3CyBxFPpnQU70ffBk8a20h7DzI2UvNKZ/qci76BX8MOFsVUQE0S+biamDQly8fpQXvkOmHGpEltcDJZfWFS6TR5nIMU1XF8OzA2q3uC5KKlthTb4cxT+hrW7oNEXPkRzV98L25k6JLh9PK5MzA2B/Nw9W1DCJIxBAII8vZ+LtHkR8ZKURHlPkZlNvpJ8m/lm97Dt+4Ff8VQXIL01VM4HU4wnPhSBaApbnKuh5Ku7KAUfp1j2OVGxftPGB4rYMt8bEXuzjt2gEsU24e7kTe9LDZA5QM9LXuGdyXmdFxSCawPAtPDzVHIGUNsxEoV4/FeHq9ASz8yE8KhGZVMKMRZWGVc1sKyh+WXjy7h+DS0E3G0UDFVFNt6zmWtgKqsdY0YpzjdAelZfoljUwPCctLyC36hHeGAdkqAMhgamGCNRy0n2/Nf/2P4cDfIViUXzgbvOoUhVyP+J0KSNOiBF4s7bTjjFWK5RI+NIurqYOj8pYGfacHhgr44SjOcNYNCq+FY+t0sqb4Kp7jy/QAAAABAAVYLjUwOQAAAzYwggMyMIICGqADAgECAgRQ+q1oMA0GCSqGSIb3DQEBCwUAMFsxCzAJBgNVBAYTAkdCMQ4wDAYDVQQIEwVTdGF0ZTENMAsGA1UEBxMEQ2l0eTEMMAoGA1UEChMDT3JnMQswCQYDVQQLEwJPVTESMBAGA1UEAxMJbG9jYWxob3N0MB4XDTEzMDExOTE0Mjc1MloXDTIzMDExNzE0Mjc1MlowWzELMAkGA1UEBhMCR0IxDjAMBgNVBAgTBVN0YXRlMQ0wCwYDVQQHEwRDaXR5MQwwCgYDVQQKEwNPcmcxCzAJBgNVBAsTAk9VMRIwEAYDVQQDEwlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC6ZhwW0JSJvtfocS4vBr2I2FsBGh+FKKzvdqgF7YieBHrb80pDWgWxZEZHaWJEfRd5cA5DCqpGcbtUHLwL4AyxPdKaTtN/CTv9F5R+OuFzWSNxR/hIEnb8lEVQDkMHmdbyG3GWj+oB2rci/pFQGdiVHiVIZHywfXMtRn4ZBWPeTqdTf4TOx2vf48c8GISq2e+Ol578h23vpkihmQLZ6D95zFyL1fTzp+XTJJ0Wu+gkPlehlzZpL58PF5sFJASVZykiflLugY60F39x7xjGPjaAIiSQ6n4g+5rlXL2lFbgHB32Ea9vloFbVSmvGrJnVVGApevy85oujNB5sTYN6rrU1AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAGM7Z1MzO+r77OQR7wBLktdtqE9utS8aVIoaz5xTSjvyJ4lMGW37zNM7wZ+HaB1yPWwssRcA5KtW6pmcHmG6uXFXP02r06fd4SHNkwqJM4EkebVcbTmZvhY7AMrS7WuNx/9y0yZJeRoNKUcPU5fU0xejW30qJ9bzF01II9JvCA/gV/cYyc6iICNqtzKd3dfUKB7JvBBBHf2ci8pugQUH6QvAxt9sn1jvrC1okseTldgNHJIUjxMTSm23w1UdA1feUM10zBrf85dOUwXuVFm/OOJv/JFzgSSO0KHPQCLRh2/qABYutGDjRJwsMWjYVcZEA1eI8EGS9l6iF0CgVqWcBeqsT05vRRMcx20GL0ctWOSyp6T7qQ==', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tsrtN7IRRFWXuv8CrtIZXg', 'server.truststore', 'Cert', 4, FALSE, 'The server.truststore', '/u3+7QAAAAIAAAABAAAAAgA0Y249dGVzdCBjbGllbnQsIG91PW91LCBvPW9yZywgbD1jaXR5LCBzdD1zdGF0ZSwgYz1nYgAAAT0DPg0zAAVYLjUwOQAAAzowggM2MIICHqADAgECAgRQ+q3AMA0GCSqGSIb3DQEBCwUAMF0xCzAJBgNVBAYTAkdCMQ4wDAYDVQQIEwVTdGF0ZTENMAsGA1UEBxMEQ2l0eTEMMAoGA1UEChMDT3JnMQswCQYDVQQLEwJPVTEUMBIGA1UEAxMLVGVzdCBDbGllbnQwHhcNMTMwMTE5MTQyOTIwWhcNMjMwMTE3MTQyOTIwWjBdMQswCQYDVQQGEwJHQjEOMAwGA1UECBMFU3RhdGUxDTALBgNVBAcTBENpdHkxDDAKBgNVBAoTA09yZzELMAkGA1UECxMCT1UxFDASBgNVBAMTC1Rlc3QgQ2xpZW50MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAgVzFyfUziGaCgffeDelK7SQfIPfjlezcmTbfEDxi/EnFR5hF5mj3g9x+LqeTLaaFHj7Aajz4JkAw7f+SrF8FwFj80hstm0QpD6wAFlz/ZKpzXDWvZXhOzGJtEsOl7FsP35LtosCFNOk7AEUki/d5BTaPP5fhFVczvfM9EDVqh+rGXl5T8/wWP6nQlTM0FC/F34WLOvM9hSRElIwhk8IFrHW5GAny7QvkNDoDFd746BMIn+CEPKz1nAuEEdk15q/z+KHa3DB3jlGiQDDWHnXX4oopwnIGkR8fKsV6VgN5xSQLRimGU9XvNNaucHEkS2ssrJ4o76gf6u9RMJ7E7TsMzQIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQBckRCuLlVTQvL99PCE4bg69Bi2KHAJUDCB6/4Yrr+hv8NZHezTFhWmYCz6fNoWOqIcvxgMza7gaezm7t5jT57J+r6NLC8SOF+ZYbdxgNM29s464bhOtc5voBSupIvGboDsro+GMGiKk1QUs7KJY0J+tGIUwGAke8tlzK/QhlBcvOKZ+CjqtlGmZdHzl2rnRRhoU4vHDaSqSdxTxQKjTgzisvV/ZPhcdpd222Z1/cRnmmhusA0pQxdXv2KEX0tgf7KtzrTalUuwGxEta9VFqDKY/zDqEaAyfJMCBWYEhQLsU2IQrIjD3+2lWh8g0s74qGvSRUO0Zl73EdZJLgN01x1QZQU8pbpjPiQevlNB5DdBopiLi2g=', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'client', 'Module', 'com.networknt.client.Http2Client', 'The configuration for client.yml using which com.networknt.client.Http2Client can be configured.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'connectionExpireTime', 'Config', 1, FALSE, 'Connection expire time when connection pool is used. By default, the cached connection will be closed after 30 minutes. This is one way to force the connection to be closed so that the client-side discovery can be balanced.', 1800000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'connectionPoolSize', 'Config', 2, FALSE, 'the maximum host capacity of connection pool', 1000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'defaultCertPassword', 'Config', 3, FALSE, 'public issued CA cert  password', 'changeit', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'derefClientId', 'Config', 4, FALSE, 'client_id used to access key distribution service. It can be the same client_id with token service or not.', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'derefClientSecret', 'Config', 5, FALSE, 'client_secret for deref', 'f6h1FTI8Q3-7UScPZDzfXA', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'derefEnableHttp2', 'Config', 6, FALSE, 'set to true if the oauth2 provider supports HTTP/2', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'derefProxyHost', 'Config', 7, FALSE, 'For users who leverage SaaS OAuth 2.0 provider in the public cloud and has an internal proxy server to access code, token and key services of OAuth 2.0, set up the proxyHost here for the HTTPS traffic. This option is only working with server_url and serviceId below should be commented out. OAuth 2.0 services cannot be discovered if a proxy is used.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'derefProxyPort', 'Config', 8, FALSE, 'We only support HTTPS traffic for the proxy and the default port is 443. If your proxy server has a different port, please specify it here. If proxyHost is available and proxyPort is missing, then the default value 443 is going to be used for the HTTP connection.', NULL, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'derefServerUrl', 'Config', 9, FALSE, 'Token service server url, this might be different than the above token server url. The static url will be used if it is configured.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'derefServiceId', 'Config', 10, FALSE, 'token service unique id for OAuth 2.0 provider. Need for service lookup/discovery. It will be used if above server_url is not configured.', 'com.networknt.oauth2-token-1.0.0', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'derefUri', 'Config', 11, FALSE, 'the path for the key distribution endpoint', '/oauth2/deref', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'earlyRefreshRetryDelay', 'Config', 12, FALSE, 'if scope token is not expired but in renew window, we need slow retry delay.', 4000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'enableHttp2', 'Config', 13, FALSE, 'the flag to indicate whether http/2 is enabled when calling client.callService()', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'errorThreshold', 'Config', 14, FALSE, 'number of timeouts/errors to break the circuit', 2, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'expiredRefreshRetryDelay', 'Config', 15, FALSE, 'if scope token is expired, we need short delay so that we can retry faster.', 2000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'injectCallerId', 'Config', 16, FALSE, 'inject serviceId as callerId into the http header for metrics to collect the caller. The serviceId is from server.yml', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'injectOpenTracing', 'Config', 17, FALSE, 'if open tracing is enabled. traceability, correlation and metrics should not be in the chain if opentracing is used.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'keyPass', 'Config', 18, FALSE, 'private key password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'keyStore', 'Config', 19, FALSE, 'key store location', 'client.keystore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'keyStorePass', 'Config', 20, FALSE, 'key store password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'loadDefaultTrustStore', 'Config', 21, FALSE, 'indicate of system load default cert.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'loadKeyStore', 'Config', 22, FALSE, 'key store contains client key and it should be loaded if two-way ssl is used.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'loadTrustStore', 'Config', 23, FALSE, 'trust store contains certificates that server needs. Enable if tls is used.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'maxConnectionNumPerHost', 'Config', 24, FALSE, 'maximum quantity of connection in connection pool for each host', 1000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'maxReqPerConn', 'Config', 25, FALSE, 'The maximum request limitation for each connection in the connection pool. By default, a connection will be closed after sending 1 million requests. This is one way to force the client-side discovery to re-balance the connections.', 1000000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'minConnectionNumPerHost', 'Config', 26, FALSE, 'minimum quantity of connection in connection pool for each host. The corresponding connection number will shrink to minConnectionNumPerHost by remove least recently used connections when the connection number of a host reach 0.75 * maxConnectionNumPerHost.', 250, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'multipleAuthServers', 'Config', 27, FALSE, 'If there are multiple oauth providers per serviceId, then we need to update this flag to true. In order to derive the serviceId from the path prefix, we need to set up the pathPrefixServices below if there is no duplicated paths between services.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'pathPrefixServices', 'Config', 28, TRUE, 'If you have multiple OAuth 2.0 providers and use path prefix to decide which OAuth 2.0 server to get the token or JWK. If two or more services have the same path, you must use serviceId in the request header to use the serviceId to find the OAuth 2.0 provider configuration. Example value format [/some/path: serviceId]', NULL, 'map', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'resetTimeout', 'Config', 29, FALSE, 'reset the circuit after this timeout in millisecond', 7000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signClientId', 'Config', 30, FALSE, 'client_id for client authentication', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signClientSecret', 'Config', 31, FALSE, 'client secret for client authentication and it can be encrypted here.', 'f6h1FTI8Q3-7UScPZDzfXA', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signEnableHttp2', 'Config', 32, FALSE, 'set to true if the oauth2 provider supports HTTP/2', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signKeyClientId', 'Config', 33, FALSE, 'client_id used to access key distribution service. It can be the same client_id with token service or not.', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signKeyClientSecret', 'Config', 34, FALSE, 'client secret used to access the key distribution service.', 'f6h1FTI8Q3-7UScPZDzfXA', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signKeyEnableHttp2', 'Config', 35, FALSE, 'set to true if the oauth2 provider supports HTTP/2', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signKeyServiceId', 'Config', 36, FALSE, 'the unique service id for key distribution service, it will be used to lookup key service if above url doesn''t exist.', 'com.networknt.oauth2-key-1.0.0', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signKeyUri', 'Config', 37, FALSE, 'the path for the key distribution endpoint', '/oauth2/key', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signProxyHost', 'Config', 38, FALSE, 'For users who leverage SaaS OAuth 2.0 provider from lightapi.net or others in the public cloud and has an internal proxy server to access code, token and key services of OAuth 2.0, set up the proxyHost here for the HTTPS traffic. This option is only working with server_url and serviceId below should be commented out. OAuth 2.0 services cannot be discovered if a proxy server is used.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signProxyPort', 'Config', 39, FALSE, 'We only support HTTPS traffic for the proxy and the default port is 443. If your proxy server has a different port, please specify it here. If proxyHost is available and proxyPort is missing, then the default value 443 is going to be used for the HTTP connection.', NULL, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signServerUrl', 'Config', 40, FALSE, 'token server url. The default port number for token service is 6882. If this url exists, it will be used. if it is not set, then a service lookup against serviceId will be taken to discover an instance.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signServiceId', 'Config', 41, FALSE, 'token serviceId. If server_url doesn''t exist, the serviceId will be used to lookup the token service.', 'com.networknt.oauth2-token-1.0.0', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signTimeout', 'Config', 42, FALSE, 'timeout in milliseconds', 2000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signUri', 'Config', 43, FALSE, 'signing endpoint for the sign request', '/oauth2/token', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'signKeyAudience', 'Config', 44, FALSE, 'audience for the token validation. It is optional and if it is not configured, no audience validation will be executed.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'timeout', 'Config', 45, FALSE, 'timeout in millisecond to indicate a client error.', 3000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tlsVersion', 'Config', 46, FALSE, 'TLS version. Default is TSLv1.2, and you can downgrade to TLSv1 to support some internal old servers that support only TLSv1.1(deprecated and risky). You can also upgrade to TSLv1.3 for maximum security if all your servers support it.', 'TLSv1.2', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenAcClientId', 'Config', 47, FALSE, 'client_id for authorization code grant flow.', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenAcClientSecret', 'Config', 48, FALSE, 'client_secret for authorization code grant flow.', 'f6h1FTI8Q3-7UScPZDzfXA', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenAcRedirectUri', 'Config', 49, FALSE, 'the web server uri that will receive the redirected authorization code', 'https://localhost:3000/authorization', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenAcScope', 'Config', 50, FALSE, 'optional scope, default scope in the client registration will be used if not defined. If there are scopes specified here, they will be verified against the registered scopes. In values.yml, you define a list of strings for the scope(s).', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenAcUri', 'Config', 51, FALSE, 'token endpoint for authorization code grant', '/oauth2/token', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenCcClientId', 'Config', 52, FALSE, 'client_id for client credentials grant flow.', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenCcClientSecret', 'Config', 53, FALSE, 'client_secret for client credentials grant flow.', 'f6h1FTI8Q3-7UScPZDzfXA', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenCcScope', 'Config', 54, FALSE, 'optional scope, default scope in the client registration will be used if not defined. If there are scopes specified here, they will be verified against the registered scopes. In values.yml, you define a list of strings for the scope(s).', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenCcServiceIdAuthServers', 'Config', 55, FALSE, 'The serviceId to the service specific OAuth 2.0 configuration. Used only when multipleOAuthServer is set as true. For detailed config options, please see the values.yml in the client module test.', NULL, 'map', 'app_api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenCcUri', 'Config', 56, FALSE, 'token endpoint for client credentials grant', '/oauth2/token', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenCacheCapacity', 'Config', 57, FALSE, 'Capacity of caching tokens in the client for downstream API calls.', 200, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenEnableHttp2', 'Config', 58, FALSE, 'set to true if the oauth2 provider supports HTTP/2', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenKeyAudience', 'Config', 59, FALSE, 'audience for the token validation. It is optional and if it is not configured, no audience validation will be executed.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenKeyClientId', 'Config', 60, FALSE, 'client_id used to access key distribution service. It can be the same client_id with token service or not.', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenKeyClientSecret', 'Config', 61, FALSE, 'client secret used to access the key distribution service.', 'f6h1FTI8Q3-7UScPZDzfXA', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenKeyEnableHttp2', 'Config', 62, FALSE, 'set to true if the oauth2 provider supports HTTP/2', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenKeyServerUrl', 'Config', 63, TRUE, 'key distribution server url for token verification. It will be used if it is configured. If it is not set, a service lookup will be taken with serviceId to find an instance.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenKeyServiceId', 'Config', 64, FALSE, 'key serviceId for key distribution service, it will be used if above server_url is not configured.', 'com.networknt.oauth2-key-1.0.0', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenKeyServiceIdAuthServers', 'Config', 65, FALSE, 'The serviceId to the service specific OAuth 2.0 configuration. Used only when multipleOAuthServer is set as true. For detailed config options, please see the values.yml in the client module test.', NULL, 'map', 'api|app_api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenKeyUri', 'Config', 66, TRUE, 'the path for the key distribution endpoint', '/oauth2/key', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenProxyHost', 'Config', 67, FALSE, 'For users who leverage SaaS OAuth 2.0 provider from lightapi.net or others in the public cloud and has an internal proxy server to access code, token and key services of OAuth 2.0, set up the proxyHost here for the HTTPS traffic. This option is only working with server_url and serviceId below should be commented out. OAuth 2.0 services cannot be discovered if a proxy server is used.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenProxyPort', 'Config', 68, FALSE, 'We only support HTTPS traffic for the proxy and the default port is 443. If your proxy server has a different port, please specify it here. If proxyHost is available and proxyPort is missing, then the default value 443 is going to be used for the HTTP connection.', NULL, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenRenewBeforeExpired', 'Config', 69, FALSE, 'The scope token will be renewed automatically 1 minute before expiry', 60000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenRtClientId', 'Config', 70, FALSE, 'client_id for refresh token grant flow.', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenRtClientSecret', 'Config', 71, FALSE, 'client_secret for refresh token grant flow', 'f6h1FTI8Q3-7UScPZDzfXA', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenRtScope', 'Config', 72, FALSE, 'optional scope, default scope in the client registration will be used if not defined. If there are scopes specified here, they will be verified against the registered scopes. In values.yml, you define a list of strings for the scope(s).', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenRtUri', 'Config', 73, FALSE, 'token endpoint for refresh token grant', '/oauth2/token', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenServerUrl', 'Config', 74, FALSE, 'token server url. The default port number for token service is 6882. If this is set, it will take high priority than serviceId for the direct connection', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'tokenServiceId', 'Config', 75, FALSE, 'token service unique id for OAuth 2.0 provider. If server_url is not set above, a service discovery action will be taken to find an instance of token service.', 'com.networknt.oauth2-token-1.0.0', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'trustStore', 'Config', 76, FALSE, 'trust store location can be specified here or system properties javax.net.ssl.trustStore and password javax.net.ssl.trustStorePassword', 'client.truststore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'trustStorePass', 'Config', 77, FALSE, 'trust store password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('T1hy8MWXS2WnJIQ2e9m5PQ', 'verifyHostname', 'Config', 78, FALSE, 'if the server is using self-signed certificate, this need to be false. If true, you have to use CA signed certificate or load truststore that contains the self-signed certificate.', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('cfklXwrGSyaY5p7DJy5ACA', 'configReload', 'Handler', 'com.networknt.config.reload.handler.ConfigReloadHandler, com.networknt.config.reload.handler.ModuleRegistryGetHandler ', 'The configuration for configreload.yml and used by com.networknt.config.reload.handler.ConfigReloadHandler. This handler is an admin endpoint used to re-load config values from config server on run-time. The endpoint spec will be defined in the openapi-inject-yml. User call the endpoint will re-load the config values runtime without service restart.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('cfklXwrGSyaY5p7DJy5ACA', 'enabled', 'Config', 1, FALSE, 'Indicate if the config reload from config server is enabled or not.', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('6mfSluKPR5WO7KYmqFfLUQ', 'conquest', 'Module', 'com.networknt.rule.conquest.ConquestTokenRequestTransformAction', 'The configuration for conquest.yml used by ConquestHandler and com.networknt.rule.conquest.ConquestTokenRequestTransformAction which is called from the request transform interceptor from the light-gateway to get the conquest planning API access token to put into the Authorization header in order to access the conquest planning APIs. For the original consumer, it might have another token in the Authorization header for the gateway to verify in order to invoke the external service handler. Once the verification is done, the Authorization header will be replaced with the conquest token from the cache or retrieved from the conquest if it is expired or about to expire.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6mfSluKPR5WO7KYmqFfLUQ', 'enabled', 'Config', 1, FALSE, 'Indicate if this handler is enabled or not.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6mfSluKPR5WO7KYmqFfLUQ', 'enableHttp2', 'Config', 2, FALSE, 'If HTTP2 is used to connect to the conquest site.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6mfSluKPR5WO7KYmqFfLUQ', 'pathPrefixAuths', 'Config', 3, FALSE, 'A list of applied request path prefixes and authentication mappings, other requests will skip this handler. Each item will have properties to help get the token from the conquest access token service. For each API or request path prefix, you need to define an item in the list for authentication. Example value format: [{pathPrefix: /conquest, authIssuer: Networknt, authSubject: conquest-public-uat-networknt-jwt-integration, authAudience: app://d5b1cb55-3835-52fc-9ef3-e38d58856396, tokenTtl: 180, tokenUrl: https://networknt-auth.uat.conquest-public.conquestplanning.com/login/oauth2/realms/root/realms/con/realms/uat/access_token}]', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6mfSluKPR5WO7KYmqFfLUQ', 'proxyHost', 'Config', 4, FALSE, 'Proxy Host if calling within the corp network with a gateway like Mcafee gateway.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6mfSluKPR5WO7KYmqFfLUQ', 'proxyPort', 'Config', 5, FALSE, 'Proxy Port if proxy host is used. default value will be 443 which means HTTPS.', NULL, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('25Eh65hIT4yOYT9xBUljBw', 'content', 'Module', 'com.networknt.content.ContentHandler', 'This is a middleware handler that is responsible for setting the default content-type header,  if it is empty. This can be enabled with content.yml config file and the default type in the');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('25Eh65hIT4yOYT9xBUljBw', 'contentType', 'Config', 1, FALSE, 'set the content type of the request', 'application/json', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('25Eh65hIT4yOYT9xBUljBw', 'enabled', 'Config', 2, FALSE, 'enable the content type', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('WsjuWlJkSdCo0l9F3L8npA', 'correlation', 'Handler', 'com.networknt.correlation.CorrelationHandler', ' * config file is application/json');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('WsjuWlJkSdCo0l9F3L8npA', 'autogenCorrelationID', 'Config', 1, FALSE, 'If set to true, it will auto-generate the correlationID if it is not provided in the request', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('WsjuWlJkSdCo0l9F3L8npA', 'enabled', 'Config', 2, FALSE, 'If enabled is true, the handler will be injected into the request and response chain.', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('Qj7QthkcR1eYT1QxgNw3Jw', 'cors', 'Handler', 'com.networknt.cors.CorsHttpHandler', 'Cors Http Handler Configuration used by com.networknt.cors.CorsHttpHandler for CORS headers');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Qj7QthkcR1eYT1QxgNw3Jw', 'allowedMethods', 'Config', 1, FALSE, 'Allowed methods list', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Qj7QthkcR1eYT1QxgNw3Jw', 'allowedOrigins', 'Config', 2, FALSE, 'Allowed origins, you can have multiple and with port if port is not 80 or 443. Wildcard is not supported for security reasons.', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Qj7QthkcR1eYT1QxgNw3Jw', 'enabled', 'Config', 3, FALSE, 'If cors handler is enabled or not', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('cdeaXFVaT9GXv0i40SfPUg', 'decode', 'Handler', 'com.networknt.decode.RequestDecodeHandler', 'unzip request and response');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('cdeaXFVaT9GXv0i40SfPUg', 'enabled', 'Config', 1, FALSE, 'if request decode is enabled', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('cdeaXFVaT9GXv0i40SfPUg', 'decoders', 'Config', 2, FALSE, 'response decode handler for gzip and deflate', '[gzip,deflate]', 'list', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('SdzdYPxiRwKmgKjjX0VZPA', 'deref', 'Handler', 'com.networknt.deref.DerefMiddlewareHandler', 'so that we don''t expose JWT, instead use a SWT and deref to get a JWT');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('SdzdYPxiRwKmgKjjX0VZPA', 'enabled', 'Config', 1, FALSE, 'If deref is enabled or not', 'false', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('beMiLK0mT1arasXnIVpe8w', 'direct-registry', 'Module', 'com.networknt.registry.support.DirectRegistry', 'The configuration for direct-registry.yml. For light-gateway or http-sidecar that needs to reload configuration for the router hosts, you can define the service to hosts mapping in this configuration to overwrite the definition in the service.yml file as part of the parameters. This configuration will only be used if parameters in the service.yml for DirectRegistry is null.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('beMiLK0mT1arasXnIVpe8w', 'directUrls', 'Config', 1, TRUE, 'For light-gateway or http-sidecar that needs to reload configuration for the router hosts, you can define the service to hosts mapping in this configuration to overwrite the definition in the service.yml file as part of the parameters. This configuration will only be used if parameters in the service.yml for DirectRegistry is null. directUrls is the mapping between the serviceId to the hosts separated by comma. If environment tag is used, you can add it to the serviceId separated with a vertical bar |. Example value format: {serviceId: /some/url}', NULL, 'map', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('3xBwhXy0QFuYfoADaSBoNQ', 'encode', 'Handler', 'com.networknt.encode.RequestEncodeHandler', 'zip request and response');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('3xBwhXy0QFuYfoADaSBoNQ', 'enabled', 'Config', 1, FALSE, 'if response encode is enabled', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('3xBwhXy0QFuYfoADaSBoNQ', 'encoders', 'Config', 2, FALSE, 'response encode handler for gzip and deflate', '[gzip,deflate]', 'list', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('w1ZLl8E4QCqzq2Tf1SWNBA', 'epam', 'Module', 'com.networknt.rule.epam.EpamTokenRequestTransformAction', 'The configuration for epam.yml used by EpamTokenRequestTransformAction and com.networknt.rule.conquest.ConquestTokenRequestTransformAction which is called from the request transform interceptor from the light-gateway to get the conquest planning API access token to put into the Authorization header in order to access the conquest planning APIs. For the original consumer, it might have another token in the Authorization header for the gateway to verify in order to invoke the external service handler. Once the verification is done, the Authorization header will be replaced with the conquest token from the cache or retrieved from the conquest if it is expired or about to expire.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('w1ZLl8E4QCqzq2Tf1SWNBA', 'certFilename', 'Config', 1, FALSE, 'Certificate file name. The private key alias is the filename without the extension.', 'epam.jks', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('w1ZLl8E4QCqzq2Tf1SWNBA', 'certPassword', 'Config', 2, FALSE, 'Certificate file password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('w1ZLl8E4QCqzq2Tf1SWNBA', 'enableHttp2', 'Config', 3, FALSE, 'If HTTP2 is used to connect to the epam site.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('w1ZLl8E4QCqzq2Tf1SWNBA', 'pathPrefixAuths', 'Config', 4, FALSE, 'A list of applied request path prefixes and authentication mappings, other requests will skip this handler. Each item will have properties to help get the token from the ePAM token service. For each API or request path prefix, you need to define an item in the list for authentication. Example value format: [{pathPrefix: /epam, clientId: networknt-uat01, scope: ep, tokenTtl: 180, tokenUrl: https://test.epexample.com/auth}]', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('w1ZLl8E4QCqzq2Tf1SWNBA', 'proxyHost', 'Config', 5, FALSE, 'Proxy Host if calling within the corp network with a gateway like Mcafee gateway.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('w1ZLl8E4QCqzq2Tf1SWNBA', 'proxyPort', 'Config', 6, FALSE, 'Proxy Port if proxy host is used. default value will be 443 which means HTTPS.', NULL, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('rAqrmdpXRji3Lj4eFUELJg', 'exception-assault', 'Handler', 'com.networknt.chaos.ExceptionAssaultHandler', 'Light Chaos Monkey Exception Assault Handler Configuration for com.networknt.chaos.ExceptionAssaultHandler');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rAqrmdpXRji3Lj4eFUELJg', 'bypass', 'Config', 1, FALSE, 'Bypass the current chaos monkey middleware handler so that attacks won''t be triggered.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rAqrmdpXRji3Lj4eFUELJg', 'enabled', 'Config', 2, FALSE, 'Enable the handler if set to true so that it will be wired in the handler chain during the startup', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rAqrmdpXRji3Lj4eFUELJg', 'level', 'Config', 3, FALSE, 'How many requests are to be attacked. 1 each request, 5 each 5th request is attacked', 10, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('rZ4wnM6HTUazla5t5N1eRQ', 'externalService', 'Handler', 'com.networknt.proxy.ExternalServiceHandler', 'Configuration for com.networknt.proxy.ExternalServiceHandler to access third party services through proxy/gateway.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rZ4wnM6HTUazla5t5N1eRQ', 'enabled', 'Config', 1, FALSE, 'Enable the handler if set to true so that it will be wired in the handler chain during the startup', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rZ4wnM6HTUazla5t5N1eRQ', 'enableHttp2', 'Config', 2, FALSE, 'If HTTP2 is used to connect to the external service.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rZ4wnM6HTUazla5t5N1eRQ', 'metricsInjection', 'Config', 3, FALSE, 'When ExternalServiceHandler is used in the http-sidecar or light-gateway, it can collect the metrics info for the total response time of the downstream API. With this value injected, users can quickly determine how much time the http-sidecar or light-gateway handlers spend and how much time the downstream API spends, including the network latency. By default, it is false, and metrics will not be collected and injected into the metrics', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rZ4wnM6HTUazla5t5N1eRQ', 'metricsName', 'Config', 4, FALSE, 'When the metrics info is injected into the metrics handler, we need to pass a metric name to it so that the metrics info can be categorized in a tree structure under the name. By default, it is external-response, and users can change it.', 'external-response', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rZ4wnM6HTUazla5t5N1eRQ', 'pathHostMappings', 'Config', 5, FALSE, 'A list of request path to the service host mappings. Other requests will skip this handler. The value is a string with two parts. The first part is the path and the second is the target host the request is finally routed to.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rZ4wnM6HTUazla5t5N1eRQ', 'proxyHost', 'Config', 6, FALSE, 'Proxy Host if calling within the corp network with a gateway like Mcafee gateway.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rZ4wnM6HTUazla5t5N1eRQ', 'proxyPort', 'Config', 7, FALSE, 'Proxy Port if proxy host is used. default value will be 443 which means HTTPS.', NULL, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rZ4wnM6HTUazla5t5N1eRQ', 'urlRewriteRules', 'Config', 8, FALSE, 'URL rewrite rules, each line will have two parts: the regex patten and replace string separated with a space. For details, please refer to the light-router router.yml configuration. Test your rules at https://www.freeformatter.com/java-regex-tester.html', NULL, 'list', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('TPyoHZDiTPuGDBsP2ULkuw', 'handler', 'Module', '(not-applicable)', 'The configuration for handler.yml used by Handler middleware chain configuration.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('TPyoHZDiTPuGDBsP2ULkuw', 'auditOnError', 'Config', 1, FALSE, 'Configuration for the LightHttpHandler. The handler is the base class  for all middleware, server and health handlers set the Status Object in the AUDIT_INFO, for auditing purposes default, if not set:false', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('TPyoHZDiTPuGDBsP2ULkuw', 'auditStackTrace', 'Config', 2, FALSE, 'set the StackTrace in the AUDIT_INFO, for auditing purposes default, if not set:false', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('TPyoHZDiTPuGDBsP2ULkuw', 'basePath', 'Config', 3, FALSE, 'Base Path of the API endpoints', '/', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('TPyoHZDiTPuGDBsP2ULkuw', 'chains.default', 'Config', 4, TRUE, 'Default Chains', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('TPyoHZDiTPuGDBsP2ULkuw', 'enabled', 'Config', 5, FALSE, 'if handler is enabled', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('TPyoHZDiTPuGDBsP2ULkuw', 'handlers', 'Config', 6, TRUE, 'handlers', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('TPyoHZDiTPuGDBsP2ULkuw', 'oauthTokenPath', 'Config', 7, FALSE, 'Generate client credential token', NULL, 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('iTMLMjxoRlKgcWeynTDZPg', 'header', 'Handler', 'com.networknt.header.HeaderHandler', 'The configuration for header.yml used by com.networknt.header.HeaderHandler which is a handler that manipulate request and response headers based on the configuration. Although one header key can support multiple values in HTTP, but it is not supported here. If the key exists during update, the original value will be replaced by the new value. A new feature is added to the handler to manipulate the headers per request path basis to support the light-gateway use cases with multiple downstream APIs.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('iTMLMjxoRlKgcWeynTDZPg', 'enabled', 'Config', 1, TRUE, 'Enable header handler or not. The default to false and it can be enabled in the externalized values.yml file. It is mostly used in the http-sidecar, light-proxy or light-router.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('iTMLMjxoRlKgcWeynTDZPg', 'pathPrefixHeader', 'Config', 2, FALSE, 'requestPath specific header configuration. The entire object is a map with path prefix as the key and request/response like above as the value', NULL, 'map', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('iTMLMjxoRlKgcWeynTDZPg', 'request.remove', 'Config', 3, FALSE, 'Request header manipulation. Remove all the request headers listed here. The value is a list of keys.', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('iTMLMjxoRlKgcWeynTDZPg', 'request.update', 'Config', 4, FALSE, 'Request header manipulation. Add or update the header with key/value pairs. The value is a map of key and value pairs. Although HTTP header supports multiple values per key, it is not supported here.', NULL, 'map', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('iTMLMjxoRlKgcWeynTDZPg', 'response.remove', 'Config', 5, FALSE, 'Response header manipulation. Remove all the response headers listed here. The value is a list of keys.', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('iTMLMjxoRlKgcWeynTDZPg', 'response.update', 'Config', 6, FALSE, 'Response header manipulation. Add or update the header with key/value pairs. The value is a map of key and value pairs. Although HTTP header supports multiple values per key, it is not supported here.', NULL, 'map', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('gSXBYduURlSaLIDbsDqBoQ', 'health', 'Handler', 'com.networknt.health.HealthGetHandler', 'The configuration for health.yml used by com.networknt.health.HealthGetHandler which has a Server health endpoint that can output OK to indicate the server is alive. Normally, it will be use by F5 to check if the server is health before route request to it. Another way to check server health is to ping the ip and port and it is the standard way to check server status for F5. However, the service instance is up and running doesn''t mean it is functioning. This is the reason to provide a this handler to output more information about the server for F5 or maybe in the future for the API marketplace. Note that we only recommend to use F5 as reverse proxy for services with static IP addresses that act like traditional web server. These services will be sitting in DMZ to serve mobile native and browser SPA and aggregate other services in the backend. For services deployed in the cloud dynamically, there is no reverse proxy but using client side service discovery.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('gSXBYduURlSaLIDbsDqBoQ', 'downstreamEnabled', 'Config', 1, FALSE, 'if the health check needs to invoke down streams API. It is false by default.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('gSXBYduURlSaLIDbsDqBoQ', 'downstreamHost', 'Config', 2, FALSE, 'down stream API host. http://localhost is the default when used with http-sidecar and kafka-sidecar.', 'http://localhost:8081', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('gSXBYduURlSaLIDbsDqBoQ', 'downstreamPath', 'Config', 3, FALSE, 'down stream API health check path. This allows the down stream API to have customized path implemented.', '/health', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('gSXBYduURlSaLIDbsDqBoQ', 'enabled', 'Config', 4, FALSE, 'true to enable this middleware handler. By default the health check is enabled.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('gSXBYduURlSaLIDbsDqBoQ', 'timeout', 'Config', 5, FALSE, 'timeout in milliseconds for the health check. If the duration is passed, a failure will return. It is to prevent taking too much time to check subsystems that are not available or timeout. As the health check is used by the control plane for service discovery, by default, one request per ten seconds. The quick response time is very important to not block the control plane.', 2000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('gSXBYduURlSaLIDbsDqBoQ', 'useJson', 'Config', 6, FALSE, 'true to return Json format message. By default, it is false. It will only be changed to true if the monitor tool only support JSON response body.', 'false', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('f0s6u0cZSNWMQCBsNXnR8A', 'info', 'Handler', 'com.networknt.info.ServerInfoGetHandler', 'The configuration for info.yml used by com.networknt.info.ServerInfoGetHandler which has a Server info endpoint that can output environment and component along with configuration. For example, how many components are installed and what is the configuration of each component. For handlers, it is registered when injecting into the handler chain during server startup. For other utilities, it should have a static block to register itself during server startup. Additional info is gathered from environment variable and JVM.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('f0s6u0cZSNWMQCBsNXnR8A', 'enableServerInfo', 'Config', 1, FALSE, 'Indicate if the server info is enable or not.', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('EkDC2IRSRouaSaLNwVLquQ', 'jaeger', 'Handler', 'com.networknt.jaeger.tracing.JaegerHandler', 'Opentracing Jaeger Handler Configuration used by com.networknt.jaeger.tracing.JaegerHandler');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('EkDC2IRSRouaSaLNwVLquQ', 'enabled', 'Config', 1, FALSE, 'Indicate if the Jaeger tracing is enabled or not.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('EkDC2IRSRouaSaLNwVLquQ', 'param', 'Config', 2, FALSE, 'The sampler parameter that can either be an integer, a double, or an integer', 1, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('EkDC2IRSRouaSaLNwVLquQ', 'type', 'Config', 3, FALSE, 'Sampler configuration https://github.com/jaegertracing/jaeger-client-java It can either be const, probabilistic, or ratelimiting', 'const', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'kafka-admin', 'Handler', '(?)', 'The configuration for kafka-admin.yml which is Generic configuration for Kafka Admin Client.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'basic.auth.credentials.source', 'Config', 1, FALSE, '(?)', 'USER_INFO', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'bootstrap.servers', 'Config', 2, FALSE, '(?)', 9092, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'client.rack', 'Config', 3, FALSE, '(?)', 'rack-name', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'metadata.max.age.ms', 'Config', 4, FALSE, 'The default value is 180s and we need to reduce it to 5s for health check accuracy', 5000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'request.timeout.ms', 'Config', 5, FALSE, 'Request timeout in milliseconds. It must be set to a short duration for health check', 200, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'sasl.mechanism', 'Config', 6, FALSE, '(?)', 'PLAIN', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'security.protocol', 'Config', 7, FALSE, 'security configuration for enterprise deployment', 'SASL_SSL', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'ssl.endpoint.identification.algorithm', 'Config', 8, FALSE, '(?)', 'algo-name', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'ssl.truststore.location', 'Config', 9, FALSE, '(?)', '/truststore/kafka.server.truststore.jks', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'ssl.truststore.password', 'Config', 10, FALSE, '(?)', 'changeme', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('LlpSJwTtTOq9koQWGbqDpA', 'username', 'Config', 11, FALSE, 'basic authentication user:pass for the schema registry', 'username', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'kafka-consumer', 'Handler', '(?)', 'The configuration for kafka-consumer.yml which is Generic Kafka Consumer Configuration');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'auditEnabled', 'Config', 1, 'FALSE', 'Indicator if the audit is enabled.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'auditTarget', 'Config', 2, 'FALSE', 'Audit log destination topic or logfile. Default to logfile', 'logfile', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'auditTopic', 'Config', 3, 'FALSE', 'The consumer audit topic name if the auditTarget is topic', 'sidecar-audit', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'backendApiHost', 'Config', 4, 'FALSE', 'Backend API host', 'https://localhost:8444', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'backendApiPath', 'Config', 5, 'FALSE', 'Backend API path', '/kafka/records', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'backendConnectionReset', 'Config', 6, 'FALSE', 'In case of .NET application we realized , under load, response comes back for batch HTTP request however FinACK does not come until keep alive time out occurs and sidecar consumer does not move forward. Hence we are adding this property so that we can explicitly close the connection when we receive the response and not wait for FinAck.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'deadLetterEnabled', 'Config', 7, 'FALSE', 'Indicator if the dead letter topic is enabled.', 'true', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'deadLetterTopicExt', 'Config', 8, 'FALSE', 'The extension of the dead letter queue(topic) that is added to the original topic to form the dead letter topic', '.dlq', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'fetchMinBytes', 'Config', 9, 'FALSE', 'Minimum bytes of records to accumulate before returning a response to a consumer request. Default 10MB', -1, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'instanceTimeoutMs', 'Config', 10, 'FALSE', 'amount of idle time before a consumer instance is automatically destroyed. If you use the ActiveConsumer and do not want to recreate the consumer instance for every request, increase this number to a bigger value. Default to 5 minutes that is in sync with max.poll.interval.ms default value. When this value is increased to a value greater than 5 minutes, the max.poll.interval.ms will be automatically increased as these two values are related although completely different.', 300000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'iteratorBackoffMs', 'Config', 11, 'FALSE', 'Amount of time to backoff when an iterator runs out of date.', 50, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'keyFormat', 'Config', 12, 'FALSE', 'the format of the key optional', 'jsonschema', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'maxConsumerThreads', 'Config', 13, 'FALSE', 'Active Consumer Specific Configuration and the reactive consumer also depends on these properties default max consumer threads to 50.', 50, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'requestMaxBytes', 'Config', 14, 'FALSE', 'maximum number of bytes message keys and values returned. Default to 100*1024', 102400, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'requestTimeoutMs', 'Config', 15, 'FALSE', 'The maximum total time to wait for messages for a request if the maximum number of messages hs not yet been reached.', 1000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'serverId', 'Config', 16, 'FALSE', 'a unique id for the server instance, if running in a Kubernetes cluster, use the container id environment variable', 'id', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'topic', 'Config', 17, 'FALSE', 'The topic that is going to be consumed. For reactive consumer only in the kafka-sidecar. If two or more topics are going to be subscribed, concat them with comma without space.', 'test1', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'useNoWrappingAvro', 'Config', 18, 'FALSE', 'Indicate if the NoWrapping Avro converter is used. This should be used for avro schema with data type in JSON.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'valueFormat', 'Config', 19, 'FALSE', 'the format of the value optional', 'jsonschema', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('V4f0vcgYT8CypvEzi0Qovg', 'waitPeriod', 'Config', 20, 'FALSE', 'Waiting period in millisecond to poll another batch', 100, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('1aROvnBjRKyGT5n41omceQ', 'kafka-ksqldb', 'Handler', '(?)', 'The configuration for kafka-ksqldb.yml which is configuration for ksqlDb');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'auto.offset.reset', 'Config', 1, 'FALSE', 'stream query properties', 'earliest', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'backendPath', 'Config', 2, 'FALSE', 'Backend API path', '/kafka/ksqldb', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'backendUrl', 'Config', 3, 'FALSE', 'Backend API host', 'https://localhost:8080', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'initialStreams', 'Config', 4, 'FALSE', 'create streams for ksqldb process. Example value format: ["CREATE STREAM TEST_STREAM (userId VARCHAR KEY) WITH (kafka_topic = , value_format = );"]', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'initialTables', 'Config', 5, 'FALSE', 'create tables/materialized views  for ksqldb process. Example value format: ["CREATE STREAM TEST_STREAM (userId VARCHAR KEY) WITH (kafka_topic = , value_format = );"]', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'ksqldbHost', 'Config', 6, 'FALSE', 'ksqlDB host', 'localhost', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'ksqldbPort', 'Config', 7, 'FALSE', 'ksqlDB port', '8088', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'query', 'Config', 8, 'FALSE', 'Run a push query over the stream on ksqldb. It can be a table or stream.', 'SELECT * from TEST_STREAM EMIT CHANGES;', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'trustStore', 'Config', 9, 'FALSE', 'ksqlDB ssl truststore location', '/truststore/kafka.server.truststore.jks', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'trustStorePassword', 'Config', 10, 'FALSE', 'ksqlDB ssl truststore Password', 'changeme', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'username', 'Config', 11, 'FALSE', 'ksqlDB basic Authentication Credentials username', 'userId', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1aROvnBjRKyGT5n41omceQ', 'useTls', 'Config', 12, 'FALSE', 'ksqlDB use tls or not. For local environment, default set as false. For enterprise kafka, please change to use true', 'false', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'kafka-producer', 'Handler', '(?)', 'The configuration for kafka-producer.yml which is Generic Kafka Producer Configuration');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'acks', 'Config', 1, 'FALSE', 'This value is a string, if using 1 or 0, you must use ''1'' or ''0'' as the value', 'all', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'auditEnabled', 'Config', 2, 'FALSE', 'Indicator if the audit is enabled.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'auditTarget', 'Config', 3, 'FALSE', 'Audit log destination topic or logfile. Default to topic', 'logfile', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'auditTopic', 'Config', 4, 'FALSE', 'The consumer audit topic name if the auditTarget is topic', 'sidecar-audit', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'basic.auth.credentials.source', 'Config', 5, 'FALSE', NULL, 'USER_INFO', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'batch.size', 'Config', 6, 'FALSE', '(?)', 16384, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'bootstrap.servers', 'Config', 7, 'FALSE', '(?)', 'localhost:9092', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'buffer.memory', 'Config', 8, 'FALSE', '(?)', 33554432, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'client.rack', 'Config', 9, 'FALSE', NULL, 'rack-name', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'enable.idempotence', 'Config', 10, 'FALSE', '(?)', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'injectCallerId', 'Config', 11, 'FALSE', 'Inject serviceId as callerId into the http header for metrics to collect the caller. The serviceId is from server.yml', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'injectOpenTracing', 'Config', 12, 'FALSE', 'If open tracing is enabled. traceability, correlation and metrics should not be in the chain if opentracing is used.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'keyFormat', 'Config', 13, 'FALSE', 'Default key format if no schema for the topic key', 'jsonschema', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'linger.ms', 'Config', 14, 'FALSE', '(?)', 1, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'max.in.flight.requests.per.connection', 'Config', 15, 'FALSE', '(?)', 5, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'max.request.size', 'Config', 16, 'FALSE', 'If you have a message that is bigger than 1 MB to produce, increase this value.', 1048576, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'retries', 'Config', 17, 'FALSE', '(?)', 3, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'sasl.mechanism', 'Config', 18, 'FALSE', NULL, 'PLAIN', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'schema.registry.auto.register.schemas', 'Config', 19, 'FALSE', 'Schema registry auto register schema indicator for streams application. If true, the first request will register the schema auto automatically.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'schema.registry.cache', 'Config', 20, 'FALSE', 'Schema registry identity cache size', 100, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'schema.registry.ssl.truststore.location', 'Config', 21, 'FALSE', 'Schema registry client truststore location, use the following two properties only if schema registry url is https.', '/config/client.truststore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'schema.registry.ssl.truststore.password', 'Config', 22, 'FALSE', 'Schema registry client truststore password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'schema.registry.url', 'Config', 23, 'FALSE', 'Confluent schema registry url', 'http://localhost:8081', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'security.protocol', 'Config', 24, 'FALSE', 'security configuration for enterprise deployment', 'SASL_SSL', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'ssl.endpoint.identification.algorithm', 'Config', 25, 'FALSE', NULL, 'algo-name', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'ssl.truststore.location', 'Config', 26, 'FALSE', NULL, '/config/client.truststore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'ssl.truststore.password', 'Config', 27, 'FALSE', NULL, 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'topic', 'Config', 28, 'FALSE', 'The default topic for the producer. Only certain producer implementation will use it.', 'test1', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'transaction.timeout.ms', 'Config', 29, 'FALSE', 'The maximum amount of time in ms that the transaction coordinator will wait for a transaction status update from the producer before proactively aborting the ongoing transaction. Default to 1 minute.', 60000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'transactional.id', 'Config', 30, 'FALSE', 'The TransactionalId to use for transactional delivery.', 'T1000', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'transactional.id.expiration.ms', 'Config', 31, 'FALSE', 'The time in ms that the transaction coordinator will wait without receiving any transaction status updates for the current transaction before expiring its transactional id. Default to 7 days.', 604800000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'username', 'Config', 32, 'FALSE', 'basic authentication user:pass for the schema registry', 'username', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('PLPo0SHFSreM6h5w4p3ocQ', 'valueFormat', 'Config', 33, 'FALSE', 'Default value format if no schema for the topic value', 'jsonschema', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'kafka-streams', 'Handler', '(?)', 'The configuration for kafka-streams.yml which is Generic Kafka Streams Configuration');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'application.id', 'Config', 1, 'FALSE', 'A unique application id for the Kafka streams app. You need to replace it or overwrite it in your code.', 'placeholder', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'auditEnabled', 'Config', 2, 'FALSE', 'Indicator if the audit is enabled.', 'true', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'auditTarget', 'Config', 3, 'FALSE', 'Audit log destination topic or logfile. Default to logfile', 'topic', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'auditTopic', 'Config', 4, 'FALSE', 'The consumer audit topic name if the auditTarget is topic', 'sidecar-audit', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'auto.offset.reset', 'Config', 5, 'FALSE', '(?)', 'earliest', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'basic.auth.credentials.source', 'Config', 6, 'FALSE', NULL, 'USER_INFO', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'bootstrap.servers', 'Config', 7, 'FALSE', '(?)', 'localhost:9092', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'cleanUp', 'Config', 8, 'FALSE', 'Only set to true right after the streams reset and start the server. Once the server is up, shutdown and change this to false and restart.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'client.rack', 'Config', 9, 'FALSE', 'Apache Kafka 2.3 clients or later will then read from followers that have matching broker.rack as the specified client.rack ID.', 'rack-name', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'deadLetterEnabled', 'Config', 10, 'FALSE', 'Indicator if the dead letter topic is enabled.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'deadLetterTopicExt', 'Config', 11, 'FALSE', 'The extension of the dead letter queue(topic) that is added to the original topic to form the dead letter topic', '.dlq', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'key.deserializer', 'Config', 12, 'FALSE', '(?)', 'org.apache.kafka.common.serialization.ByteArrayDeserializer', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'sasl.mechanism', 'Config', 13, 'FALSE', NULL, 'PLAIN', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'schema.registry.auto.register.schemas', 'Config', 14, 'FALSE', 'Schema registry auto register schema indicator for streams application. If true, the first request will register the schema auto automatically.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'schema.registry.ssl.truststore.location', 'Config', 15, 'FALSE', 'Schema registry client truststore location, use the following two properties only if schema registry url is https.', '/config/client.truststore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'schema.registry.ssl.truststore.password', 'Config', 16, 'FALSE', 'Schema registry client truststore password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'schema.registry.url', 'Config', 17, 'FALSE', 'Schema registry url', 'http://localhost:8081', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'security.protocol', 'Config', 18, 'FALSE', 'security configuration for enterprise deployment', 'SASL_SSL', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'ssl.endpoint.identification.algorithm', 'Config', 19, 'FALSE', NULL, 'algo-name', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'ssl.truststore.location', 'Config', 20, 'FALSE', NULL, '/config/client.truststore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'ssl.truststore.password', 'Config', 21, 'FALSE', NULL, 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'state.dir', 'Config', 22, 'FALSE', NULL, '/tmp', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'username', 'Config', 23, 'FALSE', 'basic authentication user:pass for the schema registry', 'username', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Cn2pfKJmQF2duAXlioChWw', 'value.deserializer', 'Config', 24, 'FALSE', '(?)', 'org.apache.kafka.common.serialization.ByteArrayDeserializer', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('84HoSDstRyqWbBabL8qX1Q', 'killapp-assault', 'Handler', 'com.networknt.chaos.KillappAssaultHandler', 'Light Chaos Monkey Kill App Assault Handler Configuration used by com.networknt.chaos.KillappAssaultHandler');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('84HoSDstRyqWbBabL8qX1Q', 'bypass', 'Config', 1, FALSE, 'Bypass the current chaos monkey middleware handler so that attacks won''t be triggered.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('84HoSDstRyqWbBabL8qX1Q', 'enabled', 'Config', 2, FALSE, 'Enable the handler if set to true so that it will be wired in the handler chain during the startup', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('84HoSDstRyqWbBabL8qX1Q', 'level', 'Config', 3, FALSE, 'How many requests are to be attacked. 1 each request, 5 each 5th request is attacked', 10, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('W3jGpM96Qc6n2zoXbIy8jA', 'lambda-invoker', 'Handler', 'com.networknt.aws.lambda.LambdaFunctionHandler', 'This configuration is used for LambdaFunctionHandler');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('W3jGpM96Qc6n2zoXbIy8jA', 'region', 'Config', 1, FALSE, 'The aws region that is used to create the LambdaClient', 'us-east-1', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('W3jGpM96Qc6n2zoXbIy8jA', 'endpointOverride', 'Config', 2, FALSE, 'endpoint override if for lambda function deployed in virtual private cloud. Here is an example.
https://vpce-0012C939329d982-tk8ps.lambda.ca-central-1.vpce.amazonaws.com', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('W3jGpM96Qc6n2zoXbIy8jA', 'logType', 'Config', 3, FALSE, 'The LogType of the execution log of Lambda. Set Tail to include and None to not include.', 'Tail', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('W3jGpM96Qc6n2zoXbIy8jA', 'functions', 'Config', 4, FALSE, 'mapping of the endpoints to Lambda functions. Define a list of functions in values.yml file.', NULL, 'map', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('W3jGpM96Qc6n2zoXbIy8jA', 'metricsInjection', 'Config', 5, FALSE, 'When LambdaFunctionHandler is used in the light-gateway, it can collect the metrics info for the total response time of the downstream Lambda functions. With this value injected, users can quickly determine how much time the light-gateway handlers spend and how much time the downstream Lambda function spends,
including the network latency. By default, it is false, and metrics will not be collected and injected into the metrics handler configured in the request/response chain.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('W3jGpM96Qc6n2zoXbIy8jA', 'metricsName', 'Config', 6, FALSE, 'When the metrics info is injected into the metrics handler, we need to pass a metric name to it so that  the metrics info can be categorized in a tree structure under the name. By default, it is lambda-response,
and users can change it.', 'lambda-response', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('U0Mu6RLEQSKpMQqBhM9C3w', 'latency-assault', 'Handler', 'com.networknt.chaos.LatencyAssaultHandler', 'Light Chaos Monkey Latency Assault Handler Configuration used by com.networknt.chaos.LatencyAssaultHandler');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('U0Mu6RLEQSKpMQqBhM9C3w', 'bypass', 'Config', 1, FALSE, 'Bypass the current chaos monkey middleware handler so that attacks won''t be triggered.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('U0Mu6RLEQSKpMQqBhM9C3w', 'enabled', 'Config', 2, FALSE, 'Enable the handler if set to true so that it will be wired in the handler chain during the startup', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('U0Mu6RLEQSKpMQqBhM9C3w', 'latencyRangeEnd', 'Config', 3, FALSE, 'Dynamic latency range end in milliseconds', 3000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('U0Mu6RLEQSKpMQqBhM9C3w', 'latencyRangeStart', 'Config', 4, FALSE, 'Dynamic Latency range start in milliseconds. When start and end are equal, then fixed latency.', 1000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('U0Mu6RLEQSKpMQqBhM9C3w', 'level', 'Config', 5, FALSE, 'How many requests are to be attacked. 1 each request, 5 each 5th request is attacked', 10, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('D3jvbxaQReCkyXcNc8iKTw', 'ldap', 'Module', 'com.networknt.ldap.LdapUtil', 'The configuraton for LDAP which will be used by a utility class that interacts with LDAP server for authentication and authorization.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('D3jvbxaQReCkyXcNc8iKTw', 'credential', 'Config', 1, FALSE, 'The user credential', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('D3jvbxaQReCkyXcNc8iKTw', 'domain', 'Config', 2, FALSE, 'The LDAP domain name', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('D3jvbxaQReCkyXcNc8iKTw', 'principal', 'Config', 3, FALSE, 'The user principal', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('D3jvbxaQReCkyXcNc8iKTw', 'searchBase', 'Config', 4, FALSE, 'The search base', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('D3jvbxaQReCkyXcNc8iKTw', 'searchFilter', 'Config', 5, FALSE, 'The search filter', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('D3jvbxaQReCkyXcNc8iKTw', 'uri', 'Config', 6, FALSE, 'The LDAP server uri', NULL, 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'limit', 'Handler', 'com.networknt.limit.LimitHandler', 'Rate Limit Handler Configuration used by com.networknt.limit.LimitHandler which is a handler which limits the maximum number of concurrent requests. Requests beyond the limit will be queued with limited size of queue. If the queue is full, then request will be dropped.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'address', 'Config', 1, FALSE, 'If address is the key, we can set up different rate limit per address and optional per path or service for certain addresses. All other un-specified addresses will share the limit defined in rateLimit.', NULL, 'map', 'app');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'addressKeyResolver', 'Config', 2, FALSE, 'Ip Address Key Resolver.', 'com.networknt.limit.key.RemoteAddressKeyResolver', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'client', 'Config', 3, FALSE, 'If client is the key, we can set up different rate limit per client and optional per path or service for certain clients. All other un-specified clients will share the limit defined in rateLimit. When client is select, the rate-limit handler must be after the JwtVerifierHandler so that the client_id can be retrieved from the auditInfo attachment.', NULL, 'map', 'app');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'clientIdKeyResolver', 'Config', 4, FALSE, 'Client id Key Resolver.', 'com.networknt.limit.key.JwtClientIdKeyResolver', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'concurrentRequest', 'Config', 5, FALSE, 'Maximum concurrent requests allowed per second on the entire server. This is property is here to keep backward compatible. New users should use the rateLimit property for config with different keys and different time unit.', '2', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'enabled', 'Config', 6, FALSE, 'If this handler is enabled or not. It is disabled by default as this handle might be in most http-sidecar, light-proxy and light-router instances. However, it should only be used internally to throttle request for a slow backend service or externally for DDoS attacks.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'errorCode', 'Config', 7, FALSE, 'If the rate limit is exposed to the Internet to prevent DDoS attacks, it will return 503 error code to trick the DDoS client/tool to stop the attacks as it considers the server is down. However, if the rate limit is used internally to throttle the client requests to protect a slow backend API, it will return 429 error code to indicate too many requests for the client to wait a grace period to resent the request. By default, 503 is returned.', 429, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'key', 'Config', 8, FALSE, 'Key of the rate limit: server, address, client, user server: The entire server has one rate limit key, and it means all users share the same. address: The IP address is the key and each IP will have its rate limit configuration. client: The client id in the JWT token so that we can give rate limit per client. user: The user id in the JWT token so that we can set rate limit and quota based on user.', 'server', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'queueSize', 'Config', 9, FALSE, 'This property is kept to ensure backward compatibility. Please don''t use it anymore. All requests will return the rate limit headers with error messages after the limit is reached.', '-1', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'rateLimit', 'Config', 10, FALSE, 'Default request rate limit 10 requests per second and 10000 quota per day. This is the default for the server shared by all the services. If the key is not server, then the quota is not applicable. 10 requests per second limit and 10000 requests per day quota.', '10/s 10000/d', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'server', 'Config', 11, FALSE, 'If server is the key, we can set up different rate limit per path or service.', NULL, 'map', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'user', 'Config', 12, FALSE, 'If user is the key, we can set up different rate limit per user and optional per path or service for certain users. All other un-specified users will share the limit defined in rateLimit. When user is select, the rate-limit handler must be after the JwtVerifierHandler so that the user_id can be retrieved from the auditInfo attachment.', NULL, 'map', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('6FBJ5u4fTkW4WhdvLQzixQ', 'userIdKeyResolver', 'Config', 13, FALSE, 'User Id Key Resolver.', 'com.networknt.limit.key.JwtUserIdKeyResolver', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('jNBkCFDfSACNlY9xXyw0ww', 'files', 'Module', '(not-applicable)', 'The files needed by Light-4j framework.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('jNBkCFDfSACNlY9xXyw0ww', 'logback.xml', 'File', 1, FALSE, 'The file logback.xml', '(?)', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('jNBkCFDfSACNlY9xXyw0ww', 'rules.yml', 'File', 1, FALSE, 'The file rules.yml', '(?)', 'string', 'none');

INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('jS2ZX6t8QuqwlMfV2mDbNg', 'logging', 'Handler', 'com.networknt.logging.handler.LoggerGetHandler, com.networknt.logging.handler.LoggerGetLogContentsHandler, com.networknt.logging.handler.LoggerGetNameHandler, com.networknt.logging.handler.LoggerPostHandler', 'The configuration for logging.yml used by com.networknt.logging.handler.LoggerGetHandler which will provide all the available logging levels for the all loggers; com.networknt.logging.handler.LoggerGetLogContentsHandler which get logs from the log files based on the input parameters; com.networknt.logging.handler.LoggerGetNameHandler which will provide the logging level for the given Logger and com.networknt.logging.handler.LoggerPostHandler which will change the logging level for the given Logger. Ex. ERROR to DEBUG');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('jS2ZX6t8QuqwlMfV2mDbNg', 'downstreamEnabled', 'Config', 1, FALSE, 'if the logger access needs to invoke down streams API. It is false by default', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('jS2ZX6t8QuqwlMfV2mDbNg', 'downstreamFramework', 'Config', 2, FALSE, 'down stream API framework that has the admin endpoints. Light4j, SpringBoot, Quarkus, Micronaut, Helidon, etc. If the adm endpoints are different between different versions, you can use the framework plus version as the identifier. For example, Light4j-1.6.0, SpringBoot-2.4.0, etc.', 'Light4j', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('jS2ZX6t8QuqwlMfV2mDbNg', 'downstreamHost', 'Config', 3, FALSE, 'down stream API host. http://localhost is the default when used with http-sidecar and kafka-sidecar', 'http://localhost:8081', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('jS2ZX6t8QuqwlMfV2mDbNg', 'enabled', 'Config', 4, FALSE, 'Indicate if the logging info is enable or not.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('jS2ZX6t8QuqwlMfV2mDbNg', 'logStart', 'Config', 5, FALSE, 'Indicate the default time period backward in millisecond for log content retrieve. Default is  hour which indicate system will retrieve one hour log by default', 600000, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('eUGlb9wTSqSNLeB1CHCggQ', 'memory-assault', 'Handler', 'com.networknt.chaos.MemoryAssaultHandler', 'Light Chaos Monkey Memory Assault Handler Configuration used by com.networknt.chaos.MemoryAssaultHandler');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('eUGlb9wTSqSNLeB1CHCggQ', 'bypass', 'Config', 1, FALSE, 'Bypass the current chaos monkey middleware handler so that attacks won''t be triggered.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('eUGlb9wTSqSNLeB1CHCggQ', 'enabled', 'Config', 2, FALSE, 'Enable the handler if set to true so that it will be wired in the handler chain during the startup', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('eUGlb9wTSqSNLeB1CHCggQ', 'level', 'Config', 3, FALSE, 'How many requests are to be attacked. 1 each request, 5 each 5th request is attacked', 10, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('eUGlb9wTSqSNLeB1CHCggQ', 'memoryFillIncrementFraction', 'Config', 4, FALSE, 'Fraction of one individual memory increase iteration. 1.0 equals 100 %. min=0.01, max = 1.0', 0.15, 'float', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('eUGlb9wTSqSNLeB1CHCggQ', 'memoryFillTargetFraction', 'Config', 5, FALSE, 'Final fraction of used memory by assault. 0.95 equals 95 %. min=0.01, max = 0.95', 0.25, 'float', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('eUGlb9wTSqSNLeB1CHCggQ', 'memoryMillisecondsHoldFilledMemory', 'Config', 6, FALSE, 'Duration to assault memory when requested fill amount is reached in ms. min=1500, max=Integer.MAX_VALUE', 90000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('eUGlb9wTSqSNLeB1CHCggQ', 'memoryMillisecondsWaitNextIncrease', 'Config', 7, FALSE, 'Time in ms between increases of memory usage. min=100,max=30000', 1000, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'metrics', 'Handler', 'com.networknt.metrics.MetricsHandler, com.networknt.metrics.APMMetricsHandler', 'The configuration for Metrics which will be used by com.networknt.metrics.AbstractMetricsHandler which is a Metrics middleware handler that can be plugged into the request/response chain to capture metrics information for all services. It is based on the dropwizard metric but customized to capture statistic info for a period of time and then reset all the data in order to capture the next period. The capture period can be configured in metrics.yml and normally should be 5 minutes, 10 minutes or 20 minutes depending on the load of the service. This is the generic implementation and all others will be extended from this handler. This handler will be used by others to inject metrics info if enabled.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'enabled', 'Config', 1, FALSE, 'If metrics handler is enabled or not. Default is true as long as one of the handlers is in the request/response chain.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'enableJVMMonitor', 'Config', 2, FALSE, 'If metrics handler is enabled for JVM MBean or not. If enabled, the CPU and Memory usage will be collected and send to the time series database.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'issuerRegex', 'Config', 3, FALSE, 'If issuer is sent, it might be necessary to extract only partial of the string with a regex pattern. For example, Okta iss is something like: "https://networknt.oktapreview.com/oauth2/aus9xt6dd1cSYyRPH1d6" We only need to extract the last part after the last slash. The following default regex is just for it. The code in the light-4j is trying to extract the matcher.group(1) and there is a junit test to allow users to test their regex. If you are using Okat, you can set metrics.issuerRegex: /([^/]+)$ By default, the regex is empty, and the original iss will be sent as a tag.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'productName', 'Config', 4, FALSE, 'This is the metrics product name for the centralized time series database. The product name will be the top level category under a Kubernetes cluster or a virtual machine. The following is the light-4j product list. http-sidecar, kafka-sidecar, corp-gateway, aiz-gateway, proxy-server, proxy-client, proxy-lambda, light-balancer etc. By default, http-sidecar is used as a placeholder. Please change it based on your usage in the values.yml file.', 'http-sidecar', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'reportInMinutes', 'Config', 5, FALSE, 'report and reset metrics in minutes.', 1, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'sendCallerId', 'Config', 6, FALSE, 'A flag to indicate if the caller id will be sent as a common tag. If it is true, try to retrieve it from the audit info and send it if it is not null. If it doesn''t exist, "unknown" will be sent. By default, this tag is not sent regardless if it is in the audit info. The purpose of this tag is similar to the scopeClientId to identify the immediate caller service in a microservice application. As the scopeClientId is only available when the scope token is used, it cannot be used for all apps. light-4j client module has a config to enforce all services to send the callerId to the downstream API, and it can be enforced within an organization. In most cases, this callerId is more reliable. ', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'sendIssuer', 'Config', 7, FALSE, 'A flag to indicate if the issuer will be sent as a common tag. If it is true, try to retrieve it from the audit info and send it if it is not null. If it doesn''t exist, "unknown" will be sent. By default, this tag is not sent regardless if it is in the audit info. This tag should only be sent if the organization uses multiple OAuth 2.0 providers. For example, Okta will provide multiple virtual instances, so each service can have its private OAuth 2.0 provider. If all services are sharing the same OAuth 2.0 provide (same issuer in the token), this tag should not be used.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'sendScopeClientId', 'Config', 8, FALSE, 'A flag to indicate if the scope client id will be sent as a common tag. If it is true, try to retrieve it from the audit info and send it if it is not null. If it does not exist, "unknown" will be sent. By default, this tag is not sent regardless if it is in the audit info. You only enable this if your API will be accessed by a Mobile or SPA application with authorization code flow. In this case, the primary token is the authorization code token that contains user info and the secondary scope token is the client_credentials token from the immediate caller service in the invocation chain.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'serverHost', 'Config', 9, FALSE, 'Time series database or metrics server hostname.', 'localhost', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'serverName', 'Config', 10, FALSE, 'Time series database name.', 'metrics', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'serverPass', 'Config', 11, FALSE, 'Time series database or metrics server password.', 'admin', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'serverPath', 'Config', 12, FALSE, 'Time series database or metrics server request path. It is optional and only some metrics handlers will use it. For example, the Broadcom APM metrics server needs the path to access the agent.', '/apm/metricFeed', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'serverPort', 'Config', 13, FALSE, 'Time series database or metrics server port number.', 8086, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'serverProtocol', 'Config', 14, FALSE, 'Time series database server protocol. It can be http or https. Others can be added upon request.', 'http', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ssCn2S77QHWw9JcXatt0zw', 'serverUser', 'Config', 15, FALSE, 'Time series database or metrics server user.', 'admin', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'mras', 'Handler', 'com.networknt.proxy.mras.MrasHandler', 'The configuration for mras.yml used by com.networknt.proxy.mras.MrasHandler which is a third party service provider for insurance company. In order to access the service, the authentication flow is a customized one, and we are handling it in this middleware handler. Like the safesforce, we will also invoke the API after the authentication is done in the same context.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'accessToken.cacheEnabled', 'Config', 1, FALSE, 'is cache enabled for the token', NULL, 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'accessToken.gracePeriod', 'Config', 2, FALSE, 'grace period', NULL, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'accessToken.memKey', 'Config', 3, FALSE, 'memory key', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'accessToken.password', 'Config', 4, FALSE, 'password for the authentication', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'accessToken.serviceHost', 'Config', 5, FALSE, 'host for the endpoint', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'accessToken.tokenUrl', 'Config', 6, FALSE, 'MRAS get token URL to send the request', 'https://test.mras.com/services/oauth2/token', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'accessToken.username', 'Config', 7, FALSE, 'username for the authentication', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'anonymous.serviceHost', 'Config', 8, FALSE, 'MRAS target service host for service access with the token get with above property.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'basicAuth.password', 'Config', 9, FALSE, 'password for the authentication', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'basicAuth.serviceHost', 'Config', 10, FALSE, 'host for the endpoint', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'basicAuth.username', 'Config', 11, FALSE, 'username for the authentication', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'enabled', 'Config', 12, FALSE, 'If handler is enabled or not', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'enableHttp2', 'Config', 13, FALSE, 'If HTTP2 is used to connect to the MRAS site.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'keyPass', 'Config', 14, FALSE, 'Key pass', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'keyStoreName', 'Config', 15, FALSE, 'Key store name', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'keyStorePass', 'Config', 16, FALSE, 'Key store password', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'metricsInjection', 'Config', 17, FALSE, 'When MrasHandler is used in the http-sidecar or light-gateway, it can collect the metrics info for the total response time of the downstream API. With this value injected, users can quickly determine how much time the http-sidecar or light-gateway handlers spend and how much time the downstream API spends, including the network latency. By default, it is false, and metrics will not be collected and injected into the metrics handler configured in the request/response chain.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'metricsName', 'Config', 18, FALSE, 'When the metrics info is injected into the metrics handler, we need to pass a metric name to it so that the metrics info can be categorized in a tree structure under the name. By default, it is mras-response, and users can change it.', 'mras-response', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'microsoft.cacheEnabled', 'Config', 19, FALSE, 'is cache enabled for the token', NULL, 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'microsoft.clientId', 'Config', 20, FALSE, 'username for the authentication', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'microsoft.clientSecret', 'Config', 21, FALSE, 'password for the authentication', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'microsoft.gracePeriod', 'Config', 22, FALSE, 'grace period', NULL, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'microsoft.memKey', 'Config', 23, FALSE, 'memory key', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'microsoft.resource', 'Config', 24, FALSE, 'resource for authentication', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'microsoft.serviceHost', 'Config', 25, FALSE, 'host for the endpoint', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'microsoft.tokenUrl', 'Config', 26, FALSE, 'MRAS get token URL to send the request', 'https://test.mras.com/services/oauth2/token', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'pathPrefixAuth', 'Config', 27, FALSE, 'A mappings for prefix auths', NULL, 'map', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'proxyHost', 'Config', 28, FALSE, 'Proxy Host if calling within the corp network with a gateway like Mcafee gateway.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'proxyPort', 'Config', 29, FALSE, 'Proxy Port if proxy host is used. default value will be 443 which means HTTPS.', NULL, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'trustStoreName', 'Config', 30, FALSE, 'Trust store name', 'apigatewayuat.pfx', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'trustStorePass', 'Config', 31, FALSE, 'Trust store password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('MPscIOJKTxO8dY104xLiDQ', 'urlRewriteRules', 'Config', 32, FALSE, 'URL rewrite rules, each line will have two parts: the regex pattern and replace string separated with a space. The light-router has service discovery for host routing, so when working on the url rewrite rules, we only need to create about the path in the URL. Test your rules at https://www.freeformatter.com/java-regex-tester.html', NULL, 'list', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('bdEJGXIFQiKWmXiHYFtkUg', 'oauthServer', 'Handler', 'com.networknt.router.OAuthServerHandler', 'The configuration for oauthServer.yml used by com.networknt.router.OAuthServerHandler which is a handler to simulate other gateway products to allow consumers to get a client credentials token before sending a request with the authorization header. It will return a dummy token to the consumer app so that we don''t need those apps to be modified to avoid the additional cost of migration. When subsequent requests comes in, the header handler will remove the authorization header and the TokenHandler will get a real JWT token from the downstream API authorization server and put it into the Authorization header. This handler is expecting that the RequestBodyInterceptor is used so that we can get the request body in a map structure in the handler.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('bdEJGXIFQiKWmXiHYFtkUg', 'client_credentials', 'Config', 1, FALSE, 'A list of client_id and client_secret concat with a colon. Example [test1:test1pass, test2:test2pass]', NULL, 'list', 'app_api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('bdEJGXIFQiKWmXiHYFtkUg', 'enabled', 'Config', 2, FALSE, 'Enable', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('bdEJGXIFQiKWmXiHYFtkUg', 'getMethodEnabled', 'Config', 3, FALSE, 'getMethodEnabled', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('bdEJGXIFQiKWmXiHYFtkUg', 'passThrough', 'Config', 4, FALSE, 'An indicator to for path through to an OAuth 2.0 server to get a real token.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('bdEJGXIFQiKWmXiHYFtkUg', 'tokenServiceId', 'Config', 5, FALSE, 'If pathThrough is set to true, this is the serviceId that is used in the client.yml configuration as the key to get all the properties to connect to the target OAuth 2.0 provider to get client_credentials access token. The client.yml must be set to true for multipleAuthServers and the token will be verified on the same LPC.', 'light-proxy-client', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('ulLKq53TTKG3n0qN0Tlg1A', 'openapi-handler', 'Handler', 'com.networknt.openapi.OpenApiHandler', 'The configuration for openapi-handler.yml used by com.networknt.openapi.OpenApiHandler which parses the OpenApi object based on uri and method of the request and attached the operation to the request so that security and validator can use it without parsing it. For subsequent handlers like the JwtVerifierHandler and ValidatorHandler, they need to get the basePath and the OpenApiHelper for scope verification and schema validation. Put the helperMap to the exchange for easy sharing.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ulLKq53TTKG3n0qN0Tlg1A', 'ignoreInvalidPath', 'Config', 1, FALSE, 'When the OpenApiHandler is used in a shared gateway and some backend APIs have no specifications deployed on the gateway, the handler will return an invalid request path error to the client. To allow the call to pass through the OpenApiHandler and route to the backend APIs, you can set this flag to true. In this mode, the handler will only add the endpoint specification to the auditInfo if it can find it. Otherwise, it will pass through.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ulLKq53TTKG3n0qN0Tlg1A', 'multipleSpec', 'Config', 2, FALSE, 'This configuration file is used to support multiple OpenAPI specifications in the same light-rest-4j instance. An indicator to allow multiple openapi specifications. Default to false which only allow one spec named openapi.yml or openapi.yaml or openapi.json.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ulLKq53TTKG3n0qN0Tlg1A', 'pathSpecMapping', 'Config', 3, FALSE, 'Path to spec mapping. One or more base paths can map to the same specifications. The key is the base path and the value is the specification name. If users want to use multiple specification files in the same instance, each specification must have a unique base path and it must be set as key.', NULL, 'map', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'openapi-security', 'Handler', 'com.networknt.openapi.JwtVerifyHandler', 'The configuration for openapi-security.yml which is Security configuration for openapi-security in light-rest-4j. It is a specific config for OpenAPI framework security. It is introduced to support multiple frameworks in the same server instance. If this file cannot be found, the generic security.yml will be loaded for backward compatibility. This is used by com.networknt.openapi.JwtVerifyHandler which is a middleware handler that handles security verification for light-rest-4j framework. It verifies token signature and token expiration. And optional scope verification if it is enabled in security.yml config file.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'bootstrapFromKeyService', 'Config', 1, FALSE, 'If you are using light-oauth2, then you don''t need to have oauth subfolder for public key certificate to verify JWT token, the key will be retrieved from key endpoint once the first token is arrived. Default to false for dev environment without oauth2 server or official environment that use other OAuth 2.0 providers.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'certificate', 'Config', 2, FALSE, 'JWT signature public certificates. kid and certificate path mappings.', '100=primary.crt&101=secondary.crt', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'clockSkewInSeconds', 'Config', 3, FALSE, '', '60', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'enableExtractScopeToken', 'Config', 4, FALSE, 'Extract JWT scope token from the X-Scope-Token header and validate the JWT token', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'enableH2c', 'Config', 5, FALSE, 'set true if you want to allow http 1/1 connections to be upgraded to http/2 using the UPGRADE method (h2c). By default this is set to false for security reasons. If you choose to enable it make sure you can handle http/2 w/o tls.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'enableJwtCache', 'Config', 6, FALSE, 'Enable JWT token cache to speed up verification. This will only verify expired time and skip the signature verification as it takes more CPU power and long time.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'enableMockJwt', 'Config', 7, FALSE, 'User for test only. should be always be false on official environment.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'enableRelaxedKeyValidation', 'Config', 8, FALSE, 'Enables relaxed verification for jwt. e.g. Disables key length requirements. Should be used in test environments only.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'enableVerifyJwt', 'Config', 9, FALSE, 'Enable the JWT verification flag. The JwtVerifierHandler will skip the JWT token verification if this flag is false. It should only be set to false on the dev environment for testing purposes. If you have some endpoints that want to skip the JWT verification, you can put the request path prefix in skipPathPrefixes.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'enableVerifyJWTScopeToken', 'Config', 10, FALSE, 'Enable JWT scope verification. Only valid when (enableVerifyJwt is true) AND (enableVerifyScope is true)', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'enableVerifyScope', 'Config', 11, FALSE, 'Enable JWT scope verification. Only valid when enableVerifyJwt is true.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'enableVerifySwt', 'Config', 12, FALSE, 'Enable the SWT verification flag. The SwtVerifierHandler will skip the SWT token verification if this flag is false. It should only be set to false on the dev environment for testing purposes. If you have some endpoints that want to skip the SWT verification, you can put the request path prefix in skipPathPrefixes.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'ignoreJwtExpiry', 'Config', 13, FALSE, 'If set true, the JWT verifier handler will pass if the JWT token is expired already. Unless you have a strong reason, please use it only on the dev environment if your OAuth 2 provider doesn''t support long-lived token for dev environment or test automation.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'jwtCacheFullSize', 'Config', 14, FALSE, 'If enableJwtCache is true, then an error message will be shown up in the log if the cache size is bigger than the jwtCacheFullSize. This helps the developers to detect cache problem if many distinct tokens flood the cache in a short period of time. If you see JWT cache exceeds the size limit in logs, you need to turn off the enableJwtCache or increase the cache full size to a bigger number from the default 100.', '100', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'keyResolver', 'Config', 15, FALSE, 'Key distribution server standard: JsonWebKeySet for other OAuth 2.0 provider| X509Certificate for light-oauth2', 'JsonWebKeySet', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'logClientUserScope', 'Config', 16, FALSE, 'Enable or disable client_id, user_id and scope logging.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'logJwtToken', 'Config', 17, FALSE, 'Enable or disable JWT token logging for audit. This is to log the entire token or choose the next option that only logs client_id, user_id and scope.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'passThroughClaims', 'Config', 18, FALSE, 'When light-gateway or http-sidecar is used for security, sometimes, we need to pass some claims from the JWT or SWT to the backend API for further verification or audit. You can select some claims to pass to the backend API with HTTP headers. The format is a map of claim in the token and a header name that the downstream API is expecting. You can use both JSON or YAML format.
When SwtVerifyHandler is used, the claim names are in https://github.com/networknt/light-4j/blob/master/client/src/main/java/com/networknt/client/oauth/TokenInfo.java
When JwtVerifyHandler is used, the claim names is the JwtClaims claimName.', NULL, 'map', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'providerId', 'Config', 19, FALSE, 'Used in light-oauth2 and oauth-kafka key service for federated deployment. Each instance will have a providerId, and it will be part of the kid to allow each instance to get the JWK from other instance based on the providerId in the kid.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'skipPathPrefixes', 'Config', 20, FALSE, 'Define a list of path prefixes to skip the security to ease the configuration for the handler.yml so that users can define some endpoint without security even through it uses the default chain. This is particularly useful in the light-gateway use case as the same instance might be shared with multiple consumers and providers with different security requirement. The format is a list of strings separated with commas or a JSON list in values.yml definition from config server, or you can use yaml format in this file.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'skipVerifyScopeWithoutSpec', 'Config', 21, FALSE, 'Users should only use this flag in a shared light gateway if the backend API specifications are unavailable in the gateway config folder. If this flag is true and the enableVerifyScope is true, the security handler will invoke the scope verification for all endpoints. However, if the endpoint doesn''t have a specification to retrieve the defined scopes, the handler will skip the scope verification.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'swtClientIdHeader', 'Config', 22, FALSE, 'swt clientId header name. When light-gateway is used and the consumer app does not want to save the client secret in the configuration file, it can be passed in the header.', 'swt-client', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8WR8CkL9QJafo7GLGjb3gw', 'swtClientSecretHeader', 'Config', 23, FALSE, 'swt clientSecret header name. When light-gateway is used and the consumer app does not want to save the client secret in the configuration file, it can be passed in the header.', 'swt-secret', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('EVu6rZRYShW1ZnMjznjB9A', 'openapi-validator', 'Handler', 'com.networknt.openapi.ValidatorHandler', 'The configuration for openapi-validator.yml which is used by com.networknt.openapi.ValidatorHandler which is an OpenAPI validator handler that validate request based on the specification. There is only request validator handler on the server side and response validation should be done on the client side only.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('EVu6rZRYShW1ZnMjznjB9A', 'enabled', 'Config', 1, FALSE, 'If handler is enabled or not', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('EVu6rZRYShW1ZnMjznjB9A', 'handleNullableField', 'Config', 2, FALSE, 'When a field is set as nullable in the OpenAPI specification, the schema validator validates that it is nullable however continues with validation against the nullable field, If handleNullableField is set to true && incoming field is nullable && value is field: null --> succeed, If handleNullableField is set to false && incoming field is nullable && value is field: null --> it is up to the type validator using the SchemaValidator to handle it.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('EVu6rZRYShW1ZnMjznjB9A', 'logError', 'Config', 3, FALSE, 'If should log errors', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('EVu6rZRYShW1ZnMjznjB9A', 'skipBodyValidation', 'Config', 4, FALSE, 'Skip body validation set to true if used in light-router, light-proxy and light-spring-boot.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('EVu6rZRYShW1ZnMjznjB9A', 'skipPathPrefixes', 'Config', 5, FALSE, 'Define a list of path prefixes to skip the validation to ease the configuration for the handler.yml so that users can define some endpoints without validation even through it uses the default chain. This is particularly useful in the light-gateway use case as the same instance might be shared with multiple consumers and providers with different validation requirement.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('EVu6rZRYShW1ZnMjznjB9A', 'validateResponse', 'Config', 6, FALSE, 'Enable response validation.', 'false', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('7xQ3hA2VSximSFj8vTObmg', 'pathPrefixService', 'Handler', 'com.networknt.router.middleware.PathPrefixServiceHandler', 'The configuration for pathPrefixService.yml used by com.networknt.router.middleware.PathPrefixServiceHandler. When using router, each request must have serviceId in the header in order to allow router to do the service discovery before invoke downstream service. The reason we have to do that is due to the unpredictable path between services. If you are sure that all the downstream services can be identified by a unique path prefix, then you can use this Path to ServiceId mapper handler to uniquely identify the serviceId and put it into the header. In this case, the client can invoke the service just the same way it is invoking the service directly. This is the simplest mapping with the prefix and all APIs behind the http-sidecar or light-router should have a unique prefix. All the services of light-router is following this convention.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('7xQ3hA2VSximSFj8vTObmg', 'enabled', 'Config', 1, FALSE, 'If handler is enabled or not', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('7xQ3hA2VSximSFj8vTObmg', 'mapping', 'Config', 2, TRUE, 'mapping from request path prefixes to serviceIds. ', NULL, 'map', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('1cO5XHYaSBuzFOXtyAERqA', 'pathService', 'Handler', 'com.networknt.router.middleware.PathServiceHandler', 'The configuration for pathService.yml used by com.networknt.router.middleware.PathServiceHandler. When using router, each request must have serviceId in the header in order to allow router to do the service discovery before invoke downstream service. The reason we have to do that is due to the unpredictable path between services. If you are sure that all the downstream services can be identified by the path, then you can use this Path to ServiceId mapper handler to uniquely identify the serviceId and put it into the header. In this case, the client can invoke the service just the same way it is invoking the service directly. Please note that you cannot invoke /health or /server/info endpoints as these are the common endpoints injected by the framework and all services will have them on the same path. The router cannot figure out which service you want to invoke so an error message will be returned This handler depends on OpenAPIHandler or SwaggerHandler in light-rest-4j framework. That means this handler only works with RESTful APIs. In rest swagger-meta or openapi-meta, the endpoint of each request is saved into auditInfo object which is attached to the exchange for auditing. This service mapper handler is very similar to the ServiceDictHandler but this one is using the light-rest-4j endpoint in the auditInfo object to do the mapping and the other one is doing the path and method pattern to do the mapping.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1cO5XHYaSBuzFOXtyAERqA', 'enabled', 'Config', 1, FALSE, 'If handler is enabled or not', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('1cO5XHYaSBuzFOXtyAERqA', 'mapping', 'Config', 2, FALSE, 'Mapping from request path prefixes to serviceIds. Example: {/v1/address/{id}@get: party.address-1.0.0, /v2/address@get: party.address-2.0.0}', NULL, 'map', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('iCWdd6qoTbeTtJPR2wJdXg', 'portal', 'Module', 'com.networknt.portal.registry.PortalRegistry', 'The configuration for portal-registry.yml used by com.networknt.portal.registry.PortalRegistry');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('iCWdd6qoTbeTtJPR2wJdXg', 'authorization', 'Config', 1, FALSE, 'Bootstrap jwt token to access the light-controller. In most case, the pipeline will get the token from OAuth 2.0 provider during the deployment. And then pass the token to the container with an environment variable. The other option is to use the light-4j encyptor to encrypt token and put it into the values.yml in the config server. In that case, you can use portalRegistry.portalToken as the key instead of the environment variable.', NULL, 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('vk7Gsl9WTUCsB7B7GZaleg', 'portalRegistry', 'Module', 'com.networknt.portal.registry.PortalRegistry', 'The configuration for portal-registry.yml used by com.networknt.portal.registry.PortalRegistry');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('vk7Gsl9WTUCsB7B7GZaleg', 'checkInterval', 'Config', 1, FALSE, 'health check interval for HTTP check. Or it will be the TTL for TTL check. Every 10 seconds, an HTTP check request will be sent from the light-portal controller. Or if there is no heartbeat TTL request from service after 10 seconds, then mark the service is critical. The value is an integer in milliseconds', '10000', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('vk7Gsl9WTUCsB7B7GZaleg', 'deregisterAfter', 'Config', 2, FALSE, 'De-register the service after the amount of time with health check failed. Once a health check is failed, the service will be put into a critical state. After the deregisterAfter, the service will be removed from discovery. the value is an integer in milliseconds. 1000 means 1 second and default to 2 minutes', '120000', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('vk7Gsl9WTUCsB7B7GZaleg', 'healthPath', 'Config', 3, FALSE, 'The health check path implemented on the server. In most of the cases, it would be /health/ plus the serviceId; however, on a kubernetes cluster, it might be /health/liveness/ in order to differentiate from the /health/readiness/ Note that we need to provide the leading and trailing slash in the path definition.', '/health/', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('vk7Gsl9WTUCsB7B7GZaleg', 'httpCheck', 'Config', 4, FALSE, 'enable health check HTTP. An HTTP get request will be sent to the service to ensure that 200 response status is coming back. This is suitable for service that depending on the database or other infrastructure services. You should implement a customized health check handler that checks dependencies. i.e. if DB is down, return status 400. This is the recommended configuration that allows the light-portal controller to poll the health info from each service.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('vk7Gsl9WTUCsB7B7GZaleg', 'maxReqPerConn', 'Config', 5, FALSE, 'number of requests before resetting the shared connection to work around HTTP/2 limitation', '1000000', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('vk7Gsl9WTUCsB7B7GZaleg', 'portalUrl', 'Config', 6, FALSE, 'Portal URL for accessing controller API. Default to lightapi.net public portal and it can be point to a standalone light-controller instance for testing in the same Kubernetes cluster or docker-compose.', 'https://lightapi.net', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('vk7Gsl9WTUCsB7B7GZaleg', 'ttlCheck', 'Config', 7, FALSE, 'enable health check TTL. When this is enabled, The light-portal controller won''t actively check your service to ensure it is healthy, but your service will call check endpoint with a heartbeat to indicate it is alive. This requires that the service is built on top of light-4j, and the HTTP check is not available. For example, your service is behind NAT. If you are running the service within your internal network and using the SaaS lightapi.net portal, this is the only option as our portal controller cannot access your internal service to perform a health check. We recommend deploying light-portal internally if you are running services within an internal network for efficiency.', 'false', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'proxy', 'Handler', 'com.networknt.proxy.LightProxyHandler', 'The configuration for proxy.yml which is Reverse Proxy Handler Configuration used by com.networknt.proxy.LightProxyHandler which is a wrapper class for LightProxyHandler as it is implemented as final. This class implements the HttpHandler which can be injected into the handler.yml configuration file as another option for the handler injection. The other option is to use RouterHandlerProvider in service.yml file.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'apiId', 'Config', 1, FALSE, 'API-ID to be displayed on error notifications', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'connectionsPerThread', 'Config', 2, FALSE, 'Connections per thread to the target servers', '20', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'forwardJwtClaims', 'Config', 3, FALSE, 'Decode the JWT token claims and forward to the backend api in the form of json string', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'hosts', 'Config', 4, FALSE, 'Target URIs. Use comma separated string for multiple hosts. You can have mix http and https and they will be load balanced. If the host start with https://, then TLS context will be created. ', 'http://localhost:8080', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'http2Enabled', 'Config', 5, FALSE, 'If HTTP 2.0 protocol will be used to connect to target servers. Only if all host are using https and support the HTTP2 can set this one to true. ', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'maxConnectionRetries', 'Config', 6, FALSE, 'Max Connection Retries', '3', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'maxQueueSize', 'Config', 7, FALSE, 'The max queue size for the requests if there is no connection to the downstream API in the connection pool. The default value is 0 that means there is queued requests. As we have maxConnectionRetries, there is no need to use the request queue to increase the memory usage. It should only be used when you see 503 errors in the log after maxConnectionRetries to accommodate slow backend API.', '0', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'maxRequestTime', 'Config', 8, FALSE, 'Max request time in milliseconds before timeout', '1000', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'metricsInjection', 'Config', 9, FALSE, 'When LightProxyHandler is used in the http-sidecar or light-gateway, it can collect the metrics info for the total response time of the downstream API. With this value injected, users can quickly determine how much time the http-sidecar or light-gateway handlers spend and how much time the downstream API spends, including the network latency. By default, it is false, and metrics will not be collected and injected into the metrics handler configured in the request/response chain.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'metricsName', 'Config', 10, FALSE, 'When the metrics info is injected into the metrics handler, we need to pass a metric name to it so that the metrics info can be categorized in a tree structure under the name. By default, it is proxy-response, and users can change it.', 'proxy-response', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'reuseXForwarded', 'Config', 11, FALSE, 'Reuse XForwarded for the target XForwarded header', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JRKadxFASBeQQnYbOHbVHg', 'rewriteHostHeader', 'Config', 12, FALSE, 'Rewrite Host Header with the target host and port and write X_FORWARDED_HOST with original host', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('QJwGFiCNTGSI20FErPinjQ', 'request-injection', 'Handler', 'com.networknt.handler.RequestInterceptorInjectionHandler', 'The configuration for request-injection.yml used by com.networknt.handler.RequestInterceptorInjectionHandler which is used in the request/response chain to inject the implementations of RequestInterceptorHandler interface to modify the request metadata and body. You can have multiple interceptors per application; however, we do provide a generic implementation in request-transform module to transform the request based on the rule engine rules.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('QJwGFiCNTGSI20FErPinjQ', 'appliedBodyInjectionPathPrefixes', 'Config', 1, FALSE, 'A list of applied request path prefixes to which body injection would be done. Injecting the request body and output into the audit log is very heavy operation, and it should only be enabled when necessary or for diagnose session to resolve issues. Please be aware that big request body will only log the beginning part of it in the audit log and gzip encoded request body can not be injected. Even the body injection is not applied, you can still transform the request for headers, query parameters, path parameters etc. Example: [/v1/cats, /v1/dogs]', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('QJwGFiCNTGSI20FErPinjQ', 'enabled', 'Config', 2, FALSE, 'indicate if this interceptor is enabled or not', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('QJwGFiCNTGSI20FErPinjQ', 'maxBuffers', 'Config', 3, FALSE, 'indicates the maxbuffer size of request', 1024, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('JifwmaiZStGjABMjirHulg', 'request-transformer', 'Handler', 'com.networknt.reqtrans.RequestTransformerInterceptor', 'The configuration for request-transformer.yml used by com.networknt.reqtrans.RequestTransformerInterceptor which is used when the handler transforms the request body of an active request being processed. This is executed by RequestInterceptorExecutionHandler.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JifwmaiZStGjABMjirHulg', 'appliedPathPrefixes', 'Config', 1, FALSE, 'A list of applied request path prefixes, other requests will skip this handler. The value can be a string if there is only one request path prefix needs this handler. or a list of strings if there are multiple.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JifwmaiZStGjABMjirHulg', 'enabled', 'Config', 2, FALSE, 'indicate if this interceptor is enabled or not', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JifwmaiZStGjABMjirHulg', 'requiredContent', 'Config', 3, FALSE, 'indicate if the transform interceptor needs to change the request body', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('KPwNLqryRdu0QI1FJPCGaQ', 'response-injection', 'Handler', 'com.networknt.handler.ResponseInterceptorInjectionHandler', 'The configuration for request-ijection.yml used by com.networknt.handler.ResponseInterceptorInjectionHandler which is a generic middleware handler for injecting the SinkConduit in order to update the response content for interceptor handlers to update the response before returning to client.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('KPwNLqryRdu0QI1FJPCGaQ', 'appliedBodyInjectionPathPrefixes', 'Config', 1, FALSE, 'A list of applied body injection path prefixes, other requests will skip this handler. Injecting the response body and output into the audit log is very heavy operation, and it should only be enabled when necessary or for diagnose session to resolve issues. Please be aware that big response body will only log the beginning part of it in the audit log and gzip encoded response body can not be injected. Even the body injection is not applied, you can still transform the response for headers, query parameters, path parameters etc. Example: [/v1/cats, /v1/dogs]', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('KPwNLqryRdu0QI1FJPCGaQ', 'enabled', 'Config', 2, FALSE, 'indicate if this interceptor is enabled or not', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('8ckp5cDKS6651g1WQiZdgQ', 'response-transformer', 'Handler', 'com.networknt.restrans.ResponseTransformerInterceptor', 'The configuration for response-transformer.yml used by com.networknt.restrans.ResponseTransformerInterceptor which is a generic middleware handler to manipulate response based on rule-engine rules so that it can be much more flexible than any other handlers like the header handler to manipulate the headers. The rules will be loaded from the configuration or from the light-portal if portal is implemented.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8ckp5cDKS6651g1WQiZdgQ', 'appliedPathPrefixes', 'Config', 1, FALSE, 'A list of applied request path prefixes, other requests will skip this handler. The value can be a string if there is only one request path prefix needs this handler. or a list of strings if there are multiple.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8ckp5cDKS6651g1WQiZdgQ', 'enabled', 'Config', 2, FALSE, 'indicate if this interceptor is enabled or not', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8ckp5cDKS6651g1WQiZdgQ', 'requiredContent', 'Config', 3, FALSE, 'indicate if the transformer needs to modify the response body in the transform rules', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'router', 'Handler', 'com.networknt.router.RouterHandler', 'The configuration for router.yml used by com.networknt.router.RouterHandler which is a wrapper class for ProxyHandler as it is implemented as final. This class implements the HttpHandler which can be injected into the handler.yml configuration file as another option for the handler injection. The other option is to use RouterHandlerProvider in service.yml file.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'connectionsPerThread', 'Config', 1, FALSE, 'Connections per thread.', 10, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'headerRewriteRules', 'Config', 2, FALSE, 'Header rewrite rules for client applications that send different header keys or values than the target server expecting. When overwriting a value, the key must be specified in order to identify the right header. If only the oldK and newK are specified, the router will rewrite the header key oldK with different key newK and keep the value. The format of the rule will be a map with the path as the key. Example: {/v1/address: [{oldK: oldV, newK: newV}], /v1/pets/{petId}: [{oldK: oldV, newK: newV},{oldK: oldV2, newK: newV2}]}', NULL, 'map', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'hostWhitelist', 'Config', 3, FALSE, 'allowed host list. Use Regex to do wildcard match', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'http2Enabled', 'Config', 4, FALSE, 'As this router is built to support discovery and security for light-4j services, the outbound connection is always HTTP 2.0 with TLS enabled. If HTTP 2.0 protocol will be accepted from incoming request.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'httpsEnabled', 'Config', 5, FALSE, 'If TLS is enabled when accepting incoming request. Should be true on test and prod.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'maxConnectionRetries', 'Config', 6, FALSE, 'Max Connection Retries', 3, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'maxQueueSize', 'Config', 7, FALSE, 'The max queue size for the requests if there is no connection to the downstream API in the connection pool. The default value is 0 that means there is queued requests. As we have maxConnectionRetries, there is no need to use the request queue to increase the memory usage. It should only be used when you see 503 errors in the log after maxConnectionRetries to accommodate slow backend API.', 0, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'maxRequestTime', 'Config', 8, FALSE, 'Max request time in milliseconds before timeout to the server. This is the global setting shared by all backend services if they don''t have service specific timeout.', 1000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'methodRewriteRules', 'Config', 9, FALSE, 'Method rewrite rules for legacy clients that do not support DELETE, PUT, and PATCH HTTP methods to send a request with GET and POST instead. The gateway will rewrite the method from GET to DELETE or from POST to PUT or PATCH. This will be set up at the endpoint level to limit the application. The format of the rule will be endpoint-pattern source-method target-method. The endpoint-pattern is a pattern in OpenAPI specification. Example: [/v2/address POST PUT, /v1/address POST PATCH] Note: you cannot rewrite a method with a body to a method without a body or vice versa.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'metricsInjection', 'Config', 10, FALSE, 'When RouterHandler is used in the http-sidecar or light-gateway, it can collect the metrics info for the total response time of the downstream API. With this value injected, users can quickly determine how much time the http-sidecar or light-gateway handlers spend and how much time the downstream API spends, including the network latency. By default, it is false, and metrics will not be collected and injected into the metrics handler configured in the request/response chain.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'metricsName', 'Config', 11, FALSE, 'When the metrics info is injected into the metrics handler, we need to pass a metric name to it so that the metrics info can be categorized in a tree structure under the name. By default, it is router-response, and users can change it.', 'router-response', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'pathPrefixMaxRequestTime', 'Config', 12, FALSE, 'If a particular downstream service has different timeout than the above global definition, you can add the path prefix and give it another timeout in millisecond. For downstream APIs not defined here, they will use the global timeout defined in router.maxRequestTime. The value is a map with key is the path prefix and value is the timeout. Example: {/v1/address: 5000, /v2/address: 10000, /v3/address: 30000, /v1/pets/{petId}: 5000}', NULL, 'map', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'preResolveFQDN2IP', 'Config', 13, FALSE, 'Pre-resolve FQDN to IP for downstream connections. Default to false in most case, and it should be only used when the downstream FQDN is a load balancer for multiple real API servers.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'queryParamRewriteRules', 'Config', 14, FALSE, 'Query parameter rewrite rules for client applications that send different query parameter keys or values than the target server expecting. When overwriting a value, the key must be specified in order to identify the right query parameter. If only the oldK and newK are specified, the router will rewrite the query parameter key oldK with different key newK and keep the value. The format of the rules will be a map with the path as the key. You can define a list of rules under the same path. Example: {/v1/address: [{oldK: oldV, newK: newV}], /v1/pets/{petId}: [{oldK: oldV, newK: newV},{oldK: oldV2, newK: newV2}]}', NULL, 'map', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'reuseXForwarded', 'Config', 15, FALSE, 'Reuse XForwarded for the target XForwarded header', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'rewriteHostHeader', 'Config', 16, FALSE, 'Rewrite Host Header with the target host and port and write X_FORWARDED_HOST with original host', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'serviceIdQueryParameter', 'Config', 17, FALSE, 'support serviceId in the query parameter for routing to overwrite serviceId in header routing. by default, it is false and should not be used unless you are dealing with a legacy client that does not support header manipulation. Once this flag is true, we are going to overwrite the header service_id derived with other handlers from prefix, path, endpoint etc.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'softMaxConnectionsPerThread', 'Config', 18, FALSE, 'Soft max connections per thread.', 5, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('2eCqYePeT2CUakZAQuIu9A', 'urlRewriteRules', 'Config', 19, FALSE, 'URL rewrite rules, each line will have two parts: the regex patten and replace string separated with a space. The light-router has service discovery for host routing, so whe working on the url rewrite rules, we only need to create about the path in the URL. Test your rules at https://www.freeformatter.com/java-regex-tester.html Example: [/listings/(.*)$ /listing.html?listing=$1, (/tutorial/.*)/wordpress/(\w+)\.?.*$ $1/cms/$2.php]', NULL, 'list', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('rsPrzQGaQ8WLopTq0PF0CA', 'rule-loader', 'Module', 'com.networknt.rule.RuleLoaderStartupHook', 'The configuration for rule-loader.yml used by com.networknt.rule.RuleLoaderStartupHook which is the startup hook to load YAML rules from the light-portal during the server startup.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rsPrzQGaQ8WLopTq0PF0CA', 'enabled', 'Config', 1, FALSE, 'A flag to enable the rule loader to get rules for the service from portal', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rsPrzQGaQ8WLopTq0PF0CA', 'endpointRules', 'Config', 2, FALSE, 'When ruleSource is config-folder, then we can load the endpoint to rules mapping here instead of portal service details. Each endpoint will have a list of rules and the type of the rules.', NULL, 'map', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rsPrzQGaQ8WLopTq0PF0CA', 'portalHost', 'Config', 3, FALSE, 'The portal host with port number if it is not default TLS port 443. Used when ruleSource is light-portal', 'https://localhost', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rsPrzQGaQ8WLopTq0PF0CA', 'portalToken', 'Config', 4, FALSE, 'An authorization token that allows the rule loader to connect to the light-portal. Only used if ruleSource is light-portal.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rsPrzQGaQ8WLopTq0PF0CA', 'ruleSource', 'Config', 5, FALSE, 'Source of the rule. light-portal or config-folder and default to light-portal. If config folder is set, a rules.yml must be in the externalized folder to load rules from it. The config-folder option should only be used for local testing or the light-portal is not implemented in the organization and cloud light-portal is not allowed due to security policy or blocked.', 'light-portal', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'salesforce', 'Handler', 'com.networknt.proxy.salesforce.SalesforceHandler', 'The configuration for salesforce.yml used by com.networknt.proxy.salesforce.SalesforceHandler which is a customized handler for authentication and authorization with cloud Salesforce service within an enterprise environment. It is converted from a customized flow for the business logic. For any external Salesforce request, this handler will check if there is a cached salesforce token that is not expired. If true, put the token into the header. If false, get a new token by following the flow and put it into the header and cache it. The way to get a salesforce token is to sign a token with your private key and salesforce will have the public key to verify your token. Send a request with grant_type and assertion as body to the url defined in the config file. Salesforce will issue an access token for API access. For the token caching, we only cache the salesforce token. The jwt token we created only last 5 minutes, and it is not cached.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'certFilename', 'Config', 1, FALSE, 'Certificate file name', 'apigatewayuat.pfx', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'certPassword', 'Config', 2, FALSE, 'Certificate password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'enabled', 'Config', 3, FALSE, 'indicate if is enabled or not', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'enableHttp2', 'Config', 4, FALSE, 'enable http2 or not', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'metricsInjection', 'Config', 5, FALSE, 'When SalesforceHandler is used in the http-sidecar or light-gateway, it can collect the metrics info for the total response time of the downstream API. With this value injected, users can quickly determine how much time the http-sidecar or light-gateway handlers spend and how much time the downstream API spends, including the network latency. By default, it is false, and metrics will not be collected and injected into the metrics handler configured in the request/response chain.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'metricsName', 'Config', 6, FALSE, 'When the metrics info is injected into the metrics handler, we need to pass a metric name to it so that the metrics info can be categorized in a tree structure under the name. By default, it is router-response, and users can change it.', 'salesforce-response', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'pathPrefixAuths', 'Config', 7, FALSE, 'A list of mappings for prefix auths', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'proxyHost', 'Config', 8, FALSE, 'Proxy host', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'proxyPort', 'Config', 9, FALSE, 'Proxy port', NULL, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('Ow6UbGxEQJepf4HqIUY3vQ', 'urlRewriteRules', 'Config', 10, FALSE, 'URL rewrite rules, each line will have two parts: the regex patten and replace string separated with a space. For details, please refer to the light-router router.yml configuration. Test your rules at https://www.freeformatter.com/java-regex-tester.html', NULL, 'list', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('tDoUa37iR0q72TabRPMTQw', 'sanitizer', 'Handler', 'com.networknt.sanitizer.SanitizerHandler', 'The configuration for sanitizer.yml used by com.networknt.sanitizer.SanitizerHandler which sanitize request for cross site scripting during runtime. This is a middleware component that sanitize cross site scripting tags in request. As potentially sanitizing body of the request, this middleware must be plugged into the chain after body parser. Note: the sanitizer only works with JSON body, for other types, it will be skipped.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tDoUa37iR0q72TabRPMTQw', 'bodyAttributesToEncode', 'Config', 1, FALSE, 'pick up a list of keys to encode the values to limit the scope to only selected keys. You can choose this option if you want to only encode certain fields in the body. When this option is selected, you can not use the bodyAttributesToIgnore list.', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tDoUa37iR0q72TabRPMTQw', 'bodyAttributesToIgnore', 'Config', 2, FALSE, 'pick up a list of keys to ignore the values encoding to skip some of the values so that these values won''t be encoded. You can choose this option if you want to encode everything except several values with a list of the keys. When this option is selected, you can not use the bodyAttributesToEncode list.', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tDoUa37iR0q72TabRPMTQw', 'bodyEnabled', 'Config', 3, FALSE, 'if it is enabled, the body needs to be sanitized', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tDoUa37iR0q72TabRPMTQw', 'bodyEncoder', 'Config', 4, FALSE, 'the encoder for the body. javascript, javascript-attribute, javascript-block or javascript-source There are other encoders that you can choose depending on your requirement. Please refer to site https://github.com/OWASP/owasp-java-encoder/blob/main/core/src/main/java/org/owasp/encoder/Encoders.java', 'javascript-source', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tDoUa37iR0q72TabRPMTQw', 'enabled', 'Config', 5, FALSE, 'indicate if sanitizer is enabled or not', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tDoUa37iR0q72TabRPMTQw', 'headerAttributesToEncode', 'Config', 6, FALSE, 'pick up a list of keys to encode the values to limit the scope to only selected keys. You can choose this option if you want to only encode certain values in the headers. When this option is selected, you can not use the headerAttributesToIgnore list.', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tDoUa37iR0q72TabRPMTQw', 'headerAttributesToIgnore', 'Config', 7, FALSE, 'pick up a list of keys to ignore the values encoding to skip some of the values so that these values won''t be encoded. You can choose this option if you want to encode everything except several values with a list of the keys. When this option is selected, you can not use the headerAttributesToEncode list.', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tDoUa37iR0q72TabRPMTQw', 'headerEnabled', 'Config', 8, FALSE, 'if it is enabled, the header needs to be sanitized', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('tDoUa37iR0q72TabRPMTQw', 'headerEncoder', 'Config', 9, FALSE, 'the encoder for the header. javascript, javascript-attribute, javascript-block or javascript-source There are other encoders that you can choose depending on your requirement. Please refer to site https://github.com/OWASP/owasp-java-encoder/blob/main/core/src/main/java/org/owasp/encoder/Encoders.java', 'javascript-source', 'string', 'none');

INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'server', 'Module', 'com.networknt.server.Server', 'The configuration for server.yml to configure Light4j Server.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'allowUnescapedCharactersInUrl', 'Config', 1, FALSE, 'Flag to set UndertowOptions.ALLOW_UNESCAPED_CHARACTERS_IN_URL. Default to false. Please note that this option widens the attack surface and attacker can potentially access your filesystem. This should only be used on an internal server and never be used on a server accessed from the Internet.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'alwaysSetDate', 'Config', 2, FALSE, 'Flag to set UndertowOptions.ALWAYS_SET_DATE', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'backlog', 'Config', 3, FALSE, 'Backlog size. Default to 10000', 10000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'bootstrapStoreName', 'Config', 4, FALSE, 'Bootstrap truststore name used to connect to the light-config-server if it is used.', 'bootstrap.truststore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'bootstrapStorePass', 'Config', 5, FALSE, 'Bootstrap truststore password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'bufferSize', 'Config', 6, FALSE, 'Buffer size of undertow server. Default to 16K', 16384, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'buildNumber', 'Config', 7, FALSE, 'Build Number, to be set by teams for auditing or tracing purposes.  Allows teams to audit the value and set it according to their release management process', 'latest', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'dynamicPort', 'Config', 8, FALSE, 'Dynamic port is used in situation that multiple services will be deployed on the same host and normally you will have enableRegistry set to true so that other services can find the dynamic port service. When deployed to Kubernetes cluster, the Pod must be annotated as hostNetwork: true', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'enableHttp', 'Config', 9, FALSE, 'Enable HTTP should be false by default. It should be only used for testing with clients or tools that don''t support https or very hard to import the certificate. Otherwise, https should be used. When enableHttp, you must set enableHttps to false, otherwise, this flag will be ignored. There is only one protocol will be used for the server at anytime. If both http and https are true, only https listener will be created and the server will bind to https port only.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'enableHttp2', 'Config', 10, FALSE, 'Http/2 is enabled by default for better performance and it works with the client module Please note that HTTP/2 only works with HTTPS.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'enableHttps', 'Config', 11, FALSE, 'Enable HTTPS should be true on official environment and most dev environments.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'enableRegistry', 'Config', 12, FALSE, 'Flag to enable self service registration. This should be turned on on official test and production. And dyanmicPort should be enabled if any orchestration tool is used like Kubernetes.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'enableTwoWayTls', 'Config', 13, FALSE, 'Flag that indicate if two way TLS is enabled. Not recommended in docker container.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'environment', 'Config', 14, TRUE, 'environment tag that will be registered on consul to support multiple instances per env for testing. https://github.com/networknt/light-doc/blob/master/docs/content/design/env-segregation.md This tag should only be set for testing env, not production. The production certification process will enforce it.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'httpPort', 'Config', 15, FALSE, 'Http port if enableHttp is true. It will be ignored if dynamicPort is true.', 8080, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'httpsPort', 'Config', 16, FALSE, 'Https port if enableHttps is true. It will be ignored if dynamicPort is true.', 8443, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'ioThreads', 'Config', 17, FALSE, 'Number of IO thread. Default to number of processor * 2', 4, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'ip', 'Config', 18, FALSE, 'This is the default binding address if the service is dockerized.', '0.0.0.0', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'keyPass', 'Config', 19, FALSE, 'Private key password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'keystoreName', 'Config', 20, FALSE, 'Keystore file name in config folder.', 'server.keystore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'keystorePass', 'Config', 21, FALSE, 'Keystore password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'maxPort', 'Config', 22, FALSE, 'Maximum port rang. The range can be customized to adopt your network security policy and can be increased or reduced to ease firewall rules.', 2500, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'maxTransferFileSize', 'Config', 23, FALSE, 'Set the max transfer file size for uploading files. Default to 1000000 which is 1 MB.', 1000000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'minPort', 'Config', 24, FALSE, 'Minimum port range. This define a range for the dynamic allocated ports so that it is easier to setup firewall rule to enable this range. Default 2400 to 2500 block has 100 port numbers and should be enough for most cases unless you are using a big bare metal box as Kubernetes node that can run 1000s pods', 2400, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'serverString', 'Config', 25, FALSE, 'Server string used to mark the server. Default to L for light-4j.', 'L', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'serviceId', 'Config', 26, TRUE, 'Unique service identifier. Used in service registration and discovery etc.', 'com.networknt.petstore-1.0.0', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'serviceName', 'Config', 27, FALSE, 'Unique service name. Used in microservice to associate a given name to a service with configuration or as a key within the configuration of a particular domain', 'petstore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'shutdownGracefulPeriod', 'Config', 28, FALSE, 'Shutdown gracefully wait period in milliseconds In this period, it allows the in-flight requests to complete but new requests are not allowed. It needs to be set based on the slowest request possible.', 2000, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'startOnRegistryFailure', 'Config', 29, FALSE, 'When enableRegistry is true and the registry/discovery service is not reachable. Stop the server or continue starting the server. When your global registry is not setup as high availability and only for monitoring, you can set it true. If you are using it for global service discovery, leave it with false.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'truststoreName', 'Config', 30, FALSE, 'Truststore file name in config folder.', 'server.truststore', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'truststorePass', 'Config', 31, FALSE, 'Truststore password', 'password', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'workerThreads', 'Config', 32, FALSE, 'Number of worker threads. Default to 200 and it can be reduced to save memory usage in a container with only one cpu', 200, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('NyluZqUCQ4i2adndN6pQ9w', 'maskConfigProperties', 'Config', 33, FALSE, 'Indicate if the mask for the module registry should be applied or not. Default to true. If all the sensitive properties are encrypted, then this flag can be set to false. This allows the encrypted sensitive properties to show up in the server info response. When config server is used, this flag should be set to false so that the server info response can be automatically compared with the config server generated server info based on the config properties.', 'true', 'boolean', 'none');

INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('gAYFFQcERVmkLfFX9HYDTg', 'service', 'Module', 'com.networknt.service.SingletonServiceFactory', 'The configuration for service.yml to configure services to be created as singletons and wired using IOC injection');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('gAYFFQcERVmkLfFX9HYDTg', 'singletons', 'Config', 1, FALSE, 'Singleton service factory configuration/IoC injection', NULL, 'list', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('cLZTZkVWRsWDsoHc6fOLRg', 'sidecar', 'Handler', 'com.networknt.router.SidecarRouterHandler', 'The configuration for sidecar.yml used by com.networknt.router.SidecarRouterHandler. It uses sidecar.egressIngressIndicator for config to trigger sidecar to router request. If sidecar.egressIngressIndicator is header, then sidecar will lookup header key: service_id/service_url. If sidecar.egressIngressIndicator is protocol, then sidecar will check if protocol is https.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('cLZTZkVWRsWDsoHc6fOLRg', 'egressIngressIndicator', 'Config', 1, FALSE, 'Light http sidecar Configuration. egressIngressIndicator is used to indicator what is the condition used for router traffic in sidecar. If the egressIngressIndicator set as header, sidecar will router request based on if the request header has service id/service url or not. This will be default setting. If the egressIngressIndicator set protocol, sidecar will router request based on protocol. normally the traffic inside pod will http (from api container to sidecar container), and sidecar will treat http traffic as egress router. If the egressIngressIndicator set as other values, currently sidecar will skip router handler and leave the request traffic to proxy', 'header', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('S4IRGjgHREmhWhPhsFK91w', 'snow', 'Module', 'com.networknt.rule.snow.SnowTokenRequestTransformAction', 'It is called from the request transform interceptor from the light-gateway to get the password grant type ServiceNow token to replace the JWT token that consumers use to access the gateway. This allows the ServiceNow API to be exposed on the Gateway as a standard API with client credentials token for API to API invocations');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('S4IRGjgHREmhWhPhsFK91w', 'enableHttp2', 'Config', 1, FALSE, 'If HTTP2 is used to connect to the ServiceNow site.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('S4IRGjgHREmhWhPhsFK91w', 'pathPrefixAuths', 'Config', 2, FALSE, 'A list of applied request path prefixes and authentication mappings, other requests will skip this handler.
Each item will have properties to help get the token from the ServiceNow access token endpoint. For each API or request path prefix, you need to define an item in the list for authentication. This will allow the object to be created and cache the token per path prefix.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('S4IRGjgHREmhWhPhsFK91w', 'proxyHost', 'Config', 3, FALSE, 'Proxy Host if calling within the corp network with a gateway like Mcafee gateway.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('S4IRGjgHREmhWhPhsFK91w', 'proxyPort', 'Config', 4, FALSE, 'Proxy Port if proxy host is used. default value will be 443 which means HTTPS.', NULL, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('ewBNPaLaRZylHO9T3hEWkg', 'specification', 'Handler', 'com.networknt.specification.SpecDisplayHandler', 'The configuration for specification.yml used by com.networknt.specification.SpecDisplayHandler');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ewBNPaLaRZylHO9T3hEWkg', 'contentType', 'Config', 1, FALSE, 'Specification type', 'text/yaml', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('ewBNPaLaRZylHO9T3hEWkg', 'fileName', 'Config', 2, FALSE, 'Specification name', 'openapi.yaml', 'string', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('npqrQMVJRsGHO0uMWT4gQg', 'status', 'Module', 'com.networknt.status.Status', 'This configuration is to configure Status class which is a representation of response.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('npqrQMVJRsGHO0uMWT4gQg', 'showDescription', 'Config', 1, FALSE, 'To control show or hide description field in the following error. Some organizations do not want to expose the error description to allow the hackers to guess how the server is doing with invalid requests.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('npqrQMVJRsGHO0uMWT4gQg', 'showMessage', 'Config', 2, FALSE, 'To control show or hide message field in the following error. Some organizations do not want to expose the error message to allow the hackers to guess how the server is doing with invalid requests.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('npqrQMVJRsGHO0uMWT4gQg', 'showMetadata', 'Config', 3, FALSE, 'To control show or hide metadata field in the error. Light-4j default status code does not have metadata defined as below. However, user defined error could have metadata that is a JSON object. If you do not want to expose the error metadata to allow the hackers to guess how the server is doing with invalid requests, you can turn it off with is flag.', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('e7qZOoS7QKmSjidv9JK3zw', 'tealium', 'Module', 'com.networknt.rule.tealium.TealiumTokenRequestTransformAction', 'This configuraiton is called from the request transform interceptor from the light-gateway to get the Tealium API access token with the configured username and password. The token will then be put into the authorization header to replace the existing one that is used to secure the connection between the consumer to the gateway.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('e7qZOoS7QKmSjidv9JK3zw', 'enableHttp2', 'Config', 1, FALSE, 'If HTTP2 is used to connect to the ServiceNow site.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('e7qZOoS7QKmSjidv9JK3zw', 'pathPrefixAuths', 'Config', 2, FALSE, 'A list of applied request path prefixes and authentication mappings, other requests will skip this handler.
Each item will have properties to help get the token from the ServiceNow access token endpoint. For each API or request path prefix, you need to define an item in the list for authentication. This will allow the object to be created and cache the token per path prefix.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('e7qZOoS7QKmSjidv9JK3zw', 'proxyHost', 'Config', 3, FALSE, 'Proxy Host if calling within the corp network with a gateway like Mcafee gateway.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('e7qZOoS7QKmSjidv9JK3zw', 'proxyPort', 'Config', 4, FALSE, 'Proxy Port if proxy host is used. default value will be 443 which means HTTPS.', NULL, 'integer', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('QKNQwl3wRGGUPlPXAi0rcA', 'token', 'Handler', 'com.networknt.router.middleware.TokenHandler', 'The configuration for token.yml used by com.networknt.router.middleware.TokenHandler which is responsible for getting a client credentials token in http-sidecar and light-gateway when calling others. The configuration for one or multiple OAuth 2.0 providers is in the client.yml file.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('QKNQwl3wRGGUPlPXAi0rcA', 'appliedPathPrefixes', 'Config', 1, FALSE, 'applied path prefixes for the token handler. Only the path prefixes listed here will get the token based on the configuration in the client.yml section. This will allow the share gateway to define only one default chain with some endpoints get the token and others bypass this handler.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('QKNQwl3wRGGUPlPXAi0rcA', 'enabled', 'Config', 2, FALSE, 'indicate if the handler is enabled.', 'false', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('UNGR0unrSvK0FN5HBCRLcw', 'traceability', 'Handler', 'com.networknt.traceability.TraceabilityHandler', 'The configuration for traceability.yml used by com.networknt.traceability.TraceabilityHandler which is a handler that checks if X-Traceability-Id exists in request header and put it into response header if it exists. The traceability-id is set by the consumer and it will be passed to all services and returned to the consumer eventually if there is no error. The AuditHandler will log it in audit log and Client will pass it to the next service. Dependencies: AuditHandler, Client');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('UNGR0unrSvK0FN5HBCRLcw', 'enabled', 'Config', 1, FALSE, 'Indicate if this handler is enabled or not', 'true', 'boolean', 'none');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('uWOMEwlsTjqdRwMVhE218A', 'unified-security', 'Handler', 'com.networknt.openapi.UnifiedSecurityHandler', 'The configuration for unified-security.yml used by com.networknt.openapi.UnifiedSecurityHandler which is a security handler that combines Anonymous, ApiKey, Basic and OAuth together to avoid all of them to be wired in the request/response chain and skip some of them based on the request path. It allows one path to choose several security handlers at the same time. In most cases, this handler will only be used in a shared light-gateway instance.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('uWOMEwlsTjqdRwMVhE218A', 'anonymousPrefixes', 'Config', 1, FALSE, 'Anonymous prefixes configuration. A list of request path prefixes. The anonymous prefixes will be checked first, and if any path is matched, all other security checks will be bypassed, and the request goes to the next handler in the chain.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('uWOMEwlsTjqdRwMVhE218A', 'enabled', 'Config', 2, TRUE, 'indicate if this handler is enabled. By default, it will be enabled if it is injected into the request/response chain in the handler.yml configuration.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('uWOMEwlsTjqdRwMVhE218A', 'pathPrefixAuths', 'Config', 3, TRUE, 'A list of mappings for prefix auths', NULL, 'list', 'api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('D3JiyF1VTwWeHTPvA2EnCw', 'whitelist', 'Handler', 'com.networknt.whitelist.WhitelistHandler', 'The configuration for whitelist.yml used by com.networknt.whitelist.WhitelistHandler which is normally used for the third party integration so that only approved IPs can connect to the light-gateway or http-sidecar at certain endpoints.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('D3JiyF1VTwWeHTPvA2EnCw', 'defaultAllow', 'Config', 1, FALSE, 'Default allowed or denied if there is no rules defined for the path. Default is false so only defined paths with IP ACL rules will be allowed to access. Other paths or other IPs are not allowed to access the service. If this is set to true, then other IPs can access other paths not defined below. However, for the paths defined below, only the listed IPs can access.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('D3JiyF1VTwWeHTPvA2EnCw', 'enabled', 'Config', 2, FALSE, 'Indicate if this handler is enabled or not. It is normally used for the third party integration so that only approved IPs can connect to the light-router or light-proxy at certain endpoints.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('D3JiyF1VTwWeHTPvA2EnCw', 'paths', 'Config', 3, FALSE, 'Map of List of endpoints and their access rules. It supports IPv4 and IPv6 with Exact, Wildcard and Slash format. The endpoint is defined as path@method.', NULL, 'map', 'app_api');
INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('usju5h9QSGex7zzPAPdbwg', 'info', 'Handler', 'com.networknt.info.ServerInfoGetHandler', 'The configuration for info.yml used by com.networknt.info.ServerInfoGetHandler which has a Server info endpoint that can output environment and component along with configuration. For example, how many components are installed and what is the configuration of each component. For handlers, it is registered when injecting into the handler chain during server startup. For other utilities, it should have a static block to register itself during server startup. Additional info is gathered from environment variable and JVM.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('usju5h9QSGex7zzPAPdbwg', 'keysToNotSort', 'Config', 1, FALSE, 'String list keys that should not be sorted in the normalized info output. If you have a list of string values define in one of your config files and the sequence of the values is important, you can add the key to this list. If you want to add your own keys, please make sure that you include the default keys as well.', '[admin, default, defaultHandlers]', 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('usju5h9QSGex7zzPAPdbwg', 'downstreamEnabled', 'Config', 2, FALSE, 'if the server info needs to invoke down streams API. It is false by default.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('usju5h9QSGex7zzPAPdbwg', 'downstreamHost', 'Config', 3, FALSE, 'down stream API host. http://localhost is the default when used with http-sidecar and kafka-sidecar.', 'http://localhost:8081', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('usju5h9QSGex7zzPAPdbwg', 'downstreamPath', 'Config', 4, FALSE, 'down stream API server info path. This allows the down stream API to have customized path implemented.', '/adm/server/info', 'string', 'none');


INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('M3HnTsHAS8Saa5XeSnEeKg', 'token-transformer', 'Module', 'com.networknt.rule.generic.token.TokenTransformerAction', 'The config used by plugin token-transformer. The transformation for token is called from the request interceptor when we make an outbound call to a token provider and attach the token to the request. Each step can be configured to account for different token request flows, different response payloads, and different ways of storing the returned token.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('M3HnTsHAS8Saa5XeSnEeKg', 'enableHttp2', 'Config', 1, FALSE, 'If HTTP2 is used to connect to the specified auth token source.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('M3HnTsHAS8Saa5XeSnEeKg', 'pathPrefixAuths', 'Config', 2, FALSE, 'A list of applied request path prefixes and authentication mappings, other requests will skip this handler. Each item will have properties to help get the token from the tealium access token service. For each API or request path prefix, you need to define an item in the list for authentication. This will allow the object to be created and cache the token per path prefix.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('M3HnTsHAS8Saa5XeSnEeKg', 'proxyHost', 'Config', 3, FALSE, 'Proxy Host if calling within the corp network with a gateway like Mcafee gateway.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('M3HnTsHAS8Saa5XeSnEeKg', 'proxyPort', 'Config', 4, FALSE, 'Proxy Port if proxy host is used. default value will be 443 which means HTTPS.', NULL, 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('M3HnTsHAS8Saa5XeSnEeKg', 'moduleMasks', 'Config', 5, FALSE, 'Masks used in module registry', NULL, 'list', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('M3HnTsHAS8Saa5XeSnEeKg', 'tokenSchemas', 'Config', 1, FALSE, 'A map of token schemas containing information on how to build token outbound request and how to use the token received and so on. This property has a complex structure and the user should read the documentation before / while using this.', NULL, 'map', 'api');


INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('WsjuWlJkSdCo0l9F3L8npA', 'correlationMdcField', 'Config', 1, FALSE, 'The MDC context field name for the correlation id value', 'cId', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('WsjuWlJkSdCo0l9F3L8npA', 'traceabilityMdcField', 'Config', 2, FALSE, 'The MDC context field name for the traceability id value', 'tId', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('JifwmaiZStGjABMjirHulg', 'defaultBodyEncoding', 'Config', 1, FALSE, 'default body encoding for the request body. The default value is UTF-8. Other options are ISO-8859-1 and US-ASCII.', 'UTF-8', 'string', 'none');

INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('8ckp5cDKS6651g1WQiZdgQ', 'defaultBodyEncoding', 'Config', 1, FALSE, 'default body encoding for the response body. The default value is UTF-8. Other options are ISO-8859-1 and US-ASCII.', 'UTF-8', 'string', 'none');

INSERT INTO config_t (config_id, config_name, config_type, class_path, config_desc) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'security', 'Handler', 'com.networknt.openapi.JwtVerifyHandler', 'The configuration for openapi-security.yml which is Security configuration for openapi-security in light-rest-4j. It is a specific config for OpenAPI framework security. It is introduced to support multiple frameworks in the same server instance.');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'bootstrapFromKeyService', 'Config', 1, FALSE, 'If you are using light-oauth2, then you don''t need to have oauth subfolder for public key certificate to verify JWT token, the key will be retrieved from key endpoint once the first token is arrived. Default to false for dev environment without oauth2 server or official environment that use other OAuth 2.0 providers.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'certificate', 'Config', 2, FALSE, 'JWT signature public certificates. kid and certificate path mappings.', '100=primary.crt&101=secondary.crt', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'clockSkewInSeconds', 'Config', 3, FALSE, '', '60', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'enableExtractScopeToken', 'Config', 4, FALSE, 'Extract JWT scope token from the X-Scope-Token header and validate the JWT token', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'enableH2c', 'Config', 5, FALSE, 'set true if you want to allow http 1/1 connections to be upgraded to http/2 using the UPGRADE method (h2c). By default this is set to false for security reasons. If you choose to enable it make sure you can handle http/2 w/o tls.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'enableJwtCache', 'Config', 6, FALSE, 'Enable JWT token cache to speed up verification. This will only verify expired time and skip the signature verification as it takes more CPU power and long time.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'enableMockJwt', 'Config', 7, FALSE, 'User for test only. should be always be false on official environment.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'enableRelaxedKeyValidation', 'Config', 8, FALSE, 'Enables relaxed verification for jwt. e.g. Disables key length requirements. Should be used in test environments only.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'enableVerifyJwt', 'Config', 9, FALSE, 'Enable the JWT verification flag. The JwtVerifierHandler will skip the JWT token verification if this flag is false. It should only be set to false on the dev environment for testing purposes. If you have some endpoints that want to skip the JWT verification, you can put the request path prefix in skipPathPrefixes.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'enableVerifyScope', 'Config', 10, FALSE, 'Enable JWT scope verification. Only valid when enableVerifyJwt is true.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'enableVerifySwt', 'Config', 11, FALSE, 'Enable the SWT verification flag. The SwtVerifierHandler will skip the SWT token verification if this flag is false. It should only be set to false on the dev environment for testing purposes. If you have some endpoints that want to skip the SWT verification, you can put the request path prefix in skipPathPrefixes.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'ignoreJwtExpiry', 'Config', 12, FALSE, 'If set true, the JWT verifier handler will pass if the JWT token is expired already. Unless you have a strong reason, please use it only on the dev environment if your OAuth 2 provider doesn''t support long-lived token for dev environment or test automation.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'jwtCacheFullSize', 'Config', 13, FALSE, 'If enableJwtCache is true, then an error message will be shown up in the log if the cache size is bigger than the jwtCacheFullSize. This helps the developers to detect cache problem if many distinct tokens flood the cache in a short period of time. If you see JWT cache exceeds the size limit in logs, you need to turn off the enableJwtCache or increase the cache full size to a bigger number from the default 100.', '100', 'integer', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'keyResolver', 'Config', 14, FALSE, 'Key distribution server standard: JsonWebKeySet for other OAuth 2.0 provider| X509Certificate for light-oauth2', 'JsonWebKeySet', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'logClientUserScope', 'Config', 15, FALSE, 'Enable or disable client_id, user_id and scope logging.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'logJwtToken', 'Config', 16, FALSE, 'Enable or disable JWT token logging for audit. This is to log the entire token or choose the next option that only logs client_id, user_id and scope.', 'true', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'passThroughClaims', 'Config', 17, FALSE, 'When light-gateway or http-sidecar is used for security, sometimes, we need to pass some claims from the JWT or SWT to the backend API for further verification or audit. You can select some claims to pass to the backend API with HTTP headers. The format is a map of claim in the token and a header name that the downstream API is expecting. You can use both JSON or YAML format.
When SwtVerifyHandler is used, the claim names are in https://github.com/networknt/light-4j/blob/master/client/src/main/java/com/networknt/client/oauth/TokenInfo.java
When JwtVerifyHandler is used, the claim names is the JwtClaims claimName.', NULL, 'map', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'providerId', 'Config', 18, FALSE, 'Used in light-oauth2 and oauth-kafka key service for federated deployment. Each instance will have a providerId, and it will be part of the kid to allow each instance to get the JWK from other instance based on the providerId in the kid.', NULL, 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'skipPathPrefixes', 'Config', 19, FALSE, 'Define a list of path prefixes to skip the security to ease the configuration for the handler.yml so that users can define some endpoint without security even through it uses the default chain. This is particularly useful in the light-gateway use case as the same instance might be shared with multiple consumers and providers with different security requirement. The format is a list of strings separated with commas or a JSON list in values.yml definition from config server, or you can use yaml format in this file.', NULL, 'list', 'api');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'skipVerifyScopeWithoutSpec', 'Config', 20, FALSE, 'Users should only use this flag in a shared light gateway if the backend API specifications are unavailable in the gateway config folder. If this flag is true and the enableVerifyScope is true, the security handler will invoke the scope verification for all endpoints. However, if the endpoint doesn''t have a specification to retrieve the defined scopes, the handler will skip the scope verification.', 'false', 'boolean', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'swtClientIdHeader', 'Config', 21, FALSE, 'swt clientId header name. When light-gateway is used and the consumer app does not want to save the client secret in the configuration file, it can be passed in the header.', 'swt-client', 'string', 'none');
INSERT INTO config_property_t (config_id, property_name, property_type, display_order, required, property_desc, property_value, value_type, resource_type) VALUES ('rbZgBr6sSzyWMrfFKmlcWw', 'swtClientSecretHeader', 'Config', 22, FALSE, 'swt clientSecret header name. When light-gateway is used and the consumer app does not want to save the client secret in the configuration file, it can be passed in the header.', 'swt-secret', 'string', 'none');


CREATE OR REPLACE AGGREGATE jsonb_merge_agg(jsonb) (
    SFUNC = jsonb_concat,
    STYPE = jsonb,
    INITCOND = '{}'
);

CREATE OR REPLACE FUNCTION merge_instance_api_property_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_host_id VARCHAR(22);
    v_instance_id VARCHAR(22);
    v_config_id VARCHAR(22);
    v_property_name VARCHAR(64);
    v_value_type VARCHAR(16);
    v_merged_json JSONB;
BEGIN
    -- Capture affected keys
    IF (TG_OP = 'DELETE') THEN
        v_host_id := OLD.host_id;
        v_instance_id := OLD.instance_id;
        v_config_id := OLD.config_id;
        v_property_name := OLD.property_name;
    ELSE
        v_host_id := NEW.host_id;
        v_instance_id := NEW.instance_id;
        v_config_id := NEW.config_id;
        v_property_name := NEW.property_name;
    END IF;

    -- Retrieve value_type from config_property_t
    SELECT value_type INTO v_value_type
    FROM config_property_t
    WHERE config_id = v_config_id
      AND property_name = v_property_name;

    -- Merge logic for 'map' or 'list'
    IF v_value_type IN ('map', 'list') THEN
        IF v_value_type = 'map' THEN
            -- Merge JSON objects, newer entries overwrite older ones
            SELECT jsonb_merge_agg(property_value::JSONB ORDER BY update_ts DESC)
            INTO v_merged_json
            FROM instance_api_property_t
            WHERE host_id = v_host_id
              AND instance_id = v_instance_id
              AND config_id = v_config_id
              AND property_name = v_property_name;
        ELSE
            -- Aggregate JSON arrays
            SELECT jsonb_agg(element ORDER BY update_ts)
            INTO v_merged_json
            FROM (
                SELECT jsonb_array_elements(property_value::JSONB) AS element, update_ts
                FROM instance_api_property_t
                WHERE host_id = v_host_id
                  AND instance_id = v_instance_id
                  AND config_id = v_config_id
                  AND property_name = v_property_name
                  AND jsonb_typeof(property_value::JSONB) = 'array' -- Filter non-arrays                  
            ) sub;
        END IF;
    ELSE
        -- For non-merge types, take the latest value
        SELECT property_value::JSONB
        INTO v_merged_json
        FROM instance_api_property_t
        WHERE host_id = v_host_id
          AND instance_id = v_instance_id
          AND config_id = v_config_id
          AND property_name = v_property_name
        ORDER BY update_ts DESC
        LIMIT 1;
    END IF;

    -- Upsert or delete in instance_property_t
    IF v_merged_json IS NOT NULL AND v_merged_json != 'null'::JSONB THEN
        INSERT INTO instance_property_t (
            host_id, instance_id, config_id, property_name,
            property_value, update_user, update_ts
        )
        VALUES (
            v_host_id, v_instance_id, v_config_id, v_property_name,
            v_merged_json::TEXT, CURRENT_USER, CURRENT_TIMESTAMP
        )
        ON CONFLICT (host_id, instance_id, config_id, property_name)
        DO UPDATE SET
            property_value = EXCLUDED.property_value,
            update_user = EXCLUDED.update_user,
            update_ts = EXCLUDED.update_ts;
    ELSE
        DELETE FROM instance_property_t
        WHERE host_id = v_host_id
          AND instance_id = v_instance_id
          AND config_id = v_config_id
          AND property_name = v_property_name;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER instance_api_property_merge_trigger
AFTER INSERT OR UPDATE OR DELETE ON instance_api_property_t
FOR EACH ROW EXECUTE FUNCTION merge_instance_api_property_trigger();


CREATE OR REPLACE FUNCTION merge_instance_app_property_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_host_id VARCHAR(22);
    v_instance_id VARCHAR(22);
    v_config_id VARCHAR(22);
    v_property_name VARCHAR(64);
    v_value_type VARCHAR(16);
    v_merged_json JSONB;
BEGIN
    -- Capture affected keys
    IF (TG_OP = 'DELETE') THEN
        v_host_id := OLD.host_id;
        v_instance_id := OLD.instance_id;
        v_config_id := OLD.config_id;
        v_property_name := OLD.property_name;
    ELSE
        v_host_id := NEW.host_id;
        v_instance_id := NEW.instance_id;
        v_config_id := NEW.config_id;
        v_property_name := NEW.property_name;
    END IF;

    -- Retrieve value_type from config_property_t
    SELECT value_type INTO v_value_type
    FROM config_property_t
    WHERE config_id = v_config_id
      AND property_name = v_property_name;

    -- Merge logic for 'map' or 'list'
    IF v_value_type IN ('map', 'list') THEN
        IF v_value_type = 'map' THEN
            -- Merge JSON objects, newer entries overwrite older ones
            SELECT jsonb_merge_agg(property_value::JSONB ORDER BY update_ts DESC)
            INTO v_merged_json
            FROM instance_app_property_t
            WHERE host_id = v_host_id
              AND instance_id = v_instance_id
              AND config_id = v_config_id
              AND property_name = v_property_name;
        ELSE
            -- Aggregate JSON arrays
            SELECT jsonb_agg(element ORDER BY update_ts)
            INTO v_merged_json
            FROM (
                SELECT 
                    jsonb_array_elements(property_value::JSONB) AS element, 
                    update_ts
                FROM instance_app_property_t
                WHERE 
                    host_id = v_host_id
                    AND instance_id = v_instance_id
                    AND config_id = v_config_id
                    AND property_name = v_property_name
                    AND jsonb_typeof(property_value::JSONB) = 'array' -- Filter non-arrays
            ) sub;
        END IF;
    ELSE
        -- For non-merge types, take the latest value
        SELECT property_value::JSONB
        INTO v_merged_json
        FROM instance_app_property_t
        WHERE host_id = v_host_id
          AND instance_id = v_instance_id
          AND config_id = v_config_id
          AND property_name = v_property_name
        ORDER BY update_ts DESC
        LIMIT 1;
    END IF;

    -- Upsert or delete in instance_property_t
    IF v_merged_json IS NOT NULL AND v_merged_json != 'null'::JSONB THEN
        INSERT INTO instance_property_t (
            host_id, instance_id, config_id, property_name,
            property_value, update_user, update_ts
        )
        VALUES (
            v_host_id, v_instance_id, v_config_id, v_property_name,
            v_merged_json::TEXT, CURRENT_USER, CURRENT_TIMESTAMP
        )
        ON CONFLICT (host_id, instance_id, config_id, property_name)
        DO UPDATE SET
            property_value = EXCLUDED.property_value,
            update_user = EXCLUDED.update_user,
            update_ts = EXCLUDED.update_ts;
    ELSE
        DELETE FROM instance_property_t
        WHERE host_id = v_host_id
          AND instance_id = v_instance_id
          AND config_id = v_config_id
          AND property_name = v_property_name;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER instance_app_property_merge_trigger
AFTER INSERT OR UPDATE OR DELETE ON instance_app_property_t
FOR EACH ROW EXECUTE FUNCTION merge_instance_app_property_trigger();


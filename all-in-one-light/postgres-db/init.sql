CREATE DATABASE configserver;
\c configserver;

DROP TABLE IF EXISTS rule_host_t CASCADE;

DROP TABLE IF EXISTS rule_group_host_t CASCADE;

DROP TABLE IF EXISTS rule_group_t CASCADE;

DROP TABLE IF EXISTS rule_t CASCADE;

DROP TABLE IF EXISTS api_endpoint_rule_t CASCADE;

DROP TABLE IF EXISTS api_endpoint_t CASCADE;

DROP TABLE IF EXISTS api_platform_instance_t CASCADE;

DROP TABLE IF EXISTS api_platform_product_t CASCADE;

DROP TABLE IF EXISTS api_scope_t CASCADE;

DROP TABLE IF EXISTS api_t CASCADE;

DROP TABLE IF EXISTS api_version_t CASCADE;

DROP TABLE IF EXISTS app_api_t CASCADE;

DROP TABLE IF EXISTS client_t CASCADE;

DROP TABLE IF EXISTS app_t CASCADE;

DROP TABLE IF EXISTS chain_handler_t CASCADE;

DROP TABLE IF EXISTS configuration_property_t CASCADE;

DROP TABLE IF EXISTS configuration_t CASCADE;

DROP TABLE IF EXISTS environment_property_t CASCADE;

DROP TABLE IF EXISTS infrastructure_t CASCADE;

DROP TABLE IF EXISTS infrastructure_type_t CASCADE;

DROP TABLE IF EXISTS instance_infrastructure_t CASCADE;

DROP TABLE IF EXISTS instance_api_property_t CASCADE;

DROP TABLE IF EXISTS instance_api_t CASCADE;

DROP TABLE IF EXISTS instance_app_property_t CASCADE;

DROP TABLE IF EXISTS instance_app_t CASCADE;

DROP TABLE IF EXISTS instance_chain_handler_t CASCADE;

DROP TABLE IF EXISTS instance_handler_chain_t CASCADE;

DROP TABLE IF EXISTS instance_path_t CASCADE;

DROP TABLE IF EXISTS instance_property_t CASCADE;

DROP TABLE IF EXISTS network_zone_t CASCADE;

DROP TABLE IF EXISTS platform_handler_chain_t CASCADE;

DROP TABLE IF EXISTS platform_path_t CASCADE;

DROP TABLE IF EXISTS product_configuration_t CASCADE;

DROP TABLE IF EXISTS product_property_t CASCADE;

DROP TABLE IF EXISTS product_version_property_t CASCADE;

DROP TABLE IF EXISTS product_version_t CASCADE;


DROP TABLE IF EXISTS api_endpoint_scope_t CASCADE;

DROP TABLE IF EXISTS tag_t CASCADE;

DROP TABLE IF EXISTS host_key_t CASCADE;

DROP TABLE IF EXISTS host_t CASCADE;

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

DROP TABLE IF EXISTS auth_provider_client_t CASCADE;

DROP TABLE IF EXISTS auth_provider_key_t CASCADE;

DROP TABLE IF EXISTS auth_provider_t CASCADE;

DROP TABLE IF EXISTS notification_t CASCADE;

DROP TABLE IF EXISTS message_t CASCADE;

DROP TABLE IF EXISTS config_property_t CASCADE;

DROP TABLE IF EXISTS global_config_t CASCADE;

DROP TABLE IF EXISTS global_cert_t CASCADE;

DROP TABLE IF EXISTS global_file_t CASCADE;

DROP TABLE IF EXISTS service_property_t CASCADE;

DROP TABLE IF EXISTS service_config_t CASCADE;

DROP TABLE IF EXISTS service_cert_t CASCADE;

DROP TABLE IF EXISTS service_file_t CASCADE;

DROP TABLE IF EXISTS service_t CASCADE;


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


CREATE TABLE api_platform_instance_t (
    host_id              VARCHAR(22) NOT NULL,
    instance_id          VARCHAR(22) NOT NULL,
    product_id           VARCHAR(22) NOT NULL,
    service_id           VARCHAR(128) NOT NULL,
    product_version      VARCHAR(128) NOT NULL,
    current_flag         BOOLEAN DEFAULT true NOT NULL,
    environment_id       VARCHAR(16) NOT NULL,
    tag_id               VARCHAR(22) NOT NULL,
    update_user          VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);



COMMENT ON COLUMN api_platform_instance_t.service_id IS
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

COMMENT ON COLUMN api_platform_instance_t.current_flag IS
    'Default is false';


ALTER TABLE api_platform_instance_t ADD CONSTRAINT api_platform_instance_pk PRIMARY KEY ( instance_id );

ALTER TABLE api_platform_instance_t
    ADD CONSTRAINT api_platform_instance_uk UNIQUE ( service_id,
                                                     product_id,
                                                     product_version,
                                                     tag_id );

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
    service_id              VARCHAR(64) NOT NULL,
    api_version_desc        VARCHAR(1024),
    spec_link               VARCHAR(1024),
    spec                    TEXT,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE api_version_t ADD CONSTRAINT api_version_pk PRIMARY KEY (host_id, api_id, api_version );
ALTER TABLE api_version_t ADD CONSTRAINT api_ver_uk UNIQUE ( service_id );


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
    operation_owner         VARCHAR(64),
    delivery_owner          VARCHAR(64),
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE app_t ADD CONSTRAINT app_pk PRIMARY KEY ( host_id, app_id );


CREATE TABLE client_t (
    host_id                 VARCHAR(22) NOT NULL,
    app_id                  VARCHAR(22) NOT NULL,
    client_id               VARCHAR(36) NOT NULL,
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
    PRIMARY KEY (client_id),
    FOREIGN KEY (host_id, app_id) REFERENCES app_t(host_id, app_id) ON DELETE CASCADE
);


CREATE TABLE chain_handler_t (
    chain_id          VARCHAR(22) NOT NULL,
    configuration_id  VARCHAR(22) NOT NULL,
    sequence_id       INTEGER NOT NULL,
    update_user       VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE chain_handler_t ADD CONSTRAINT chain_handler_pk PRIMARY KEY ( chain_id,
                                                                          configuration_id );

CREATE TABLE configuration_property_t (
    property_id               VARCHAR(22) NOT NULL,
    configuration_id          VARCHAR(22),
    property_name             VARCHAR(128) NOT NULL,
    property_type             VARCHAR(32) DEFAULT 'Config' NOT NULL,
    sequence_id               INTEGER,
    required_flag             BOOLEAN DEFAULT true NOT NULL,
    property_desc             VARCHAR(1024),
    property_value            TEXT,
    property_value_type       VARCHAR(32),
    property_file             TEXT,
    allowed_subresource_type  VARCHAR(30) DEFAULT 'none',
    update_user               VARCHAR(255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE configuration_property_t
    ADD CHECK ( property_type IN ( 'Cert', 'Config', 'File' ) );

COMMENT ON COLUMN configuration_property_t.property_id IS
    'Autogenerated ID as SMALLSERIAL pseudo-type';

COMMENT ON COLUMN configuration_property_t.configuration_id IS
    'Autogenerated ID as SMALLSERIAL pseudo-type';

COMMENT ON COLUMN configuration_property_t.property_value IS
    'Property Default Value';

COMMENT ON COLUMN configuration_property_t.property_value_type IS
    'One of string, boolean, integer, map, list';

COMMENT ON COLUMN configuration_property_t.allowed_subresource_type IS
  'One of none, api, app, all';

ALTER TABLE configuration_property_t ADD CONSTRAINT configuration_property_pk PRIMARY KEY ( property_id );

ALTER TABLE configuration_property_t ADD CONSTRAINT configuration_property_uk UNIQUE ( configuration_id,
                                                                                       property_name );





CREATE TABLE configuration_t (
    configuration_id          VARCHAR(22) NOT NULL,
    configuration_name        VARCHAR(128) NOT NULL,
    configuration_type        VARCHAR(32) DEFAULT 'Handler',
    infrastructure_type_id    VARCHAR(16) DEFAULT 'Generic',
    class_path                VARCHAR(1024) NOT NULL,
    configuration_desc        VARCHAR(1024),
    transaction_id            INTEGER,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE configuration_t
    ADD CHECK ( configuration_type IN ( 'Deployment', 'Handler', 'Module' ) );

COMMENT ON COLUMN configuration_t.configuration_id IS
    'Autogenerated ID as SMALLSERIAL pseudo-type';

COMMENT ON COLUMN configuration_t.transaction_id IS
    'Autogenerated Unique Transaction ID which is used to group the related changes from different tables  into the same transaction. Transaction ID can be used to rollback all related changes across multiple tables. '
    ;

ALTER TABLE configuration_t ADD CONSTRAINT configuration_pk PRIMARY KEY ( configuration_id );




CREATE TABLE environment_property_t (
    environment_id   VARCHAR(16) NOT NULL,
    property_id      VARCHAR(22) NOT NULL,
    property_type    VARCHAR(32) DEFAULT 'Config' NOT NULL,
    property_value   TEXT,
    property_file    TEXT,
    transaction_id   INTEGER,
    update_user      VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE environment_property_t
    ADD CHECK ( property_type IN ( 'Cert', 'Config', 'File' ) );

COMMENT ON COLUMN environment_property_t.transaction_id IS
    'Autogenerated Unique Transaction ID which is used to group the related changes from different tables  into the same transaction. Transaction ID can be used to rollback all related changes across multiple tables. '
    ;

ALTER TABLE environment_property_t ADD CONSTRAINT environment_property_pk PRIMARY KEY ( environment_id,
                                                                                        property_id );


CREATE TABLE infrastructure_t (
    infrastructure_id          SERIAL NOT NULL,
    infrastructure_type_id     VARCHAR(16) DEFAULT 'Generic',
    zone_id                    INTEGER,
    host_name                  VARCHAR(128),
    k8_cluster_name            VARCHAR(128),
    k8_namespace               VARCHAR(128),
    k8_pod_id                  VARCHAR(128),
    k8_container_id            VARCHAR(128),
    infrastructure_desc        VARCHAR(1024),
    update_user                VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON COLUMN infrastructure_t.infrastructure_id IS
    'Autogenerated ID as SERIAL pseudo-type';

COMMENT ON COLUMN infrastructure_t.zone_id IS
    '1-Application Isolation Zone, AIZ
2-Corporate Zone, Corp';


ALTER TABLE infrastructure_t ADD CONSTRAINT infrastructure_pk PRIMARY KEY ( infrastructure_id );



CREATE TABLE instance_infrastructure_t (
    instance_id       VARCHAR(22)
        CONSTRAINT nnc_instance_infrastrucuture_instance_id NOT NULL,
    infrastructure_id INTEGER
        CONSTRAINT nnc_instance_infrastrucuture_infrastructure_id NOT NULL,
    port_number       VARCHAR(32),
    update_user  VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts         TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_infrastructure_t ADD CONSTRAINT instance_infrastructure_pk PRIMARY KEY ( instance_id,
                                                                                              infrastructure_id,
                                                                                              port_number );



CREATE TABLE instance_api_property_t (
    host_id          VARCHAR(22) NOT NULL,
    instance_id      VARCHAR(22) NOT NULL,
    api_id           VARCHAR(22) NOT NULL,
    api_version      VARCHAR(16) NOT NULL,
    property_id      VARCHAR(22) NOT NULL,
    property_type    VARCHAR(32) DEFAULT 'Config',
    property_value   TEXT,
    property_file    TEXT,
    transaction_id   INTEGER,
    update_user VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_api_property_t
    ADD CONSTRAINT ck_instance_api_property_property_type CHECK ( property_type IN ( 'Cert', 'Config', 'File' ) );


ALTER TABLE instance_api_property_t ADD CONSTRAINT instance_api_property_pk
PRIMARY KEY ( host_id, instance_id, api_id, api_version, property_id );




CREATE TABLE instance_api_t (
    host_id          VARCHAR(22) NOT NULL,
    instance_id      VARCHAR(22) NOT NULL,
    api_id           VARCHAR(22) NOT NULL,
    api_version      VARCHAR(22) NOT NULL,
    is_active        BOOLEAN DEFAULT true,
    update_user      VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_api_t ADD CONSTRAINT instance_api_pk PRIMARY KEY ( host_id, instance_id, api_id, api_version );


CREATE TABLE instance_app_property_t (
    instance_app_id INTEGER
        CONSTRAINT nnc_instance_app_property_instance_app_id NOT NULL,
    property_id             VARCHAR(22)
        CONSTRAINT nnc_instance_app_property_property_id NOT NULL,
    property_type           VARCHAR(32) DEFAULT 'Config',
    property_value          TEXT,
    property_file           TEXT,
    update_user        VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_app_property_t
    ADD CONSTRAINT ck_instance_app_property_property_type CHECK ( property_type IN ( 'Cert', 'Config', 'File' ) );


ALTER TABLE instance_app_property_t ADD CONSTRAINT instance_app_property_pk PRIMARY KEY ( instance_app_id,
                                                                                                          property_id );


CREATE TABLE instance_app_t (
    instance_app_id         SERIAL NOT NULL,
    instance_id             VARCHAR(22) NOT NULL,
    host_id                 VARCHAR(32) NOT NULL,
    app_id                  VARCHAR(128) NOT NULL,
    app_version             VARCHAR(128) NOT NULL,
    is_active               BOOLEAN DEFAULT true,
    update_user             VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_app_t ADD CONSTRAINT instance_app_pk PRIMARY KEY ( instance_app_id );

ALTER TABLE instance_app_t ADD CONSTRAINT instance_app_uk UNIQUE ( instance_id, host_id, app_id );


CREATE TABLE instance_chain_handler_t (
    chain_id          VARCHAR(22) NOT NULL,
    configuration_id  VARCHAR(22) NOT NULL,
    sequence_id       INTEGER NOT NULL,
    transaction_id    INTEGER,
    update_user       VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE instance_chain_handler_t ADD CONSTRAINT instance_chain_handler_pk PRIMARY KEY ( chain_id,
                                                                                            configuration_id );




CREATE TABLE instance_handler_chain_t (
    chain_id          VARCHAR(22) NOT NULL,
    instance_id       VARCHAR(22),
    chain_name        VARCHAR(128) NOT NULL,
    chain_desc        VARCHAR(1024),
    transaction_id    INTEGER,
    update_user  VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts         TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON COLUMN instance_handler_chain_t.chain_id IS
    'Autogenerated ID as SMALLSERIAL pseudo-type';

COMMENT ON COLUMN instance_handler_chain_t.instance_id IS
    'Autogenerated ID as SERIAL pseudo-type';

ALTER TABLE instance_handler_chain_t ADD CONSTRAINT instance_handler_chain_pk PRIMARY KEY ( chain_id );

ALTER TABLE instance_handler_chain_t ADD CONSTRAINT instance_handler_chain_uk UNIQUE ( instance_id,
                                                                                       chain_name );




CREATE TABLE instance_path_t (
    path_id          SMALLSERIAL NOT NULL,
    path_name        VARCHAR(128) NOT NULL,
    path_method      VARCHAR(10),
    chain_id         VARCHAR(22),
    update_user VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_path_t
    ADD CHECK ( path_method IN ( 'DELETE', 'GET', 'PATCH', 'POST', 'PUT' ) );

COMMENT ON COLUMN instance_path_t.path_id IS
    'Autogenerated ID as SMALLSERIAL pseudo-type';

COMMENT ON COLUMN instance_path_t.chain_id IS
    'Autogenerated ID as SMALLSERIAL pseudo-type';

ALTER TABLE instance_path_t ADD CONSTRAINT instance_path_pk PRIMARY KEY ( path_id );

ALTER TABLE instance_path_t
    ADD CONSTRAINT instance_path_uk UNIQUE ( path_name,
                                             path_method,
                                             chain_id );




CREATE TABLE instance_property_t (
    host_id           VARCHAR(22) NOT NULL,
    instance_id       VARCHAR(22) NOT NULL,
    property_id       VARCHAR(22) NOT NULL,
    property_type     VARCHAR(32) DEFAULT 'Config' NOT NULL,
    property_value    TEXT,
    property_file     TEXT,
    transaction_id    INTEGER,
    update_user       VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE instance_property_t
    ADD CHECK ( property_type IN ( 'Cert', 'Config', 'File' ) );

COMMENT ON COLUMN instance_property_t.transaction_id IS
    'Autogenerated Unique Transaction ID which is used to group the related changes from different tables  into the same transaction. Transaction ID can be used to rollback all related changes across multiple tables. '
    ;

ALTER TABLE instance_property_t ADD CONSTRAINT instance_property_pk PRIMARY KEY ( instance_id,
                                                                                  property_id );



CREATE TABLE network_zone_t (
    zone_id          INTEGER NOT NULL,
    zone_name        VARCHAR(128) NOT NULL,
    abbreviation     VARCHAR(128),
    transaction_id   INTEGER,
    update_user VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON COLUMN network_zone_t.zone_id IS
    '1-Application Isolation Zone, AIZ
2-Corporate Zone, Corp';

COMMENT ON COLUMN network_zone_t.transaction_id IS
    'Autogenerated Unique Transaction ID which is used to group the related changes from different tables  into the same transaction. Transaction ID can be used to rollback all related changes across multiple tables. '
    ;

ALTER TABLE network_zone_t ADD CONSTRAINT network_zone_pk PRIMARY KEY ( zone_id );




CREATE TABLE platform_handler_chain_t (
    chain_id          VARCHAR(22) NOT NULL,
    chain_name        VARCHAR(128) NOT NULL,
    chain_desc        VARCHAR(1024),
    transaction_id    INTEGER,
    update_user       VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts         TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON COLUMN platform_handler_chain_t.chain_id IS
    'Autogenerated ID as SMALLSERIAL pseudo-type';

COMMENT ON COLUMN platform_handler_chain_t.transaction_id IS
    'Autogenerated Unique Transaction ID which is used to group the related changes from different tables  into the same transaction. Transaction ID can be used to rollback all related changes across multiple tables. '
    ;

ALTER TABLE platform_handler_chain_t ADD CONSTRAINT platform_handler_chain_pk PRIMARY KEY ( chain_id );



CREATE TABLE platform_path_t (
    path_id          SMALLSERIAL NOT NULL,
    path_name        VARCHAR(128) NOT NULL,
    path_desc        VARCHAR(1024),
    path_method      VARCHAR(10),
    chain_id         VARCHAR(22),
    transaction_id   INTEGER,
    update_user      VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE platform_path_t
    ADD CHECK ( path_method IN ( 'DELETE', 'GET', 'PATCH', 'POST', 'PUT' ) );

COMMENT ON COLUMN platform_path_t.path_id IS
    'Autogenerated ID as SMALLSERIAL pseudo-type';

COMMENT ON COLUMN platform_path_t.chain_id IS
    'Autogenerated ID as SMALLSERIAL pseudo-type';

COMMENT ON COLUMN platform_path_t.transaction_id IS
    'Autogenerated Unique Transaction ID which is used to group the related changes from different tables  into the same transaction. Transaction ID can be used to rollback all related changes across multiple tables. '
    ;

ALTER TABLE platform_path_t ADD CONSTRAINT platform_path_pk PRIMARY KEY ( path_id );

ALTER TABLE platform_path_t ADD CONSTRAINT platform_path_uk UNIQUE ( path_name,
                                                                     path_method );




CREATE TABLE product_configuration_t (
    product_id       VARCHAR(22) NOT NULL,
    configuration_id VARCHAR(22) NOT NULL,
    update_user VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE product_configuration_t ADD CONSTRAINT product_configuration_pk PRIMARY KEY ( product_id,
                                                                                          configuration_id );




CREATE TABLE product_property_t (
    product_id       VARCHAR(22) NOT NULL,
    property_id      VARCHAR(22) NOT NULL,
    property_type    VARCHAR(32) DEFAULT 'Config' NOT NULL,
    property_value   TEXT,
    property_file    TEXT,
    update_user VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE product_property_t
    ADD CHECK ( property_type IN ( 'Cert', 'Config', 'File' ) );

ALTER TABLE product_property_t ADD CONSTRAINT product_property_pk PRIMARY KEY ( product_id,
                                                                                property_id );




CREATE TABLE product_version_property_t (
    product_id       VARCHAR(22) NOT NULL,
    product_version  VARCHAR(128) NOT NULL,
    property_id      VARCHAR(22) NOT NULL,
    property_type    VARCHAR(32) DEFAULT 'Config' NOT NULL,
    property_value   TEXT,
    property_file    TEXT,
    update_user VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE product_version_property_t
    ADD CHECK ( property_type IN ( 'Cert', 'Config', 'File' ) );

ALTER TABLE product_version_property_t
    ADD CONSTRAINT product_version_property_pk PRIMARY KEY ( product_id,
                                                             product_version,
                                                             property_id );




CREATE TABLE product_version_t (
    product_id                  VARCHAR(22) NOT NULL,
    product_version             VARCHAR(128) NOT NULL,
    product_version_desc        VARCHAR(1024),
    current_flag                BOOLEAN DEFAULT false,
    update_user                 VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON COLUMN product_version_t.product_id IS
    '1 - Light Gateway
2 - Light Proxy Server
3 - Light Proxy Client
4 - Light Proxy Sidecar
5 - Light Proxy Lambda
6 - Kafka Sidecar';


ALTER TABLE product_version_t ADD CONSTRAINT product_version_pk PRIMARY KEY ( product_id, product_version );


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


CREATE TABLE host_t (
    host_id                   VARCHAR(32) NOT NULL, -- a generated unique identifier.
    host_domain               VARCHAR(64) NOT NULL,
    org_name                  VARCHAR(128) NOT NULL,
    org_desc                  VARCHAR(255) NOT NULL,
    org_owner                 VARCHAR(64) NOT NULL,
    jwk                       VARCHAR(65535) NOT NULL, -- json web key that contains current and previous public keys
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE host_t ADD CONSTRAINT host_pk PRIMARY KEY ( host_id );

ALTER TABLE host_t ADD CONSTRAINT host_domain_uk UNIQUE ( host_domain );



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

CREATE TABLE host_key_t (
    host_id                   VARCHAR(32) NOT NULL,
    kid                       VARCHAR(32) NOT NULL,
    public_key                VARCHAR(65535) NOT NULL,
    private_key               VARCHAR(65535) NOT NULL,
    key_type                  CHAR(1) NOT NULL, -- L long live C current, P previous
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE host_key_t ADD CONSTRAINT host_key_pk PRIMARY KEY ( host_id, kid );

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
    FOREIGN KEY (host_id, user_id) REFERENCES user_host_t(host_id, user_id) ON DELETE CASCADE,
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
    FOREIGN KEY (host_id, user_id) REFERENCES user_host_t(host_id, user_id) ON DELETE CASCADE,
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
    PRIMARY KEY (host_id, role_id)
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
    host_id                   VARCHAR(22) NOT NULL,
    provider_id               VARCHAR(22) NOT NULL,
    jwk                       VARCHAR(65535) NOT NULL, -- json web key that contains current and previous public keys
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (host_id, provider_id) -- in case the provider id is input from user to backup other cloud oauth2 provider.
);

CREATE TABLE auth_provider_key_t (
    host_id                   VARCHAR(22) NOT NULL,
    provider_id               VARCHAR(22) NOT NULL,
    kid                       VARCHAR(22) NOT NULL,
    public_key                VARCHAR(65535) NOT NULL,
    private_key               VARCHAR(65535) NOT NULL,
    key_type                  CHAR(1) NOT NULL, -- L long live C current, P previous
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, provider_id, kid),
    FOREIGN KEY(host_id, provider_id) REFERENCES auth_provider_t (host_id, provider_id) ON DELETE CASCADE
);

CREATE TABLE auth_provider_client_t (
    host_id                   VARCHAR(22) NOT NULL,
    provider_id               VARCHAR(22) NOT NULL,
    client_id                 VARCHAR(36) NOT NULL,
    update_user               VARCHAR (255) DEFAULT SESSION_USER NOT NULL,
    update_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(host_id, provider_id, client_id),
    FOREIGN KEY(host_id, provider_id) REFERENCES auth_provider_t (host_id, provider_id) ON DELETE CASCADE,
    FOREIGN KEY(client_id) REFERENCES client_t(client_id) ON DELETE CASCADE
);

CREATE TABLE auth_code_t (
    host_id                   VARCHAR(22) NOT NULL,
    auth_code                 VARCHAR(22) NOT NULL,
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
    FOREIGN KEY (host_id, user_id) REFERENCES user_host_t(host_id, user_id) ON DELETE CASCADE
);

CREATE TABLE auth_refresh_token_t (
    refresh_token             VARCHAR(36) NOT NULL,
    host_id                   VARCHAR(22) NOT NULL,
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
    FOREIGN KEY (host_id, user_id) REFERENCES user_host_t (host_id, user_id) ON DELETE CASCADE
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
    user_id                   VARCHAR(22) NOT NULL,
    nonce                     INTEGER NOT NULL,
    event_class               VARCHAR(255) NOT NULL,
    event_json                TEXT NOT NULL,
    process_time              TIMESTAMP NOT NULL,
    process_flag              BOOLEAN NOT NULL,
    error                     VARCHAR(1024) NULL
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

CREATE TABLE config_property_t (
  host_id              VARCHAR(22) NOT NULL,
  config_type          CHAR(1) NOT NULL,   -- R Runtime, D Deployment
  product_id           VARCHAR(22) NOT NULL,
  product_version      VARCHAR(64) NOT NULL,
  scope                VARCHAR(32) NOT NULL,   -- proxy, application, api
  pkey                 VARCHAR(128) NOT NULL,
  pmod                 VARCHAR(128) NOT NULL,  -- the module or handler with package of the property
  ptype                CHAR(1) NOT NULL,       -- S string B boolean I integer M map L list
  porder               INT,
  PRIMARY KEY(host_id, config_type, product_id, product_version, scope, pkey)
);


CREATE TABLE global_config_t (
  host_id               VARCHAR(22) NOT NULL,
  config_type           CHAR(1) NOT NULL, -- R Runtime D Deployment
  product_id            VARCHAR(22) NOT NULL,
  product_version       VARCHAR(64) NOT NULL,
  api_id                VARCHAR(128) NOT NULL,
  api_version           VARCHAR(64) NOT NULL,
  env_tag               VARCHAR(32) NOT NULL,
  pkey                  VARCHAR(128) NOT NULL,
  pvalue                VARCHAR(1024) NOT NULL,
  PRIMARY KEY(host_id, config_type, product_id, product_version, api_id, api_version, env_tag, pkey)
);

CREATE TABLE global_file_t (
  host_id               VARCHAR(22) NOT NULL,
  config_type           CHAR(1) NOT NULL, -- R Runtime D Deployment
  product_id            VARCHAR(22) NOT NULL,
  product_version       VARCHAR(64) NOT NULL,
  api_id                VARCHAR(128) NOT NULL,
  api_version           VARCHAR(64) NOT NULL,
  env_tag               VARCHAR(32) NOT NULL,
  filename              VARCHAR(64) NOT NULL,
  content               TEXT NOT NULL,
  PRIMARY KEY(host_id, config_type, product_id, product_version, api_id, api_version, env_tag, filename)
);

CREATE TABLE global_cert_t (
  host_id               VARCHAR(22) NOT NULL,
  config_type           CHAR(1) NOT NULL, -- R Runtime D Deployment
  product_id            VARCHAR(22) NOT NULL,
  product_version       VARCHAR(64) NOT NULL,
  api_id                VARCHAR(128) NOT NULL,
  api_version           VARCHAR(64) NOT NULL,
  env_tag               VARCHAR(32) NOT NULL,
  filename              VARCHAR(64) NOT NULL,
  content               TEXT NOT NULL,
  PRIMARY KEY(host_id, config_type, product_id, product_version, api_id, api_version, env_tag, filename)
);

CREATE TABLE service_t (
  sid                   SERIAL PRIMARY KEY,
  host_id               VARCHAR(22) NOT NULL,
  config_type           CHAR(1) NOT NULL,
  product_id            VARCHAR(22) NOT NULL,
  product_version       VARCHAR(64) NOT NULL,
  api_id                VARCHAR(128) NOT NULL,
  api_version           VARCHAR(64) NOT NULL,
  env_tag               VARCHAR(32) NOT NULL,
  CONSTRAINT uc_service UNIQUE(host_id, config_type, product_id, product_version, api_id, api_version, env_tag)
);

CREATE TABLE service_property_t (
  sid                   INT NOT NULL,
  pkey                  VARCHAR(128) NOT NULL,
  pvalue                VARCHAR(1024) NOT NULL,
  PRIMARY KEY(sid, pkey)
);


CREATE TABLE service_config_t (
  sid                   INT NOT NULL,
  pkey                  VARCHAR(128) NOT NULL,
  pvalue                VARCHAR(1024) NOT NULL,
  PRIMARY KEY(sid, pkey)
);

ALTER TABLE service_config_t ADD FOREIGN KEY(sid) REFERENCES service_t(sid);

CREATE TABLE service_file_t (
  sid                   INT NOT NULL,
  filename              VARCHAR(64) NOT NULL,
  content               TEXT NOT NULL,
  PRIMARY KEY(sid, filename)
);

ALTER TABLE service_file_t ADD FOREIGN KEY(sid) REFERENCES service_t(sid);

CREATE TABLE service_cert_t (
  sid                   INT NOT NULL,
  filename              VARCHAR(64) NOT NULL,
  content               TEXT NOT NULL,
  PRIMARY KEY(sid, filename)
);

ALTER TABLE service_cert_t ADD FOREIGN KEY(sid) REFERENCES service_t(sid);


ALTER TABLE rule_group_host_t
    ADD CONSTRAINT rule_group_fk FOREIGN KEY ( group_id, rule_id )
        REFERENCES rule_group_t ( group_id, rule_id )
            ON DELETE CASCADE;


ALTER TABLE rule_group_host_t
    ADD CONSTRAINT host_id_fk FOREIGN KEY ( host_id )
        REFERENCES host_t ( host_id )
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
    ADD CONSTRAINT api_platform_instance_fk FOREIGN KEY ( instance_id )
        REFERENCES api_platform_instance_t ( instance_id )
            ON DELETE CASCADE;

ALTER TABLE instance_app_t
    ADD CONSTRAINT api_platform_instance_fkv1 FOREIGN KEY ( instance_id )
        REFERENCES api_platform_instance_t ( instance_id )
            ON DELETE CASCADE;

ALTER TABLE instance_property_t
    ADD CONSTRAINT api_platform_instance_fkv2 FOREIGN KEY ( instance_id )
        REFERENCES api_platform_instance_t ( instance_id )
            ON DELETE CASCADE;

ALTER TABLE instance_handler_chain_t
    ADD CONSTRAINT api_platform_instance_fkv3 FOREIGN KEY ( instance_id )
        REFERENCES api_platform_instance_t ( instance_id )
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
        REFERENCES configuration_t ( configuration_id )
            ON DELETE CASCADE;

ALTER TABLE instance_chain_handler_t
    ADD CONSTRAINT configuration_fkv1 FOREIGN KEY ( configuration_id )
        REFERENCES configuration_t ( configuration_id )
            ON DELETE CASCADE;

ALTER TABLE configuration_property_t
    ADD CONSTRAINT configuration_fkv2 FOREIGN KEY ( configuration_id )
        REFERENCES configuration_t ( configuration_id )
            ON DELETE CASCADE;

ALTER TABLE product_configuration_t
    ADD CONSTRAINT configuration_fkv3 FOREIGN KEY ( configuration_id )
        REFERENCES configuration_t ( configuration_id )
            ON DELETE CASCADE;

ALTER TABLE environment_property_t
    ADD CONSTRAINT configuration_property_fk FOREIGN KEY ( property_id )
        REFERENCES configuration_property_t ( property_id )
            ON DELETE CASCADE;

ALTER TABLE instance_property_t
    ADD CONSTRAINT configuration_property_fkv1 FOREIGN KEY ( property_id )
        REFERENCES configuration_property_t ( property_id )
            ON DELETE CASCADE;

ALTER TABLE product_property_t
    ADD CONSTRAINT configuration_property_fkv2 FOREIGN KEY ( property_id )
        REFERENCES configuration_property_t ( property_id )
            ON DELETE CASCADE;

ALTER TABLE product_version_property_t
    ADD CONSTRAINT configuration_property_fkv3 FOREIGN KEY ( property_id )
        REFERENCES configuration_property_t ( property_id )
            ON DELETE CASCADE;

ALTER TABLE instance_api_property_t
    ADD CONSTRAINT configuration_property_fkv5 FOREIGN KEY ( property_id )
        REFERENCES configuration_property_t ( property_id )
            ON DELETE CASCADE;

ALTER TABLE instance_app_property_t
    ADD CONSTRAINT configuration_property_fkv6 FOREIGN KEY ( property_id )
        REFERENCES configuration_property_t ( property_id )
            ON DELETE CASCADE;

ALTER TABLE api_platform_instance_t
    ADD CONSTRAINT tag_fk FOREIGN KEY ( host_id, tag_id )
        REFERENCES tag_t ( host_id, tag_id )
            ON DELETE CASCADE;

ALTER TABLE instance_infrastructure_t
    ADD CONSTRAINT instance_infrastructure_instance_fk FOREIGN KEY ( instance_id )
        REFERENCES api_platform_instance_t ( instance_id )
            ON DELETE CASCADE;

ALTER TABLE instance_infrastructure_t
    ADD CONSTRAINT instance_infrastructure_infrastructure_fk FOREIGN KEY ( infrastructure_id )
        REFERENCES infrastructure_t ( infrastructure_id )
            ON DELETE CASCADE;

ALTER TABLE instance_app_property_t
    ADD CONSTRAINT instance_app_fk FOREIGN KEY ( instance_app_id )
        REFERENCES instance_app_t ( instance_app_id )
            ON DELETE CASCADE;

ALTER TABLE instance_chain_handler_t
    ADD CONSTRAINT instance_handler_chain_fk FOREIGN KEY ( chain_id )
        REFERENCES instance_handler_chain_t ( chain_id )
            ON DELETE CASCADE;

ALTER TABLE instance_path_t
    ADD CONSTRAINT instance_handler_chain_fkv2 FOREIGN KEY ( chain_id )
        REFERENCES instance_handler_chain_t ( chain_id )
            ON DELETE CASCADE;

ALTER TABLE infrastructure_t
    ADD CONSTRAINT network_zone_fk FOREIGN KEY ( zone_id )
        REFERENCES network_zone_t ( zone_id )
            ON DELETE CASCADE;

ALTER TABLE chain_handler_t
    ADD CONSTRAINT platform_handler_chain_fk FOREIGN KEY ( chain_id )
        REFERENCES platform_handler_chain_t ( chain_id )
            ON DELETE CASCADE;

ALTER TABLE platform_path_t
    ADD CONSTRAINT platform_handler_chain_fkv2 FOREIGN KEY ( chain_id )
        REFERENCES platform_handler_chain_t ( chain_id )
            ON DELETE CASCADE;

ALTER TABLE api_platform_instance_t
    ADD CONSTRAINT product_version_fk FOREIGN KEY ( product_id,
                                                    product_version )
        REFERENCES product_version_t ( product_id,
                                       product_version )
            ON DELETE CASCADE;

ALTER TABLE product_version_property_t
    ADD CONSTRAINT product_version_fkv1 FOREIGN KEY ( product_id,
                                                      product_version )
        REFERENCES product_version_t ( product_id,
                                       product_version )
            ON DELETE CASCADE;


-- Extend platform instance with region, network zone, line of business, server description, business description, topic classification
-- region, network zone and line of business tables already exist, adding others as varchar

ALTER TABLE api_platform_instance_t
  ADD COLUMN zone_id INTEGER,
  ADD COLUMN region_id INTEGER,
  ADD COLUMN lob_id INTEGER,
  ADD COLUMN server_desc VARCHAR(128),
  ADD COLUMN instance_desc VARCHAR(128),
  ADD COLUMN topic_classification VARCHAR(128);


ALTER TABLE api_platform_instance_t
    ADD CONSTRAINT zone_fk_v1 FOREIGN KEY ( zone_id )
        REFERENCES network_zone_t ( zone_id )
            ON DELETE CASCADE;



-- insert the lightapi.net as the default host. All users created will be associated to this host by default.
INSERT INTO host_t (host_id, host_domain, org_name, org_desc, org_owner, jwk)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'lightapi.net', 'Light API Organization', 'Default Orgnaization populated with db script when database is created.', 'stevehu@gmail.com', '{"keys":[{"kty":"RSA","kid":"7pGHLozGRXqv2g47T1HQag","n":"h25ydNVptrcDlUiixNtcdsjDUyTT2ZlarxIyRpsOZNWpQ_kXjn723j9YnyePeQkC88K-MPWYhRHKp9w_HwZvWvGgQNk5wlGW3PbOAldbW_5-j5gizPDM8d5mTAThbjsve5wVWwN51utQoqFNdkCQ8sJ5mHbaiSTTUHIDhbKriIlFhsNdLZEHj0yO3awnH8KYxzvbrGzqKse4bDNu7a-dYcjmEbmZ0qGuLYbNeHN4vc-1QukFlnnLD9XNmbh9Gurv52box-Sx2VcU1EY_PaFae2p2BgVBbqLJhcv176vIpKAnIFnyb1aNtP19wOB3JbZDhXhXdG9QhEjUYzLOiV5HnQ","e":"AQAB"},{"kty":"RSA","kid":"Tj_l_tIBTginOtQbL0Pv5w","n":"0YRbWAb1FGDpPUUcrIpJC6BwlswlKMS-z2wMAobdo0BNxNa7hG_gIHVPkXu14Jfo1JhUhS4wES3DdY3a6olqPcRN1TCCUVHd-1TLd1BBS-yq9tdJ6HCewhe5fXonaRRKwutvoH7i_eR4m3fQ1GoVzVAA3IngpTr4ptnM3Ef3fj-5wZYmitzrRUyQtfARTl3qGaXP_g8pHFAP0zrNVvOnV-jcNMKm8YZNcgcs1SuLSFtUDXpf7Nr2_xOhiNM-biES6Dza1sMLrlxULFuctudO9lykB7yFh3LHMxtIZyIUHuy0RbjuOGC5PmDowLttZpPI_j4ynJHAaAWr8Ddz764WdQ","e":"AQAB"}]}');

INSERT INTO host_key_t(host_id, kid, public_key, private_key, key_type) VALUES
(
'N2CMw0HGQXeLvC1wBfln2A',
'7pGHLozGRXqv2g47T1HQag',
'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAh25ydNVptrcDlUiixNtcdsjDUyTT2ZlarxIyRpsOZNWpQ/kXjn723j9YnyePeQkC88K+MPWYhRHKp9w/HwZvWvGgQNk5wlGW3PbOAldbW/5+j5gizPDM8d5mTAThbjsve5wVWwN51utQoqFNdkCQ8sJ5mHbaiSTTUHIDhbKriIlFhsNdLZEHj0yO3awnH8KYxzvbrGzqKse4bDNu7a+dYcjmEbmZ0qGuLYbNeHN4vc+1QukFlnnLD9XNmbh9Gurv52box+Sx2VcU1EY/PaFae2p2BgVBbqLJhcv176vIpKAnIFnyb1aNtP19wOB3JbZDhXhXdG9QhEjUYzLOiV5HnQIDAQAB',
'MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCHbnJ01Wm2twOVSKLE21x2yMNTJNPZmVqvEjJGmw5k1alD+ReOfvbeP1ifJ495CQLzwr4w9ZiFEcqn3D8fBm9a8aBA2TnCUZbc9s4CV1tb/n6PmCLM8Mzx3mZMBOFuOy97nBVbA3nW61CioU12QJDywnmYdtqJJNNQcgOFsquIiUWGw10tkQePTI7drCcfwpjHO9usbOoqx7hsM27tr51hyOYRuZnSoa4ths14c3i9z7VC6QWWecsP1c2ZuH0a6u/nZujH5LHZVxTURj89oVp7anYGBUFuosmFy/Xvq8ikoCcgWfJvVo20/X3A4HcltkOFeFd0b1CESNRjMs6JXkedAgMBAAECggEAMcLTKzp+7TOxjVhy9gHjp4F8wz/01y8RsuHstySh1UrsNp1/mkvsSRzdYx0WClLVUttrJnIW6E3xOFwklTG4GKJPT4SBRHTWCbplV1bhqpuHxRsRLlwL8ZLV43inm+kDOVfQQPC2A9HSfu7ll12B5LCwHOUOxvVQ7230/Vr4y+GacYHDO0aL7tWAC2fH8hXzvgSc+sosg/gIRro7aasP5GMuFZjtPANzwhovE8vq71ZQTCzEEm890NuzOOYLUCmkE+FDL6Fjg9lckcosmfPuBpqMjAMMAhIHLEwmWBX6najTcuxpzDT6H+4cmU8+TyX2OwBlyAWpFNTLp3ta05tAAQKBgQDRgSxGB83hx5IL1u1gvDsEfS2sKgRDE5ZEeNDOrxI+U6dhgKj7ae11as83AZnA+sAQrHPZowoRAnAlqNFTQKMLxQfocs2sl5pG5xkL7DrlteUtG6gDvjsbtL64wiy6WrfTJvcICiAw9skgSFX+ZTy9GhcvQVrrjrHrjMl2b+uHAQKBgQClfN7SdW9hxKbKzHzpJ4G74Vr0JqYmr2JPu5DezL/Mxnx+sKEA2ByqVAEO6pJKGR5GfwPh91BBc1sRA4PzWtLRR5Dve6dm1puhaXKeREwBgIoDnXvGDfsOnwHQcGJzSgqBmycTTDiBmjnYX8AkZkbHN5lIFriy7G063XsuGIh8nQKBgDpEVb7oXr9DlP/L99smnrdh5Tjzupm5Mdq7Sz+ge09wTqYUdWrvDAbS/OyMemmsk4xPmizWZm9SoUQoDoe7+1zDoK5qd39f7p13moSxX7QRgbqo7XKVDrVm8IBMKMpvfp6wQJYw0sErccaTt674Ewt43SfcYmAPILalQka5W+UBAoGAQpom83zf/vEuT6BNBWkpBXyFJo4HgLpFTuGmRIUTDE81+6cKpVRU9Rgp9N7jUX8aeDTWUzM90ZmjpQ1NJbv/7Mpownl5viHRMP1Ha/sAu/oHkbzn+6XUzOWhzUnt1YiPAep3p4SdmUuAzFx88ClZgwQVZLYAT8Jnk7FfygWFqOECgYBOox0DFatEqB/7MNMoLMZCacSrylZ1NYHJYAdWkxOvahrppAMbDVFDlwvH7i8gVvzcfFxQtOxSJBlUKlamDd5i76O2N+fIPO8P+iyqKz2Uh/emVwWCWlijSOnXvKRUOiujVufGP0OGxi1GKSUaIXnvMQqYF9M/Igi0BQiCn+pFzw==',
'L'
);

INSERT INTO host_key_t(host_id, kid, public_key, private_key, key_type) VALUES
(
'N2CMw0HGQXeLvC1wBfln2A',
'Tj_l_tIBTginOtQbL0Pv5w',
'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0YRbWAb1FGDpPUUcrIpJC6BwlswlKMS+z2wMAobdo0BNxNa7hG/gIHVPkXu14Jfo1JhUhS4wES3DdY3a6olqPcRN1TCCUVHd+1TLd1BBS+yq9tdJ6HCewhe5fXonaRRKwutvoH7i/eR4m3fQ1GoVzVAA3IngpTr4ptnM3Ef3fj+5wZYmitzrRUyQtfARTl3qGaXP/g8pHFAP0zrNVvOnV+jcNMKm8YZNcgcs1SuLSFtUDXpf7Nr2/xOhiNM+biES6Dza1sMLrlxULFuctudO9lykB7yFh3LHMxtIZyIUHuy0RbjuOGC5PmDowLttZpPI/j4ynJHAaAWr8Ddz764WdQIDAQAB',
'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDRhFtYBvUUYOk9RRysikkLoHCWzCUoxL7PbAwCht2jQE3E1ruEb+AgdU+Re7Xgl+jUmFSFLjARLcN1jdrqiWo9xE3VMIJRUd37VMt3UEFL7Kr210nocJ7CF7l9eidpFErC62+gfuL95Hibd9DUahXNUADcieClOvim2czcR/d+P7nBliaK3OtFTJC18BFOXeoZpc/+DykcUA/TOs1W86dX6Nw0wqbxhk1yByzVK4tIW1QNel/s2vb/E6GI0z5uIRLoPNrWwwuuXFQsW5y25072XKQHvIWHcsczG0hnIhQe7LRFuO44YLk+YOjAu21mk8j+PjKckcBoBavwN3PvrhZ1AgMBAAECggEBAMuDYGLqJydLV2PPfSHQFVH430RrOfEW4y2CC0xtCl8n+CKqXm0vaqq8qLRtUWa+yEexS/AtxDz7ke/fAfVt00f6JYxe2Ub6WcBnRlg4GaURV6P7zWu98UghWWkbvaphLpmVrdFdT0pFoi2JvcyG23SaMKwINbDpzlvsFgUm1q3GoCIZXRc8iAKT+Iil1QmGdacGni/D2WzPTLSf1/acZU2TsPBWLS/jsjPe4ac4IDpxssDC+w6QArZ8U64DKJ531C4tK9o+RArQzBrEaZc1mAlw7xAPr36tXvOTUycux6k07ERSIIze2okVmmewL6tX1cb7tY1F8T+ebKGD3xGEAYUCgYEA9Lpy4593uTBww7AupcZq2YL8qHUfnvxIWiFbeIznUezyYyRbjyLDYj+g7QfQJHk579UckDZZDcT3H+wdh1LxQ7HKDlYQn2zt8Kdufs5cvSObeGkSqSY26g4QDRcRcRO3xFs8bQ/CnPNT7hsWSY+8wnuRvjUTstMA1vx1+/HHZfMCgYEA2yq8yFogdd2/wUcFlqjPgbJ98X9ZNbZ06uUCur4egseVlSVE+R2pigVVwFCDQpseGu2GVgW5q8kgDGsaJuEVWIhGZvS9IHONBz/WB0PmOZjXlXOhmT6iT6m/9bAQk8MtOee77lUVvgf7FO8XDKtuPh6VGJpr+YJHxHoEX/dbo/cCgYAjwy9Q1hffxxVjc1aNwR4SJRMY5uy1BfbovOEqD6UqEq8lD8YVd6YHsHaqzK589f4ibwkaheajnXnjf1SdVuCM3OlDCQ6qzXdD6KO8AhoJRa/Ne8VPVJdHwsBTuWBCHviGyDJfWaM93k0QiYLLQyb5YKdenVEAm9cOk5wGMkHKQwKBgH050CASDxYJm/UNZY4N6nLKz9da0lg0Zl2IeKTG2JwU+cz8PIqyfhqUrchyuG0oQG1WZjlkkBAtnRg7YffxB8dMJh3RnPabz2ri+KGyFCu4vwVvylfLR+aIsVvqO66SCJdbZy/ogcHQwY/WhK8CjL0FsF8cbLFl1SfYKAPFTCFFAoGANmOKonyafvWqsSkcl6vUTYYq53IN+qt0IJTDB2cEIEqLXtNth48HvdQkxDF3y4cNLZevhyuIy0Z3yWGbZM2yWbDNn8Q2W5RTyajofQu1mIv2EBzLeOoaSBPLX4G6r4cODSwWbjOdaNxcXd0+uYeAWDuQUSnHpHFJ2r1cpL/9Nbs=',
'C'
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


INSERT INTO product_version_t (product_id, product_version, product_version_desc, current_flag)
VALUES ('lg', '1.4.5', 'This is incremental release to first major release of light gateway', true);


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


INSERT INTO client_t (host_id, app_id, client_id, client_type, client_profile, client_secret,
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'APM000100', 'f7d42348-c647-4efb-a52d-4c5787421e70', 'trusted', 'mobile', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'admin', null, 'https://localhost:3000/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);

INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'APM000123', 'PetStore Web Server', 'PetStore Web Server that calls PetStore API', false, null, null);

INSERT INTO client_t (host_id, app_id, client_id, client_type, client_profile, client_secret,
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'APM000123', 'f7d42348-c647-4efb-a52d-4c5787421e72', 'trusted', 'mobile', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'portal.r portal.w ref.r ref.w', '{"c1": "361", "c2": "67"}', 'https://localhost:3000/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);


INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'APM000124', 'Light Portal Test Web Application', 'Light Portal Test React Single Page Application', false, null, null);

INSERT INTO client_t (host_id, app_id, client_id, client_type, client_profile, client_secret,
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'APM000124', 'f7d42348-c647-4efb-a52d-4c5787421e73', 'trusted', 'browser', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'portal.r portal.w ref.r ref.w', null, 'https://dev.lightapi.net/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);


INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'APM000126', 'Light Portal Test Web Application', 'Light Portal Test React Single Page Application', false, null, null);


INSERT INTO client_t (host_id, app_id, client_id, client_type, client_profile, client_secret,
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'APM000126', 'f7d42348-c647-4efb-a52d-4c5787421e75', 'trusted', 'browser', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'portal.r portal.w ref.r ref.w', null, 'https://dev.lightapi.net/authorization', 'com.networknt.oauth.auth.DefaultAuth', null);

INSERT INTO app_t(host_id, app_id, app_name, app_desc, is_kafka_app, operation_owner, delivery_owner)
VALUES ('N2CMw0HGQXeLvC1wBfln2A', 'APM000127', 'Petstore Client Application', 'An example application that is used to demo access to openapi-petstore', false, null, null);


INSERT INTO client_t (host_id, app_id, client_id, client_type, client_profile, client_secret,
    client_scope, custom_claim, redirect_uri, authenticate_class, deref_client_id)
VALUES('N2CMw0HGQXeLvC1wBfln2A', 'APM000127', 'f7d42348-c647-4efb-a52d-4c5787421e76', 'trusted', 'browser', '1000:5b37332c202d36362c202d36392c203131362c203132362c2036322c2037382c20342c202d37382c202d3131352c202d35332c202d34352c202d342c202d3132322c203130322c2033325d:29ad1fe88d66584c4d279a6f58277858298dbf9270ffc0de4317a4d38ba4b41f35f122e0825c466f2fa14d91e17ba82b1a2f2a37877a2830fae2973076d93cc2',
'read:pets write:pets', null, 'https://dev.lightapi.net/authorization', 'com.networknt.oauth.auth.LightPortalAuth', null);


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

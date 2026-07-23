\connect configserver

BEGIN;

-- Event replay Phase 1 is additive and remains dormant while every runtime
-- feature gate is disabled. Existing DLQ, notification, outbox, and consumer
-- offset tables are deliberately untouched.

CREATE TABLE IF NOT EXISTS event_failure_transaction_t (
    host_id                  UUID NOT NULL,
    failure_id               UUID NOT NULL,
    projection_name          VARCHAR(128) NOT NULL,
    consumer_group           VARCHAR(255) NOT NULL,
    first_source_processor   VARCHAR(16) NOT NULL,
    original_transaction_id  VARCHAR(255) NOT NULL,
    content_fingerprint      VARCHAR(64) NOT NULL,
    event_count              INTEGER NOT NULL,
    encrypted_payload_bytes  BIGINT NOT NULL DEFAULT 0,
    decrypted_payload_bytes  BIGINT NOT NULL DEFAULT 0,
    dependency_scopes        JSONB NOT NULL DEFAULT '[]'::jsonb,
    status                   VARCHAR(16) NOT NULL DEFAULT 'OPEN',
    error_type               VARCHAR(255),
    error_code               VARCHAR(128),
    error_message            VARCHAR(2048),
    failure_count            INTEGER NOT NULL DEFAULT 1,
    first_failed_ts          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_failed_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_ts              TIMESTAMPTZ,
    resolved_by_request_id   UUID,
    legal_hold               BOOLEAN NOT NULL DEFAULT FALSE,
    created_ts               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_failure_transaction_pk PRIMARY KEY(host_id, failure_id),
    CONSTRAINT event_failure_transaction_host_fk FOREIGN KEY(host_id)
        REFERENCES host_t(host_id) ON DELETE RESTRICT,
    CONSTRAINT event_failure_transaction_content_uk UNIQUE(
        host_id, projection_name, consumer_group, content_fingerprint
    ),
    CONSTRAINT event_failure_transaction_processor_ck CHECK(
        first_source_processor IN ('DATABASE', 'KAFKA')
    ),
    CONSTRAINT event_failure_transaction_fingerprint_ck CHECK(
        content_fingerprint ~ '^[0-9a-f]{64}$'
    ),
    CONSTRAINT event_failure_transaction_counts_ck CHECK(
        event_count > 0 AND failure_count > 0
        AND encrypted_payload_bytes >= 0 AND decrypted_payload_bytes >= 0
    ),
    CONSTRAINT event_failure_transaction_scopes_ck CHECK(
        jsonb_typeof(dependency_scopes) = 'array'
    ),
    CONSTRAINT event_failure_transaction_status_ck CHECK(
        status IN ('OPEN', 'RESOLVED', 'WAIVED')
    ),
    CONSTRAINT event_failure_transaction_terminal_ck CHECK(
        (status = 'OPEN' AND resolved_ts IS NULL AND resolved_by_request_id IS NULL)
        OR (status = 'RESOLVED' AND resolved_ts IS NOT NULL AND resolved_by_request_id IS NOT NULL)
        OR (status = 'WAIVED' AND resolved_ts IS NOT NULL AND resolved_by_request_id IS NULL)
    ),
    CONSTRAINT event_failure_transaction_time_ck CHECK(
        last_failed_ts >= first_failed_ts
    )
);

CREATE TABLE IF NOT EXISTS event_failure_delivery_t (
    host_id                 UUID NOT NULL,
    delivery_id             UUID NOT NULL,
    failure_id              UUID NOT NULL,
    delivery_fingerprint    VARCHAR(64) NOT NULL,
    source_processor        VARCHAR(16) NOT NULL,
    source_coordinates      JSONB NOT NULL,
    observation_count       INTEGER NOT NULL DEFAULT 1,
    first_observed_ts       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_observed_ts        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_failure_delivery_pk PRIMARY KEY(host_id, delivery_id),
    CONSTRAINT event_failure_delivery_failure_fk FOREIGN KEY(host_id, failure_id)
        REFERENCES event_failure_transaction_t(host_id, failure_id) ON DELETE RESTRICT,
    CONSTRAINT event_failure_delivery_fingerprint_uk UNIQUE(
        host_id, failure_id, delivery_fingerprint
    ),
    CONSTRAINT event_failure_delivery_fingerprint_ck CHECK(
        delivery_fingerprint ~ '^[0-9a-f]{64}$'
    ),
    CONSTRAINT event_failure_delivery_processor_ck CHECK(
        source_processor IN ('DATABASE', 'KAFKA')
    ),
    CONSTRAINT event_failure_delivery_coordinates_ck CHECK(
        jsonb_typeof(source_coordinates) = 'object'
    ),
    CONSTRAINT event_failure_delivery_count_ck CHECK(observation_count > 0),
    CONSTRAINT event_failure_delivery_time_ck CHECK(last_observed_ts >= first_observed_ts)
);

CREATE TABLE IF NOT EXISTS event_failure_event_t (
    host_id                UUID NOT NULL,
    failure_id             UUID NOT NULL,
    event_ordinal          INTEGER NOT NULL,
    event_id               VARCHAR(255) NOT NULL,
    event_type             VARCHAR(255) NOT NULL,
    aggregate_id           VARCHAR(255),
    aggregate_type         VARCHAR(255),
    aggregate_version      BIGINT,
    root_instance_id       UUID,
    graph_revision         BIGINT,
    clone_request_id       UUID,
    source_processor       VARCHAR(16) NOT NULL,
    source_topic           VARCHAR(255),
    source_partition       INTEGER,
    source_offset          BIGINT NOT NULL,
    source_key             BYTEA,
    source_headers         JSONB NOT NULL DEFAULT '[]'::jsonb,
    payload_format         VARCHAR(32) NOT NULL,
    payload_digest         VARCHAR(64) NOT NULL,
    payload_storage        VARCHAR(16) NOT NULL,
    payload_ciphertext     BYTEA,
    payload_object_uri     VARCHAR(2048),
    payload_object_version VARCHAR(255),
    payload_key_id         VARCHAR(255),
    payload_wrapped_key    BYTEA,
    payload_iv             BYTEA,
    encrypted_payload_bytes BIGINT NOT NULL,
    decrypted_payload_bytes BIGINT NOT NULL,
    sensitive_payload      BOOLEAN NOT NULL DEFAULT FALSE,
    payload_deleted_ts     TIMESTAMPTZ,
    payload_deleted_reason VARCHAR(1024),
    created_ts             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_failure_event_pk PRIMARY KEY(host_id, failure_id, event_ordinal),
    CONSTRAINT event_failure_event_failure_fk FOREIGN KEY(host_id, failure_id)
        REFERENCES event_failure_transaction_t(host_id, failure_id) ON DELETE RESTRICT,
    CONSTRAINT event_failure_event_ordinal_ck CHECK(event_ordinal >= 0),
    CONSTRAINT event_failure_event_versions_ck CHECK(
        (aggregate_version IS NULL OR aggregate_version >= 0)
        AND (graph_revision IS NULL OR graph_revision >= 0)
    ),
    CONSTRAINT event_failure_event_processor_ck CHECK(
        source_processor IN ('DATABASE', 'KAFKA')
    ),
    CONSTRAINT event_failure_event_source_ck CHECK(
        source_offset >= 0 AND (source_partition IS NULL OR source_partition >= 0)
    ),
    CONSTRAINT event_failure_event_coordinates_ck CHECK(
        (source_processor = 'DATABASE' AND source_topic IS NULL AND source_partition IS NOT NULL)
        OR (source_processor = 'KAFKA' AND source_topic IS NOT NULL AND source_partition IS NOT NULL)
    ),
    CONSTRAINT event_failure_event_headers_ck CHECK(
        jsonb_typeof(source_headers) = 'array'
    ),
    CONSTRAINT event_failure_event_digest_ck CHECK(
        payload_digest ~ '^[0-9a-f]{64}$'
    ),
    CONSTRAINT event_failure_event_payload_storage_ck CHECK(
        (payload_storage = 'DATABASE'
            AND payload_ciphertext IS NOT NULL
            AND payload_object_uri IS NULL
            AND payload_object_version IS NULL
            AND payload_key_id IS NOT NULL
            AND payload_wrapped_key IS NOT NULL
            AND payload_iv IS NOT NULL
            AND payload_deleted_ts IS NULL
            AND payload_deleted_reason IS NULL)
        OR (payload_storage = 'OBJECT'
            AND payload_ciphertext IS NULL
            AND payload_object_uri IS NOT NULL
            AND payload_object_version IS NOT NULL
            AND payload_key_id IS NOT NULL
            AND payload_wrapped_key IS NOT NULL
            AND payload_iv IS NOT NULL
            AND payload_deleted_ts IS NULL
            AND payload_deleted_reason IS NULL)
        OR (payload_storage = 'DELETED'
            AND payload_ciphertext IS NULL
            AND payload_object_uri IS NULL
            AND payload_object_version IS NULL
            AND payload_key_id IS NULL
            AND payload_wrapped_key IS NULL
            AND payload_iv IS NULL
            AND payload_deleted_ts IS NOT NULL
            AND length(btrim(payload_deleted_reason)) > 0)
    ),
    CONSTRAINT event_failure_event_crypto_ck CHECK(
        payload_storage = 'DELETED'
        OR (octet_length(payload_iv) = 12 AND octet_length(payload_wrapped_key) > 0)
    ),
    CONSTRAINT event_failure_event_bytes_ck CHECK(
        encrypted_payload_bytes >= 0 AND decrypted_payload_bytes >= 0
    )
);

CREATE TABLE IF NOT EXISTS event_replay_request_t (
    host_id                    UUID NOT NULL,
    replay_request_id          UUID NOT NULL,
    projection_name            VARCHAR(128) NOT NULL,
    consumer_group             VARCHAR(255) NOT NULL,
    selection_strategy         VARCHAR(32) NOT NULL,
    validation_mode            VARCHAR(32) NOT NULL,
    reason                     VARCHAR(2048) NOT NULL,
    plan_hash                  VARCHAR(64),
    policy_registry_version    VARCHAR(64) NOT NULL,
    plan_metadata              JSONB NOT NULL DEFAULT '{}'::jsonb,
    status                     VARCHAR(32) NOT NULL DEFAULT 'PLANNING',
    transaction_count          INTEGER NOT NULL DEFAULT 0,
    event_count                INTEGER NOT NULL DEFAULT 0,
    encrypted_payload_bytes    BIGINT NOT NULL DEFAULT 0,
    decrypted_payload_bytes    BIGINT NOT NULL DEFAULT 0,
    requested_by               VARCHAR(255) NOT NULL,
    requested_ts               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_by                VARCHAR(255),
    approved_ts                TIMESTAMPTZ,
    started_by                 VARCHAR(255),
    started_ts                 TIMESTAMPTZ,
    completed_ts               TIMESTAMPTZ,
    expires_ts                 TIMESTAMPTZ NOT NULL,
    failure_code               VARCHAR(128),
    failure_message            VARCHAR(2048),
    fencing_token              BIGINT NOT NULL DEFAULT 0,
    isolation_mode             VARCHAR(32),
    installed_barrier_epoch    BIGINT,
    created_ts                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_replay_request_pk PRIMARY KEY(host_id, replay_request_id),
    CONSTRAINT event_replay_request_host_fk FOREIGN KEY(host_id)
        REFERENCES host_t(host_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_request_strategy_ck CHECK(
        selection_strategy IN ('EXACT', 'DEPENDENCY_CLOSURE')
    ),
    CONSTRAINT event_replay_request_mode_ck CHECK(
        validation_mode IN ('VALIDATE_ONLY', 'ROLLBACK_DRY_RUN', 'EXECUTE')
    ),
    CONSTRAINT event_replay_request_reason_ck CHECK(length(btrim(reason)) > 0),
    CONSTRAINT event_replay_request_plan_hash_ck CHECK(
        plan_hash IS NULL OR plan_hash ~ '^[0-9a-f]{64}$'
    ),
    CONSTRAINT event_replay_request_metadata_ck CHECK(jsonb_typeof(plan_metadata) = 'object'),
    CONSTRAINT event_replay_request_status_ck CHECK(
        status IN ('PLANNING', 'READY', 'AWAITING_APPROVAL', 'APPROVED',
                   'INSTALLING_BARRIER', 'RUNNING', 'SUCCEEDED', 'FAILED',
                   'CANCELLED', 'EXPIRED')
    ),
    CONSTRAINT event_replay_request_counts_ck CHECK(
        transaction_count >= 0 AND event_count >= 0
        AND encrypted_payload_bytes >= 0 AND decrypted_payload_bytes >= 0
    ),
    CONSTRAINT event_replay_request_planned_ck CHECK(
        status = 'PLANNING'
        OR status = 'FAILED'
        OR (plan_hash IS NOT NULL AND transaction_count > 0 AND event_count > 0)
    ),
    CONSTRAINT event_replay_request_approval_ck CHECK(
        (approved_by IS NULL) = (approved_ts IS NULL)
        AND (status NOT IN ('APPROVED', 'INSTALLING_BARRIER', 'RUNNING', 'SUCCEEDED')
             OR approved_ts IS NOT NULL)
    ),
    CONSTRAINT event_replay_request_started_ck CHECK(
        (started_by IS NULL) = (started_ts IS NULL)
        AND (status NOT IN ('RUNNING', 'SUCCEEDED') OR started_ts IS NOT NULL)
    ),
    CONSTRAINT event_replay_request_completed_ck CHECK(
        (status IN ('SUCCEEDED', 'FAILED', 'CANCELLED', 'EXPIRED')) = (completed_ts IS NOT NULL)
    ),
    CONSTRAINT event_replay_request_expiry_ck CHECK(expires_ts > requested_ts),
    CONSTRAINT event_replay_request_fence_ck CHECK(
        fencing_token >= 0 AND (installed_barrier_epoch IS NULL OR installed_barrier_epoch > 0)
    ),
    CONSTRAINT event_replay_request_isolation_ck CHECK(
        isolation_mode IS NULL OR isolation_mode IN (
            'GRAPH_ROOT', 'AGGREGATE', 'HOST', 'DB_PARTITION',
            'KAFKA_PARTITION', 'PROJECTION'
        )
    )
);

ALTER TABLE event_failure_transaction_t
    DROP CONSTRAINT IF EXISTS event_failure_transaction_resolved_request_fk;
ALTER TABLE event_failure_transaction_t
    ADD CONSTRAINT event_failure_transaction_resolved_request_fk
    FOREIGN KEY(host_id, resolved_by_request_id)
    REFERENCES event_replay_request_t(host_id, replay_request_id) ON DELETE RESTRICT;

CREATE TABLE IF NOT EXISTS event_replay_item_t (
    host_id                    UUID NOT NULL,
    replay_request_id          UUID NOT NULL,
    item_ordinal               INTEGER NOT NULL,
    failure_id                 UUID NOT NULL,
    expected_content_fingerprint VARCHAR(64) NOT NULL,
    dependency_reason          VARCHAR(1024) NOT NULL,
    added_dependency           BOOLEAN NOT NULL DEFAULT FALSE,
    status                     VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    attempt_count              INTEGER NOT NULL DEFAULT 0,
    current_fencing_token      BIGINT NOT NULL DEFAULT 0,
    created_ts                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_replay_item_pk PRIMARY KEY(host_id, replay_request_id, item_ordinal),
    CONSTRAINT event_replay_item_request_fk FOREIGN KEY(host_id, replay_request_id)
        REFERENCES event_replay_request_t(host_id, replay_request_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_item_failure_fk FOREIGN KEY(host_id, failure_id)
        REFERENCES event_failure_transaction_t(host_id, failure_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_item_failure_uk UNIQUE(host_id, replay_request_id, failure_id),
    CONSTRAINT event_replay_item_ordinal_ck CHECK(item_ordinal >= 0),
    CONSTRAINT event_replay_item_fingerprint_ck CHECK(
        expected_content_fingerprint ~ '^[0-9a-f]{64}$'
    ),
    CONSTRAINT event_replay_item_reason_ck CHECK(length(btrim(dependency_reason)) > 0),
    CONSTRAINT event_replay_item_status_ck CHECK(
        status IN ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED')
    ),
    CONSTRAINT event_replay_item_attempt_ck CHECK(
        attempt_count >= 0 AND current_fencing_token >= 0
    )
);

CREATE TABLE IF NOT EXISTS event_replay_attempt_t (
    host_id                    UUID NOT NULL,
    replay_attempt_id          UUID NOT NULL,
    replay_request_id          UUID NOT NULL,
    item_ordinal               INTEGER NOT NULL,
    attempt_number             INTEGER NOT NULL,
    worker_id                  VARCHAR(255) NOT NULL,
    fencing_token              BIGINT NOT NULL,
    started_ts                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_ts               TIMESTAMPTZ,
    result                     VARCHAR(16) NOT NULL DEFAULT 'RUNNING',
    projection_committed       BOOLEAN NOT NULL DEFAULT FALSE,
    pre_projection_metadata    JSONB NOT NULL DEFAULT '{}'::jsonb,
    post_projection_metadata   JSONB NOT NULL DEFAULT '{}'::jsonb,
    error_code                 VARCHAR(128),
    error_message              VARCHAR(2048),
    created_ts                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_replay_attempt_pk PRIMARY KEY(host_id, replay_attempt_id),
    CONSTRAINT event_replay_attempt_item_fk FOREIGN KEY(host_id, replay_request_id, item_ordinal)
        REFERENCES event_replay_item_t(host_id, replay_request_id, item_ordinal) ON DELETE RESTRICT,
    CONSTRAINT event_replay_attempt_number_uk UNIQUE(
        host_id, replay_request_id, item_ordinal, attempt_number
    ),
    CONSTRAINT event_replay_attempt_number_ck CHECK(attempt_number > 0 AND fencing_token >= 0),
    CONSTRAINT event_replay_attempt_result_ck CHECK(
        result IN ('RUNNING', 'SUCCEEDED', 'FAILED', 'ABANDONED')
    ),
    CONSTRAINT event_replay_attempt_terminal_ck CHECK(
        (result = 'RUNNING' AND completed_ts IS NULL AND projection_committed = FALSE)
        OR (result <> 'RUNNING' AND completed_ts IS NOT NULL)
    ),
    CONSTRAINT event_replay_attempt_metadata_ck CHECK(
        jsonb_typeof(pre_projection_metadata) = 'object'
        AND jsonb_typeof(post_projection_metadata) = 'object'
    )
);

CREATE TABLE IF NOT EXISTS event_replay_lease_t (
    host_id              UUID NOT NULL,
    replay_request_id    UUID NOT NULL,
    lease_owner          VARCHAR(255) NOT NULL,
    lease_epoch          BIGINT NOT NULL,
    fencing_token        BIGINT NOT NULL,
    heartbeat_ts         TIMESTAMPTZ NOT NULL,
    expires_ts           TIMESTAMPTZ NOT NULL,
    created_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_replay_lease_pk PRIMARY KEY(host_id, replay_request_id),
    CONSTRAINT event_replay_lease_request_fk FOREIGN KEY(host_id, replay_request_id)
        REFERENCES event_replay_request_t(host_id, replay_request_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_lease_epoch_ck CHECK(lease_epoch > 0 AND fencing_token >= 0),
    CONSTRAINT event_replay_lease_time_ck CHECK(expires_ts > heartbeat_ts)
);

CREATE TABLE IF NOT EXISTS event_replay_barrier_t (
    host_id                UUID NOT NULL,
    barrier_id             UUID NOT NULL,
    projection_name        VARCHAR(128) NOT NULL,
    consumer_group         VARCHAR(255) NOT NULL,
    scope_type             VARCHAR(32) NOT NULL,
    scope_key              VARCHAR(1024) NOT NULL,
    state                  VARCHAR(16) NOT NULL,
    owner_type             VARCHAR(32) NOT NULL,
    replay_request_id      UUID,
    quarantine_failure_id  UUID,
    barrier_epoch          BIGINT NOT NULL,
    fencing_token          BIGINT NOT NULL DEFAULT 0,
    released_by            VARCHAR(255),
    release_reason         VARCHAR(2048),
    released_ts            TIMESTAMPTZ,
    installed_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_replay_barrier_pk PRIMARY KEY(host_id, barrier_id),
    CONSTRAINT event_replay_barrier_request_fk FOREIGN KEY(host_id, replay_request_id)
        REFERENCES event_replay_request_t(host_id, replay_request_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_barrier_failure_fk FOREIGN KEY(host_id, quarantine_failure_id)
        REFERENCES event_failure_transaction_t(host_id, failure_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_barrier_scope_ck CHECK(
        scope_type IN ('GRAPH_ROOT', 'AGGREGATE', 'HOST', 'DB_PARTITION',
                       'KAFKA_PARTITION', 'PROJECTION')
        AND length(btrim(scope_key)) > 0
    ),
    CONSTRAINT event_replay_barrier_state_ck CHECK(
        state IN ('INSTALLING', 'ACTIVE', 'DRAINING', 'QUARANTINED')
    ),
    CONSTRAINT event_replay_barrier_owner_ck CHECK(
        (owner_type = 'REPLAY_REQUEST'
            AND state <> 'QUARANTINED'
            AND replay_request_id IS NOT NULL
            AND quarantine_failure_id IS NULL)
        OR (owner_type = 'FAILURE_QUARANTINE'
            AND state = 'QUARANTINED'
            AND replay_request_id IS NULL
            AND quarantine_failure_id IS NOT NULL)
    ),
    CONSTRAINT event_replay_barrier_epoch_ck CHECK(barrier_epoch > 0 AND fencing_token >= 0),
    CONSTRAINT event_replay_barrier_release_ck CHECK(
        (released_ts IS NULL AND released_by IS NULL AND release_reason IS NULL)
        OR (released_ts IS NOT NULL AND released_by IS NOT NULL
            AND release_reason IS NOT NULL AND length(btrim(release_reason)) > 0)
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS event_replay_barrier_active_scope_uk
    ON event_replay_barrier_t(host_id, projection_name, consumer_group, scope_type, scope_key)
    WHERE released_ts IS NULL;

CREATE TABLE IF NOT EXISTS event_projection_deferred_t (
    host_id                  UUID NOT NULL,
    deferred_id              UUID NOT NULL,
    barrier_id               UUID NOT NULL,
    failure_id               UUID,
    original_transaction_id  VARCHAR(255) NOT NULL,
    content_fingerprint      VARCHAR(64) NOT NULL,
    source_processor         VARCHAR(16) NOT NULL,
    source_order_key         VARCHAR(1024) NOT NULL,
    source_coordinates       JSONB NOT NULL,
    event_count              INTEGER NOT NULL,
    encrypted_payload_bytes  BIGINT NOT NULL,
    decrypted_payload_bytes  BIGINT NOT NULL,
    dependency_scopes        JSONB NOT NULL DEFAULT '[]'::jsonb,
    payload_digest           VARCHAR(64) NOT NULL,
    payload_storage          VARCHAR(16) NOT NULL,
    payload_ciphertext       BYTEA,
    payload_object_uri       VARCHAR(2048),
    payload_object_version   VARCHAR(255),
    payload_key_id           VARCHAR(255) NOT NULL,
    payload_wrapped_key      BYTEA NOT NULL,
    payload_iv               BYTEA NOT NULL,
    status                   VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    attempt_count            INTEGER NOT NULL DEFAULT 0,
    error_code               VARCHAR(128),
    error_message            VARCHAR(2048),
    deferred_ts              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_ts             TIMESTAMPTZ,
    created_ts               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_projection_deferred_pk PRIMARY KEY(host_id, deferred_id),
    CONSTRAINT event_projection_deferred_barrier_fk FOREIGN KEY(host_id, barrier_id)
        REFERENCES event_replay_barrier_t(host_id, barrier_id) ON DELETE RESTRICT,
    CONSTRAINT event_projection_deferred_failure_fk FOREIGN KEY(host_id, failure_id)
        REFERENCES event_failure_transaction_t(host_id, failure_id) ON DELETE RESTRICT,
    CONSTRAINT event_projection_deferred_order_uk UNIQUE(host_id, barrier_id, source_order_key),
    CONSTRAINT event_projection_deferred_content_uk UNIQUE(host_id, barrier_id, content_fingerprint),
    CONSTRAINT event_projection_deferred_fingerprint_ck CHECK(
        content_fingerprint ~ '^[0-9a-f]{64}$' AND payload_digest ~ '^[0-9a-f]{64}$'
    ),
    CONSTRAINT event_projection_deferred_processor_ck CHECK(
        source_processor IN ('DATABASE', 'KAFKA')
        AND jsonb_typeof(source_coordinates) = 'object'
    ),
    CONSTRAINT event_projection_deferred_counts_ck CHECK(
        event_count > 0 AND encrypted_payload_bytes >= 0
        AND decrypted_payload_bytes >= 0 AND attempt_count >= 0
        AND jsonb_typeof(dependency_scopes) = 'array'
    ),
    CONSTRAINT event_projection_deferred_payload_storage_ck CHECK(
        (payload_storage = 'DATABASE'
            AND payload_ciphertext IS NOT NULL
            AND payload_object_uri IS NULL
            AND payload_object_version IS NULL)
        OR (payload_storage = 'OBJECT'
            AND payload_ciphertext IS NULL
            AND payload_object_uri IS NOT NULL
            AND payload_object_version IS NOT NULL)
    ),
    CONSTRAINT event_projection_deferred_crypto_ck CHECK(
        octet_length(payload_iv) = 12 AND octet_length(payload_wrapped_key) > 0
    ),
    CONSTRAINT event_projection_deferred_status_ck CHECK(
        status IN ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED')
    ),
    CONSTRAINT event_projection_deferred_terminal_ck CHECK(
        (status IN ('PENDING', 'RUNNING') AND completed_ts IS NULL AND failure_id IS NULL)
        OR (status = 'SUCCEEDED' AND completed_ts IS NOT NULL AND failure_id IS NULL)
        OR (status = 'FAILED' AND completed_ts IS NOT NULL AND failure_id IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS event_projection_deferred_scope_t (
    host_id      UUID NOT NULL,
    deferred_id  UUID NOT NULL,
    barrier_id   UUID NOT NULL,
    created_ts   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_projection_deferred_scope_pk PRIMARY KEY(host_id, deferred_id, barrier_id),
    CONSTRAINT event_projection_deferred_scope_deferred_fk FOREIGN KEY(host_id, deferred_id)
        REFERENCES event_projection_deferred_t(host_id, deferred_id) ON DELETE RESTRICT,
    CONSTRAINT event_projection_deferred_scope_barrier_fk FOREIGN KEY(host_id, barrier_id)
        REFERENCES event_replay_barrier_t(host_id, barrier_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS event_projection_control_t (
    host_id              UUID NOT NULL,
    control_id           UUID NOT NULL,
    projection_name      VARCHAR(128) NOT NULL,
    consumer_group       VARCHAR(255) NOT NULL,
    scope_type           VARCHAR(32) NOT NULL,
    scope_key            VARCHAR(1024) NOT NULL,
    requested_state      VARCHAR(32) NOT NULL,
    control_epoch        BIGINT NOT NULL,
    replay_request_id    UUID,
    acknowledgement_deadline_ts TIMESTAMPTZ,
    created_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_projection_control_pk PRIMARY KEY(host_id, control_id),
    CONSTRAINT event_projection_control_request_fk FOREIGN KEY(host_id, replay_request_id)
        REFERENCES event_replay_request_t(host_id, replay_request_id) ON DELETE RESTRICT,
    CONSTRAINT event_projection_control_scope_uk UNIQUE(
        host_id, projection_name, consumer_group, scope_type, scope_key
    ),
    CONSTRAINT event_projection_control_scope_ck CHECK(
        scope_type IN ('HOST', 'DB_PARTITION', 'KAFKA_PARTITION', 'PROJECTION')
        AND length(btrim(scope_key)) > 0
    ),
    CONSTRAINT event_projection_control_state_ck CHECK(
        requested_state IN ('RUNNING', 'PAUSE_REQUESTED', 'PAUSED_FOR_REPLAY', 'RESUME_REQUESTED')
    ),
    CONSTRAINT event_projection_control_owner_ck CHECK(
        (requested_state = 'RUNNING' AND replay_request_id IS NULL)
        OR (requested_state <> 'RUNNING' AND replay_request_id IS NOT NULL)
    ),
    CONSTRAINT event_projection_control_epoch_ck CHECK(control_epoch >= 0)
);

CREATE TABLE IF NOT EXISTS event_projection_worker_t (
    host_id              UUID NOT NULL,
    worker_id            VARCHAR(255) NOT NULL,
    projection_name      VARCHAR(128) NOT NULL,
    consumer_group       VARCHAR(255) NOT NULL,
    source_processor     VARCHAR(16) NOT NULL,
    source_partition_key VARCHAR(512) NOT NULL,
    control_id           UUID,
    observed_epoch       BIGINT NOT NULL DEFAULT 0,
    acknowledged_epoch   BIGINT NOT NULL DEFAULT 0,
    state                VARCHAR(16) NOT NULL DEFAULT 'RUNNING',
    assignment_metadata  JSONB NOT NULL DEFAULT '{}'::jsonb,
    heartbeat_ts         TIMESTAMPTZ NOT NULL,
    created_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_projection_worker_pk PRIMARY KEY(host_id, worker_id),
    CONSTRAINT event_projection_worker_host_fk FOREIGN KEY(host_id)
        REFERENCES host_t(host_id) ON DELETE RESTRICT,
    CONSTRAINT event_projection_worker_control_fk FOREIGN KEY(host_id, control_id)
        REFERENCES event_projection_control_t(host_id, control_id) ON DELETE RESTRICT,
    CONSTRAINT event_projection_worker_assignment_uk UNIQUE(
        host_id, projection_name, consumer_group, source_processor, source_partition_key, worker_id
    ),
    CONSTRAINT event_projection_worker_processor_ck CHECK(
        source_processor IN ('DATABASE', 'KAFKA')
    ),
    CONSTRAINT event_projection_worker_epoch_ck CHECK(
        observed_epoch >= 0 AND acknowledged_epoch >= 0
        AND acknowledged_epoch <= observed_epoch
    ),
    CONSTRAINT event_projection_worker_state_ck CHECK(
        state IN ('RUNNING', 'PAUSING', 'PAUSED', 'STOPPED')
    ),
    CONSTRAINT event_projection_worker_control_state_ck CHECK(
        state NOT IN ('PAUSING', 'PAUSED') OR control_id IS NOT NULL
    ),
    CONSTRAINT event_projection_worker_metadata_ck CHECK(
        jsonb_typeof(assignment_metadata) = 'object'
    )
);

CREATE TABLE IF NOT EXISTS event_failure_publish_outbox_t (
    host_id              UUID NOT NULL,
    publication_id       UUID NOT NULL,
    failure_id           UUID NOT NULL,
    envelope_version     VARCHAR(64) NOT NULL,
    target_topic         VARCHAR(255) NOT NULL,
    status               VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    attempt_count        INTEGER NOT NULL DEFAULT 0,
    next_attempt_ts      TIMESTAMPTZ,
    first_error_ts       TIMESTAMPTZ,
    last_error_ts        TIMESTAMPTZ,
    error_code           VARCHAR(128),
    error_message        VARCHAR(2048),
    published_ts         TIMESTAMPTZ,
    created_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_failure_publish_outbox_pk PRIMARY KEY(host_id, publication_id),
    CONSTRAINT event_failure_publish_outbox_failure_topic_uq
        UNIQUE(host_id, failure_id, envelope_version, target_topic),
    CONSTRAINT event_failure_publish_outbox_failure_fk FOREIGN KEY(host_id, failure_id)
        REFERENCES event_failure_transaction_t(host_id, failure_id) ON DELETE RESTRICT,
    CONSTRAINT event_failure_publish_outbox_status_ck CHECK(
        status IN ('PENDING', 'RETRY_WAIT', 'PUBLISHED', 'TERMINAL_FAILED')
    ),
    CONSTRAINT event_failure_publish_outbox_attempt_ck CHECK(attempt_count >= 0),
    CONSTRAINT event_failure_publish_outbox_retry_ck CHECK(
        (status = 'PENDING' AND next_attempt_ts IS NULL AND published_ts IS NULL)
        OR (status = 'RETRY_WAIT' AND next_attempt_ts IS NOT NULL AND published_ts IS NULL)
        OR (status = 'PUBLISHED' AND next_attempt_ts IS NULL AND published_ts IS NOT NULL)
        OR (status = 'TERMINAL_FAILED' AND next_attempt_ts IS NULL AND published_ts IS NULL)
    ),
    CONSTRAINT event_failure_publish_outbox_error_time_ck CHECK(
        (first_error_ts IS NULL AND last_error_ts IS NULL)
        OR (first_error_ts IS NOT NULL AND last_error_ts IS NOT NULL
            AND last_error_ts >= first_error_ts)
    )
);

CREATE TABLE IF NOT EXISTS event_replay_action_request_t (
    host_id              UUID NOT NULL,
    action_request_id    UUID NOT NULL,
    action_type          VARCHAR(32) NOT NULL,
    status               VARCHAR(32) NOT NULL DEFAULT 'AWAITING_APPROVAL',
    target_ids           JSONB NOT NULL,
    expected_state       JSONB NOT NULL,
    reason               VARCHAR(2048) NOT NULL,
    requested_by         VARCHAR(255) NOT NULL,
    requested_ts         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_by          VARCHAR(255),
    approved_ts          TIMESTAMPTZ,
    completed_ts         TIMESTAMPTZ,
    expires_ts           TIMESTAMPTZ NOT NULL,
    created_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_replay_action_request_pk PRIMARY KEY(host_id, action_request_id),
    CONSTRAINT event_replay_action_request_host_fk FOREIGN KEY(host_id)
        REFERENCES host_t(host_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_action_request_type_ck CHECK(
        action_type IN ('WAIVE_FAILURES', 'RELEASE_WITH_GAP')
    ),
    CONSTRAINT event_replay_action_request_status_ck CHECK(
        status IN ('AWAITING_APPROVAL', 'COMPLETED', 'CANCELLED', 'EXPIRED')
    ),
    CONSTRAINT event_replay_action_request_json_ck CHECK(
        jsonb_typeof(target_ids) = 'array' AND jsonb_array_length(target_ids) > 0
        AND jsonb_typeof(expected_state) = 'object'
    ),
    CONSTRAINT event_replay_action_request_reason_ck CHECK(length(btrim(reason)) > 0),
    CONSTRAINT event_replay_action_request_approval_ck CHECK(
        (approved_by IS NULL) = (approved_ts IS NULL)
        AND (status <> 'COMPLETED' OR (approved_ts IS NOT NULL AND completed_ts IS NOT NULL))
    ),
    CONSTRAINT event_replay_action_request_expiry_ck CHECK(expires_ts > requested_ts)
);

CREATE TABLE IF NOT EXISTS event_replay_audit_t (
    host_id              UUID NOT NULL,
    audit_id             UUID NOT NULL,
    event_name           VARCHAR(128) NOT NULL,
    actor_type           VARCHAR(32) NOT NULL,
    actor_id             VARCHAR(255) NOT NULL,
    replay_request_id    UUID,
    failure_id           UUID,
    barrier_id           UUID,
    reason               VARCHAR(2048),
    details              JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_ts           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_replay_audit_pk PRIMARY KEY(host_id, audit_id),
    CONSTRAINT event_replay_audit_host_fk FOREIGN KEY(host_id)
        REFERENCES host_t(host_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_audit_request_fk FOREIGN KEY(host_id, replay_request_id)
        REFERENCES event_replay_request_t(host_id, replay_request_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_audit_failure_fk FOREIGN KEY(host_id, failure_id)
        REFERENCES event_failure_transaction_t(host_id, failure_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_audit_barrier_fk FOREIGN KEY(host_id, barrier_id)
        REFERENCES event_replay_barrier_t(host_id, barrier_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_audit_actor_ck CHECK(
        actor_type IN ('USER', 'WORKER', 'SYSTEM') AND length(btrim(actor_id)) > 0
    ),
    CONSTRAINT event_replay_audit_reason_ck CHECK(
        reason IS NULL OR length(btrim(reason)) > 0
    ),
    CONSTRAINT event_replay_audit_details_ck CHECK(jsonb_typeof(details) = 'object')
);

CREATE TABLE IF NOT EXISTS event_replay_retention_log_t (
    host_id UUID, retention_id UUID NOT NULL, subject_type VARCHAR(32) NOT NULL,
    subject_id VARCHAR(255) NOT NULL, outcome VARCHAR(32) NOT NULL, reason VARCHAR(1024) NOT NULL,
    details JSONB NOT NULL DEFAULT '{}'::jsonb, created_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_replay_retention_log_pk PRIMARY KEY(retention_id),
    CONSTRAINT event_replay_retention_log_host_fk FOREIGN KEY(host_id)
        REFERENCES host_t(host_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_retention_log_subject_ck CHECK(
        subject_type IN ('PAYLOAD','FAILURE_METADATA','REPLAY_METADATA','AUDIT','PUBLICATION_OUTBOX','OBJECT_RECONCILIATION')
        AND length(btrim(subject_id)) > 0),
    CONSTRAINT event_replay_retention_log_outcome_ck CHECK(
        outcome IN ('DELETED','SKIPPED_LEGAL_HOLD','SKIPPED_ACTIVE','FAILED','ORPHAN_DELETED')),
    CONSTRAINT event_replay_retention_log_reason_ck CHECK(length(btrim(reason)) > 0),
    CONSTRAINT event_replay_retention_log_details_ck CHECK(jsonb_typeof(details) = 'object')
);

CREATE TABLE IF NOT EXISTS event_replay_backfill_checkpoint_t (
    job_name VARCHAR(128) NOT NULL, source_processor VARCHAR(16) NOT NULL,
    cursor_offset BIGINT NOT NULL DEFAULT -1,
    cursor_host_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
    cursor_consumer_group VARCHAR(255) NOT NULL DEFAULT '', cursor_transaction_id VARCHAR(255) NOT NULL DEFAULT '',
    status VARCHAR(16) NOT NULL DEFAULT 'READY', examined_transactions BIGINT NOT NULL DEFAULT 0,
    indexed_transactions BIGINT NOT NULL DEFAULT 0, unresolved_transactions BIGINT NOT NULL DEFAULT 0,
    change_ticket VARCHAR(255) NOT NULL, scope_digest CHAR(64) NOT NULL,
    last_worker_id VARCHAR(255), last_error_code VARCHAR(128),
    last_error_message VARCHAR(2048), created_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, completed_ts TIMESTAMPTZ,
    CONSTRAINT event_replay_backfill_checkpoint_pk PRIMARY KEY(job_name),
    CONSTRAINT event_replay_backfill_checkpoint_source_ck CHECK(source_processor IN ('DATABASE','KAFKA')),
    CONSTRAINT event_replay_backfill_checkpoint_status_ck CHECK(status IN ('READY','RUNNING','COMPLETED','FAILED')),
    CONSTRAINT event_replay_backfill_checkpoint_counts_ck CHECK(examined_transactions>=0 AND indexed_transactions>=0 AND unresolved_transactions>=0 AND indexed_transactions+unresolved_transactions<=examined_transactions),
    CONSTRAINT event_replay_backfill_checkpoint_ticket_ck CHECK(length(btrim(change_ticket))>0),
    CONSTRAINT event_replay_backfill_checkpoint_scope_ck CHECK(scope_digest~'^[0-9a-f]{64}$'),
    CONSTRAINT event_replay_backfill_checkpoint_error_ck CHECK((status<>'FAILED' AND last_error_code IS NULL AND last_error_message IS NULL) OR (status='FAILED' AND last_error_code IS NOT NULL AND last_error_message IS NOT NULL))
);
CREATE TABLE IF NOT EXISTS event_replay_backfill_issue_t (
    job_name VARCHAR(128) NOT NULL, issue_id UUID NOT NULL, host_id UUID NOT NULL,
    source_processor VARCHAR(16) NOT NULL, consumer_group VARCHAR(255) NOT NULL,
    transaction_id VARCHAR(255) NOT NULL, error_code VARCHAR(128) NOT NULL,
    error_message VARCHAR(2048) NOT NULL, observation_count INTEGER NOT NULL DEFAULT 1,
    first_observed_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_observed_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_ts TIMESTAMPTZ, resolution VARCHAR(2048),
    CONSTRAINT event_replay_backfill_issue_pk PRIMARY KEY(job_name,issue_id),
    CONSTRAINT event_replay_backfill_issue_job_fk FOREIGN KEY(job_name) REFERENCES event_replay_backfill_checkpoint_t(job_name) ON DELETE RESTRICT,
    CONSTRAINT event_replay_backfill_issue_host_fk FOREIGN KEY(host_id) REFERENCES host_t(host_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_backfill_issue_source_ck CHECK(source_processor IN ('DATABASE','KAFKA')),
    CONSTRAINT event_replay_backfill_issue_count_ck CHECK(observation_count>0),
    CONSTRAINT event_replay_backfill_issue_resolution_ck CHECK((resolved_ts IS NULL AND resolution IS NULL) OR (resolved_ts IS NOT NULL AND length(btrim(resolution))>0)),
    CONSTRAINT event_replay_backfill_issue_uk UNIQUE(job_name,source_processor,host_id,consumer_group,transaction_id,error_code)
);
CREATE TABLE IF NOT EXISTS event_replay_rollout_audit_t (
    host_id UUID, rollout_audit_id UUID NOT NULL, stage VARCHAR(32) NOT NULL,
    outcome VARCHAR(32) NOT NULL, change_ticket VARCHAR(255) NOT NULL,
    actor_id VARCHAR(255) NOT NULL, config_digest VARCHAR(64) NOT NULL,
    evidence JSONB NOT NULL DEFAULT '{}'::jsonb, created_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_replay_rollout_audit_pk PRIMARY KEY(rollout_audit_id),
    CONSTRAINT event_replay_rollout_audit_host_fk FOREIGN KEY(host_id) REFERENCES host_t(host_id) ON DELETE RESTRICT,
    CONSTRAINT event_replay_rollout_audit_stage_ck CHECK(stage IN ('SCHEMA','DATABASE_CAPTURE','KAFKA_CAPTURE','BACKFILL','READ_ONLY','DRY_RUN','NON_PROD_EXECUTION','PRODUCTION_CANARY','EXPANDED','ROLLBACK')),
    CONSTRAINT event_replay_rollout_audit_outcome_ck CHECK(outcome IN ('PRECHECK_PASSED','ENABLED','VERIFIED','ROLLED_BACK','FAILED')),
    CONSTRAINT event_replay_rollout_audit_text_ck CHECK(length(btrim(change_ticket))>0 AND length(btrim(actor_id))>0 AND config_digest ~ '^[0-9a-f]{64}$'),
    CONSTRAINT event_replay_rollout_audit_evidence_ck CHECK(jsonb_typeof(evidence)='object')
);

CREATE OR REPLACE FUNCTION protect_event_replay_rollout_audit_v1()
RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
    RAISE EXCEPTION 'event replay rollout evidence is append-only';
END $body$;
CREATE TRIGGER event_replay_rollout_audit_append_guard_v1
BEFORE UPDATE OR DELETE ON event_replay_rollout_audit_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_rollout_audit_v1();

CREATE OR REPLACE FUNCTION protect_event_replay_retention_log_v1()
RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
    RAISE EXCEPTION 'event replay retention evidence is append-only';
END $body$;
CREATE TRIGGER event_replay_retention_log_append_guard_v1
BEFORE UPDATE OR DELETE ON event_replay_retention_log_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_retention_log_v1();

CREATE INDEX IF NOT EXISTS event_failure_open_age_idx
    ON event_failure_transaction_t(host_id, projection_name, consumer_group, last_failed_ts)
    WHERE status = 'OPEN';
CREATE INDEX IF NOT EXISTS event_failure_host_status_idx
    ON event_failure_transaction_t(host_id, status, last_failed_ts DESC);
CREATE INDEX IF NOT EXISTS event_failure_transaction_lookup_idx
    ON event_failure_transaction_t(host_id, original_transaction_id);
CREATE INDEX IF NOT EXISTS event_failure_dependency_scope_idx
    ON event_failure_transaction_t USING GIN(dependency_scopes);
CREATE INDEX IF NOT EXISTS event_failure_retention_idx
    ON event_failure_transaction_t(status, resolved_ts, last_failed_ts);
CREATE INDEX IF NOT EXISTS event_failure_payload_retention_idx
    ON event_failure_transaction_t(status, legal_hold, resolved_ts)
    WHERE status IN ('RESOLVED','WAIVED') AND legal_hold=FALSE;
CREATE INDEX IF NOT EXISTS event_replay_retention_log_created_idx
    ON event_replay_retention_log_t(created_ts);
CREATE INDEX IF NOT EXISTS event_replay_backfill_checkpoint_status_idx
    ON event_replay_backfill_checkpoint_t(status,updated_ts);
CREATE INDEX IF NOT EXISTS event_replay_backfill_issue_open_idx
    ON event_replay_backfill_issue_t(job_name,last_observed_ts) WHERE resolved_ts IS NULL;
CREATE INDEX IF NOT EXISTS event_replay_rollout_audit_ticket_idx
    ON event_replay_rollout_audit_t(change_ticket,created_ts DESC);
CREATE INDEX IF NOT EXISTS event_failure_quota_idx
    ON event_failure_transaction_t(host_id, status, encrypted_payload_bytes);
CREATE INDEX IF NOT EXISTS event_failure_delivery_observed_idx
    ON event_failure_delivery_t(host_id, failure_id, last_observed_ts DESC);
CREATE INDEX IF NOT EXISTS event_failure_event_graph_idx
    ON event_failure_event_t(host_id, root_instance_id, graph_revision)
    WHERE root_instance_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS event_failure_event_aggregate_idx
    ON event_failure_event_t(host_id, aggregate_type, aggregate_id, aggregate_version)
    WHERE aggregate_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS event_failure_event_source_idx
    ON event_failure_event_t(source_processor, source_topic, source_partition, source_offset);
CREATE INDEX IF NOT EXISTS event_replay_request_status_idx
    ON event_replay_request_t(host_id, status, requested_ts DESC);
CREATE INDEX IF NOT EXISTS event_replay_request_expiry_idx
    ON event_replay_request_t(expires_ts)
    WHERE status IN ('READY', 'AWAITING_APPROVAL');
CREATE INDEX IF NOT EXISTS event_replay_request_retention_idx
    ON event_replay_request_t(status, completed_ts, created_ts);
CREATE INDEX IF NOT EXISTS event_replay_item_order_idx
    ON event_replay_item_t(host_id, replay_request_id, status, item_ordinal);
CREATE INDEX IF NOT EXISTS event_replay_attempt_history_idx
    ON event_replay_attempt_t(host_id, replay_request_id, item_ordinal, attempt_number DESC);
CREATE INDEX IF NOT EXISTS event_replay_attempt_retention_idx
    ON event_replay_attempt_t(result, completed_ts, created_ts);
CREATE INDEX IF NOT EXISTS event_replay_lease_expiry_idx
    ON event_replay_lease_t(expires_ts);
CREATE INDEX IF NOT EXISTS event_replay_barrier_scope_idx
    ON event_replay_barrier_t(host_id, projection_name, consumer_group, scope_type, scope_key, state)
    WHERE released_ts IS NULL;
CREATE INDEX IF NOT EXISTS event_replay_barrier_quarantine_idx
    ON event_replay_barrier_t(updated_ts)
    WHERE state = 'QUARANTINED' AND released_ts IS NULL;
CREATE INDEX IF NOT EXISTS event_replay_action_request_pending_idx
    ON event_replay_action_request_t(host_id, status, expires_ts)
    WHERE status = 'AWAITING_APPROVAL';
CREATE INDEX IF NOT EXISTS event_projection_deferred_drain_idx
    ON event_projection_deferred_t(host_id, barrier_id, status, source_order_key);
CREATE INDEX IF NOT EXISTS event_projection_deferred_retention_idx
    ON event_projection_deferred_t(status, completed_ts, deferred_ts);
CREATE INDEX IF NOT EXISTS event_projection_deferred_quota_idx
    ON event_projection_deferred_t(host_id, status, encrypted_payload_bytes);
CREATE INDEX IF NOT EXISTS event_projection_deferred_scope_barrier_idx
    ON event_projection_deferred_scope_t(host_id, barrier_id, deferred_id);
CREATE INDEX IF NOT EXISTS event_projection_control_scope_idx
    ON event_projection_control_t(host_id, projection_name, consumer_group, requested_state, control_epoch);
CREATE INDEX IF NOT EXISTS event_projection_worker_ack_idx
    ON event_projection_worker_t(host_id, projection_name, consumer_group, acknowledged_epoch, heartbeat_ts)
    WHERE state IN ('RUNNING', 'PAUSING', 'PAUSED');
CREATE INDEX IF NOT EXISTS event_failure_publish_retry_idx
    ON event_failure_publish_outbox_t(status, next_attempt_ts, created_ts)
    WHERE status IN ('PENDING', 'RETRY_WAIT');
CREATE UNIQUE INDEX IF NOT EXISTS event_failure_publish_active_uk
    ON event_failure_publish_outbox_t(host_id, failure_id, envelope_version)
    WHERE status IN ('PENDING', 'RETRY_WAIT');
CREATE INDEX IF NOT EXISTS event_failure_publish_retention_idx
    ON event_failure_publish_outbox_t(status, published_ts, updated_ts);
CREATE INDEX IF NOT EXISTS event_failure_publish_quota_idx
    ON event_failure_publish_outbox_t(host_id, status, created_ts);
CREATE INDEX IF NOT EXISTS event_replay_audit_subject_idx
    ON event_replay_audit_t(host_id, replay_request_id, failure_id, created_ts DESC);
CREATE INDEX IF NOT EXISTS event_replay_audit_retention_idx
    ON event_replay_audit_t(created_ts);

CREATE OR REPLACE FUNCTION validate_event_failure_members_v1()
RETURNS trigger LANGUAGE plpgsql AS '
DECLARE
    v_host UUID;
    v_failure UUID;
    v_expected INTEGER;
    v_count BIGINT;
    v_min INTEGER;
    v_max INTEGER;
BEGIN
    v_host := COALESCE(NEW.host_id, OLD.host_id);
    v_failure := COALESCE(NEW.failure_id, OLD.failure_id);
    SELECT event_count INTO v_expected
      FROM event_failure_transaction_t
     WHERE host_id = v_host AND failure_id = v_failure;
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    SELECT count(*), min(event_ordinal), max(event_ordinal)
      INTO v_count, v_min, v_max
      FROM event_failure_event_t
     WHERE host_id = v_host AND failure_id = v_failure;
    IF v_count <> v_expected OR v_min <> 0 OR v_max <> v_expected - 1 THEN
        RAISE EXCEPTION ''failure transaction %/% must contain contiguous ordinals 0..%, found count %, min %, max %'',
            v_host, v_failure, v_expected - 1, v_count, v_min, v_max;
    END IF;
    RETURN NULL;
END ';

DROP TRIGGER IF EXISTS event_failure_transaction_members_v1 ON event_failure_transaction_t;
CREATE CONSTRAINT TRIGGER event_failure_transaction_members_v1
AFTER INSERT OR UPDATE OF event_count ON event_failure_transaction_t
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION validate_event_failure_members_v1();

DROP TRIGGER IF EXISTS event_failure_event_members_v1 ON event_failure_event_t;
CREATE CONSTRAINT TRIGGER event_failure_event_members_v1
AFTER INSERT OR UPDATE OR DELETE ON event_failure_event_t
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION validate_event_failure_members_v1();

CREATE OR REPLACE FUNCTION protect_event_failure_identity_v1()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF NEW.host_id IS DISTINCT FROM OLD.host_id
       OR NEW.failure_id IS DISTINCT FROM OLD.failure_id
       OR NEW.projection_name IS DISTINCT FROM OLD.projection_name
       OR NEW.consumer_group IS DISTINCT FROM OLD.consumer_group
       OR NEW.first_source_processor IS DISTINCT FROM OLD.first_source_processor
       OR NEW.original_transaction_id IS DISTINCT FROM OLD.original_transaction_id
       OR NEW.content_fingerprint IS DISTINCT FROM OLD.content_fingerprint
       OR NEW.event_count IS DISTINCT FROM OLD.event_count
       OR NEW.encrypted_payload_bytes IS DISTINCT FROM OLD.encrypted_payload_bytes
       OR NEW.decrypted_payload_bytes IS DISTINCT FROM OLD.decrypted_payload_bytes
       OR NEW.dependency_scopes IS DISTINCT FROM OLD.dependency_scopes
       OR NEW.first_failed_ts IS DISTINCT FROM OLD.first_failed_ts
       OR NEW.created_ts IS DISTINCT FROM OLD.created_ts
       OR NEW.failure_count < OLD.failure_count
       OR NEW.last_failed_ts < OLD.last_failed_ts THEN
        RAISE EXCEPTION ''canonical failure identity is immutable'';
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_failure_identity_guard_v1 ON event_failure_transaction_t;
CREATE TRIGGER event_failure_identity_guard_v1
BEFORE UPDATE ON event_failure_transaction_t
FOR EACH ROW EXECUTE FUNCTION protect_event_failure_identity_v1();

CREATE OR REPLACE FUNCTION event_replay_retention_delete_enabled_v1()
RETURNS boolean LANGUAGE sql STABLE AS '
    SELECT COALESCE(current_setting(''lightapi.event_replay_retention'', TRUE), '''') = ''on''
';

CREATE OR REPLACE FUNCTION protect_event_failure_event_v1()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF TG_OP = ''DELETE'' AND event_replay_retention_delete_enabled_v1() THEN RETURN OLD; END IF;
    IF TG_OP = ''DELETE'' THEN
        RAISE EXCEPTION ''archived failure event rows are immutable'';
    END IF;
    IF OLD.payload_storage = ''DELETED''
       OR NEW.host_id IS DISTINCT FROM OLD.host_id
       OR NEW.failure_id IS DISTINCT FROM OLD.failure_id
       OR NEW.event_ordinal IS DISTINCT FROM OLD.event_ordinal
       OR NEW.event_id IS DISTINCT FROM OLD.event_id
       OR NEW.event_type IS DISTINCT FROM OLD.event_type
       OR NEW.aggregate_id IS DISTINCT FROM OLD.aggregate_id
       OR NEW.aggregate_type IS DISTINCT FROM OLD.aggregate_type
       OR NEW.aggregate_version IS DISTINCT FROM OLD.aggregate_version
       OR NEW.root_instance_id IS DISTINCT FROM OLD.root_instance_id
       OR NEW.graph_revision IS DISTINCT FROM OLD.graph_revision
       OR NEW.clone_request_id IS DISTINCT FROM OLD.clone_request_id
       OR NEW.source_processor IS DISTINCT FROM OLD.source_processor
       OR NEW.source_topic IS DISTINCT FROM OLD.source_topic
       OR NEW.source_partition IS DISTINCT FROM OLD.source_partition
       OR NEW.source_offset IS DISTINCT FROM OLD.source_offset
       OR NEW.source_key IS DISTINCT FROM OLD.source_key
       OR NEW.source_headers IS DISTINCT FROM OLD.source_headers
       OR NEW.payload_format IS DISTINCT FROM OLD.payload_format
       OR NEW.payload_digest IS DISTINCT FROM OLD.payload_digest
       OR NEW.encrypted_payload_bytes IS DISTINCT FROM OLD.encrypted_payload_bytes
       OR NEW.decrypted_payload_bytes IS DISTINCT FROM OLD.decrypted_payload_bytes
       OR NEW.sensitive_payload IS DISTINCT FROM OLD.sensitive_payload
       OR NEW.created_ts IS DISTINCT FROM OLD.created_ts
       OR NEW.payload_storage <> ''DELETED''
       OR NEW.payload_ciphertext IS NOT NULL
       OR NEW.payload_object_uri IS NOT NULL
       OR NEW.payload_object_version IS NOT NULL
       OR NEW.payload_key_id IS NOT NULL
       OR NEW.payload_wrapped_key IS NOT NULL
       OR NEW.payload_iv IS NOT NULL
       OR NEW.payload_deleted_ts IS NULL
       OR NEW.payload_deleted_reason IS NULL
       OR length(btrim(NEW.payload_deleted_reason)) = 0 THEN
        RAISE EXCEPTION ''archived failure event rows are immutable except payload deletion'';
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_failure_event_guard_v1 ON event_failure_event_t;
CREATE TRIGGER event_failure_event_guard_v1
BEFORE UPDATE OR DELETE ON event_failure_event_t
FOR EACH ROW EXECUTE FUNCTION protect_event_failure_event_v1();

CREATE OR REPLACE FUNCTION protect_event_replay_item_plan_v1()
RETURNS trigger LANGUAGE plpgsql AS '
DECLARE
    v_host UUID;
    v_request UUID;
    v_status VARCHAR(32);
BEGIN
    IF TG_OP = ''DELETE'' AND event_replay_retention_delete_enabled_v1() THEN RETURN OLD; END IF;
    v_host := COALESCE(NEW.host_id, OLD.host_id);
    v_request := COALESCE(NEW.replay_request_id, OLD.replay_request_id);
    SELECT status INTO v_status
      FROM event_replay_request_t
     WHERE host_id = v_host AND replay_request_id = v_request;
    IF v_status <> ''PLANNING'' THEN
        IF TG_OP IN (''INSERT'', ''DELETE'') THEN
            RAISE EXCEPTION ''completed replay plan items are immutable'';
        END IF;
        IF NEW.host_id IS DISTINCT FROM OLD.host_id
           OR NEW.replay_request_id IS DISTINCT FROM OLD.replay_request_id
           OR NEW.item_ordinal IS DISTINCT FROM OLD.item_ordinal
           OR NEW.failure_id IS DISTINCT FROM OLD.failure_id
           OR NEW.expected_content_fingerprint IS DISTINCT FROM OLD.expected_content_fingerprint
           OR NEW.dependency_reason IS DISTINCT FROM OLD.dependency_reason
           OR NEW.added_dependency IS DISTINCT FROM OLD.added_dependency THEN
            RAISE EXCEPTION ''completed replay plan definition is immutable'';
        END IF;
    END IF;
    IF TG_OP = ''DELETE'' AND event_replay_retention_delete_enabled_v1() THEN RETURN OLD; END IF;
    IF TG_OP = ''DELETE'' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_replay_item_plan_guard_v1 ON event_replay_item_t;
CREATE TRIGGER event_replay_item_plan_guard_v1
BEFORE INSERT OR UPDATE OR DELETE ON event_replay_item_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_item_plan_v1();

CREATE OR REPLACE FUNCTION protect_event_replay_request_plan_v1()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF OLD.status <> ''PLANNING'' AND (
       NEW.host_id IS DISTINCT FROM OLD.host_id OR NEW.replay_request_id IS DISTINCT FROM OLD.replay_request_id
       OR NEW.projection_name IS DISTINCT FROM OLD.projection_name OR NEW.consumer_group IS DISTINCT FROM OLD.consumer_group
       OR NEW.selection_strategy IS DISTINCT FROM OLD.selection_strategy OR NEW.validation_mode IS DISTINCT FROM OLD.validation_mode
       OR NEW.reason IS DISTINCT FROM OLD.reason OR NEW.plan_hash IS DISTINCT FROM OLD.plan_hash
       OR NEW.policy_registry_version IS DISTINCT FROM OLD.policy_registry_version OR NEW.plan_metadata IS DISTINCT FROM OLD.plan_metadata
       OR NEW.transaction_count IS DISTINCT FROM OLD.transaction_count OR NEW.event_count IS DISTINCT FROM OLD.event_count
       OR NEW.encrypted_payload_bytes IS DISTINCT FROM OLD.encrypted_payload_bytes OR NEW.decrypted_payload_bytes IS DISTINCT FROM OLD.decrypted_payload_bytes
       OR NEW.requested_by IS DISTINCT FROM OLD.requested_by OR NEW.requested_ts IS DISTINCT FROM OLD.requested_ts
       OR NEW.expires_ts IS DISTINCT FROM OLD.expires_ts OR NEW.isolation_mode IS DISTINCT FROM OLD.isolation_mode) THEN
        RAISE EXCEPTION ''completed replay plan definition is immutable'';
    END IF;
    RETURN NEW;
END ';
DROP TRIGGER IF EXISTS event_replay_request_plan_guard_v1 ON event_replay_request_t;
CREATE TRIGGER event_replay_request_plan_guard_v1 BEFORE UPDATE ON event_replay_request_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_request_plan_v1();

CREATE OR REPLACE FUNCTION protect_event_replay_attempt_v1()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF TG_OP = ''DELETE'' THEN
        IF event_replay_retention_delete_enabled_v1() THEN RETURN OLD; END IF;
        RAISE EXCEPTION ''replay attempts are append-only'';
    END IF;
    IF NEW.host_id IS DISTINCT FROM OLD.host_id
       OR NEW.replay_attempt_id IS DISTINCT FROM OLD.replay_attempt_id
       OR NEW.replay_request_id IS DISTINCT FROM OLD.replay_request_id
       OR NEW.item_ordinal IS DISTINCT FROM OLD.item_ordinal
       OR NEW.attempt_number IS DISTINCT FROM OLD.attempt_number
       OR NEW.worker_id IS DISTINCT FROM OLD.worker_id
       OR NEW.fencing_token IS DISTINCT FROM OLD.fencing_token
       OR NEW.started_ts IS DISTINCT FROM OLD.started_ts
       OR NEW.pre_projection_metadata IS DISTINCT FROM OLD.pre_projection_metadata
       OR OLD.result <> ''RUNNING''
       OR NEW.result NOT IN (''SUCCEEDED'', ''FAILED'', ''ABANDONED'')
       OR NEW.completed_ts IS NULL THEN
        RAISE EXCEPTION ''replay attempt identity/history is immutable'';
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_replay_attempt_append_guard_v1 ON event_replay_attempt_t;
CREATE TRIGGER event_replay_attempt_append_guard_v1
BEFORE UPDATE OR DELETE ON event_replay_attempt_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_attempt_v1();

CREATE OR REPLACE FUNCTION protect_event_replay_monotonic_v1()
RETURNS trigger LANGUAGE plpgsql AS '
DECLARE
    v_new JSONB := to_jsonb(NEW);
    v_old JSONB := to_jsonb(OLD);
BEGIN
    IF TG_TABLE_NAME = ''event_replay_request_t''
       AND (v_new->>''fencing_token'')::BIGINT < (v_old->>''fencing_token'')::BIGINT THEN
        RAISE EXCEPTION ''replay request fencing token cannot decrease'';
    ELSIF TG_TABLE_NAME = ''event_replay_item_t''
       AND ((v_new->>''current_fencing_token'')::BIGINT < (v_old->>''current_fencing_token'')::BIGINT
            OR (v_new->>''attempt_count'')::INTEGER < (v_old->>''attempt_count'')::INTEGER) THEN
        RAISE EXCEPTION ''replay item fencing or attempt count cannot decrease'';
    ELSIF TG_TABLE_NAME = ''event_replay_lease_t''
       AND ((v_new->>''lease_epoch'')::BIGINT < (v_old->>''lease_epoch'')::BIGINT
            OR (v_new->>''fencing_token'')::BIGINT < (v_old->>''fencing_token'')::BIGINT) THEN
        RAISE EXCEPTION ''replay lease epoch or fencing token cannot decrease'';
    ELSIF TG_TABLE_NAME = ''event_replay_barrier_t''
       AND ((v_new->>''barrier_epoch'')::BIGINT < (v_old->>''barrier_epoch'')::BIGINT
            OR (v_new->>''fencing_token'')::BIGINT < (v_old->>''fencing_token'')::BIGINT) THEN
        RAISE EXCEPTION ''replay barrier epoch or fencing token cannot decrease'';
    ELSIF TG_TABLE_NAME = ''event_projection_control_t''
       AND (v_new->>''control_epoch'')::BIGINT < (v_old->>''control_epoch'')::BIGINT THEN
        RAISE EXCEPTION ''projection control epoch cannot decrease'';
    ELSIF TG_TABLE_NAME = ''event_projection_worker_t''
       AND ((v_new->>''observed_epoch'')::BIGINT < (v_old->>''observed_epoch'')::BIGINT
            OR (v_new->>''acknowledged_epoch'')::BIGINT < (v_old->>''acknowledged_epoch'')::BIGINT) THEN
        RAISE EXCEPTION ''projection worker epochs cannot decrease'';
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_replay_request_monotonic_v1 ON event_replay_request_t;
CREATE TRIGGER event_replay_request_monotonic_v1 BEFORE UPDATE ON event_replay_request_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_monotonic_v1();
DROP TRIGGER IF EXISTS event_replay_item_monotonic_v1 ON event_replay_item_t;
CREATE TRIGGER event_replay_item_monotonic_v1 BEFORE UPDATE ON event_replay_item_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_monotonic_v1();
DROP TRIGGER IF EXISTS event_replay_lease_monotonic_v1 ON event_replay_lease_t;
CREATE TRIGGER event_replay_lease_monotonic_v1 BEFORE UPDATE ON event_replay_lease_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_monotonic_v1();
DROP TRIGGER IF EXISTS event_replay_barrier_monotonic_v1 ON event_replay_barrier_t;
CREATE TRIGGER event_replay_barrier_monotonic_v1 BEFORE UPDATE ON event_replay_barrier_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_monotonic_v1();
DROP TRIGGER IF EXISTS event_projection_control_monotonic_v1 ON event_projection_control_t;
CREATE TRIGGER event_projection_control_monotonic_v1 BEFORE UPDATE ON event_projection_control_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_monotonic_v1();
DROP TRIGGER IF EXISTS event_projection_worker_monotonic_v1 ON event_projection_worker_t;
CREATE TRIGGER event_projection_worker_monotonic_v1 BEFORE UPDATE ON event_projection_worker_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_monotonic_v1();

CREATE OR REPLACE FUNCTION protect_event_failure_publish_outbox_v1()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF NEW.host_id IS DISTINCT FROM OLD.host_id
       OR NEW.publication_id IS DISTINCT FROM OLD.publication_id
       OR NEW.failure_id IS DISTINCT FROM OLD.failure_id
       OR NEW.envelope_version IS DISTINCT FROM OLD.envelope_version
       OR NEW.target_topic IS DISTINCT FROM OLD.target_topic
       OR NEW.created_ts IS DISTINCT FROM OLD.created_ts THEN
        RAISE EXCEPTION ''failure publication envelope identity is immutable'';
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_failure_publish_outbox_identity_guard_v1
    ON event_failure_publish_outbox_t;
CREATE TRIGGER event_failure_publish_outbox_identity_guard_v1
BEFORE UPDATE ON event_failure_publish_outbox_t
FOR EACH ROW EXECUTE FUNCTION protect_event_failure_publish_outbox_v1();

CREATE OR REPLACE FUNCTION protect_event_replay_audit_v1()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF TG_OP = ''DELETE'' AND event_replay_retention_delete_enabled_v1() THEN RETURN OLD; END IF;
    RAISE EXCEPTION ''event replay audit rows are append-only'';
END ';

DROP TRIGGER IF EXISTS event_replay_audit_append_guard_v1 ON event_replay_audit_t;
CREATE TRIGGER event_replay_audit_append_guard_v1
BEFORE UPDATE OR DELETE ON event_replay_audit_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_audit_v1();

CREATE OR REPLACE FUNCTION protect_event_replay_action_request_v1()
RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
    IF TG_OP = 'DELETE' AND event_replay_retention_delete_enabled_v1() THEN RETURN OLD; END IF;
    IF TG_OP = 'DELETE' OR NEW.host_id IS DISTINCT FROM OLD.host_id
       OR NEW.action_request_id IS DISTINCT FROM OLD.action_request_id
       OR NEW.action_type IS DISTINCT FROM OLD.action_type
       OR NEW.target_ids IS DISTINCT FROM OLD.target_ids
       OR NEW.expected_state IS DISTINCT FROM OLD.expected_state
       OR NEW.reason IS DISTINCT FROM OLD.reason
       OR NEW.requested_by IS DISTINCT FROM OLD.requested_by
       OR NEW.requested_ts IS DISTINCT FROM OLD.requested_ts
       OR NEW.expires_ts IS DISTINCT FROM OLD.expires_ts
       OR OLD.status <> 'AWAITING_APPROVAL'
       OR NEW.status NOT IN ('COMPLETED', 'CANCELLED', 'EXPIRED') THEN
        RAISE EXCEPTION 'event replay operator action history is immutable';
    END IF;
    RETURN NEW;
END $body$;
DROP TRIGGER IF EXISTS event_replay_action_request_guard_v1 ON event_replay_action_request_t;
CREATE TRIGGER event_replay_action_request_guard_v1
BEFORE UPDATE OR DELETE ON event_replay_action_request_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_action_request_v1();

CREATE OR REPLACE FUNCTION protect_event_replay_barrier_release_v1()
RETURNS trigger LANGUAGE plpgsql AS $body$
BEGIN
    IF OLD.released_ts IS NOT NULL AND (
       NEW.released_ts IS DISTINCT FROM OLD.released_ts
       OR NEW.released_by IS DISTINCT FROM OLD.released_by
       OR NEW.release_reason IS DISTINCT FROM OLD.release_reason) THEN
        RAISE EXCEPTION 'released replay barrier evidence is immutable';
    END IF;
    RETURN NEW;
END $body$;
DROP TRIGGER IF EXISTS event_replay_barrier_release_guard_v1 ON event_replay_barrier_t;
CREATE TRIGGER event_replay_barrier_release_guard_v1
BEFORE UPDATE ON event_replay_barrier_t
FOR EACH ROW EXECUTE FUNCTION protect_event_replay_barrier_release_v1();


-- Event replay redesign R1: additive repair persistence and immutable
-- database-plain payload bytes. Existing encrypted/object rows remain valid.

ALTER TABLE event_store_t
    ADD COLUMN IF NOT EXISTS policy_registry_version VARCHAR(64)
        NOT NULL DEFAULT 'event-replay-policy-v1',
    ADD COLUMN IF NOT EXISTS repair_schema_version VARCHAR(64);
ALTER TABLE event_store_t
    DROP CONSTRAINT IF EXISTS event_store_replay_versions_v2_ck,
    ADD CONSTRAINT event_store_replay_versions_v2_ck CHECK(
        length(btrim(policy_registry_version)) > 0
        AND (repair_schema_version IS NULL OR length(btrim(repair_schema_version)) > 0)
    ) NOT VALID;

ALTER TABLE outbox_message_t
    ADD COLUMN IF NOT EXISTS policy_registry_version VARCHAR(64)
        NOT NULL DEFAULT 'event-replay-policy-v1',
    ADD COLUMN IF NOT EXISTS repair_schema_version VARCHAR(64);
ALTER TABLE outbox_message_t
    DROP CONSTRAINT IF EXISTS outbox_message_replay_versions_v2_ck,
    ADD CONSTRAINT outbox_message_replay_versions_v2_ck CHECK(
        length(btrim(policy_registry_version)) > 0
        AND (repair_schema_version IS NULL OR length(btrim(repair_schema_version)) > 0)
    ) NOT VALID;

ALTER TABLE event_store_t VALIDATE CONSTRAINT event_store_replay_versions_v2_ck;
ALTER TABLE outbox_message_t VALIDATE CONSTRAINT outbox_message_replay_versions_v2_ck;

ALTER TABLE event_failure_transaction_t
    ADD COLUMN IF NOT EXISTS policy_registry_version VARCHAR(64)
        NOT NULL DEFAULT 'event-replay-policy-v1',
    ADD COLUMN IF NOT EXISTS resolution_code VARCHAR(64),
    ADD COLUMN IF NOT EXISTS resolved_by_repair_id UUID;
ALTER TABLE event_failure_transaction_t
    DROP CONSTRAINT IF EXISTS event_failure_transaction_policy_version_v2_ck,
    DROP CONSTRAINT IF EXISTS event_failure_transaction_resolution_v2_ck,
    ADD CONSTRAINT event_failure_transaction_policy_version_v2_ck CHECK(
        length(btrim(policy_registry_version)) > 0
    ),
    ADD CONSTRAINT event_failure_transaction_resolution_v2_ck CHECK(
        (resolution_code IS NULL AND resolved_by_repair_id IS NULL)
        OR (status = 'RESOLVED'
            AND resolution_code = 'RESOLVED_BY_EXACT_REPLAY'
            AND resolved_by_repair_id IS NULL)
        OR (status = 'RESOLVED'
            AND resolution_code = 'RESOLVED_BY_REPAIR'
            AND resolved_by_repair_id IS NOT NULL)
    );

ALTER TABLE event_failure_event_t
    ADD COLUMN IF NOT EXISTS payload_plain BYTEA,
    ADD COLUMN IF NOT EXISTS event_schema_version VARCHAR(64),
    ADD COLUMN IF NOT EXISTS policy_registry_version VARCHAR(64)
        NOT NULL DEFAULT 'event-replay-policy-v1',
    ADD COLUMN IF NOT EXISTS repair_schema_version VARCHAR(64);
ALTER TABLE event_failure_event_t
    DROP CONSTRAINT IF EXISTS event_failure_event_payload_storage_ck,
    DROP CONSTRAINT IF EXISTS event_failure_event_crypto_ck,
    DROP CONSTRAINT IF EXISTS event_failure_event_bytes_ck,
    DROP CONSTRAINT IF EXISTS event_failure_event_versions_v2_ck,
    ADD CONSTRAINT event_failure_event_payload_storage_ck CHECK(
        (payload_storage = 'DATABASE_PLAIN'
            AND payload_plain IS NOT NULL
            AND octet_length(payload_plain) > 0
            AND payload_digest = encode(sha256(payload_plain), 'hex')
            AND payload_ciphertext IS NULL
            AND payload_object_uri IS NULL
            AND payload_object_version IS NULL
            AND payload_key_id IS NULL
            AND payload_wrapped_key IS NULL
            AND payload_iv IS NULL
            AND payload_deleted_ts IS NULL
            AND payload_deleted_reason IS NULL)
        OR (payload_storage = 'DATABASE'
            AND payload_plain IS NULL
            AND payload_ciphertext IS NOT NULL
            AND payload_object_uri IS NULL
            AND payload_object_version IS NULL
            AND payload_key_id IS NOT NULL
            AND payload_wrapped_key IS NOT NULL
            AND payload_iv IS NOT NULL
            AND payload_deleted_ts IS NULL
            AND payload_deleted_reason IS NULL)
        OR (payload_storage = 'OBJECT'
            AND payload_plain IS NULL
            AND payload_ciphertext IS NULL
            AND payload_object_uri IS NOT NULL
            AND payload_object_version IS NOT NULL
            AND payload_key_id IS NOT NULL
            AND payload_wrapped_key IS NOT NULL
            AND payload_iv IS NOT NULL
            AND payload_deleted_ts IS NULL
            AND payload_deleted_reason IS NULL)
        OR (payload_storage = 'DELETED'
            AND payload_plain IS NULL
            AND payload_ciphertext IS NULL
            AND payload_object_uri IS NULL
            AND payload_object_version IS NULL
            AND payload_key_id IS NULL
            AND payload_wrapped_key IS NULL
            AND payload_iv IS NULL
            AND payload_deleted_ts IS NOT NULL
            AND length(btrim(payload_deleted_reason)) > 0)
    ),
    ADD CONSTRAINT event_failure_event_crypto_ck CHECK(
        payload_storage IN ('DATABASE_PLAIN', 'DELETED')
        OR (octet_length(payload_iv) = 12 AND octet_length(payload_wrapped_key) > 0)
    ),
    ADD CONSTRAINT event_failure_event_bytes_ck CHECK(
        encrypted_payload_bytes >= 0 AND decrypted_payload_bytes >= 0
        AND (payload_storage <> 'DATABASE_PLAIN'
             OR (encrypted_payload_bytes = 0
                 AND decrypted_payload_bytes = octet_length(payload_plain)))
    ),
    ADD CONSTRAINT event_failure_event_versions_v2_ck CHECK(
        length(btrim(policy_registry_version)) > 0
        AND (event_schema_version IS NULL OR length(btrim(event_schema_version)) > 0)
        AND (repair_schema_version IS NULL OR length(btrim(repair_schema_version)) > 0)
    );

ALTER TABLE event_replay_request_t
    ADD COLUMN IF NOT EXISTS repair_schema_version VARCHAR(64);
ALTER TABLE event_replay_request_t
    DROP CONSTRAINT IF EXISTS event_replay_request_repair_schema_v2_ck,
    ADD CONSTRAINT event_replay_request_repair_schema_v2_ck CHECK(
        repair_schema_version IS NULL OR length(btrim(repair_schema_version)) > 0
    );

CREATE OR REPLACE FUNCTION event_replay_changed_fields_valid_v2(fields JSONB)
RETURNS boolean LANGUAGE sql IMMUTABLE AS '
    SELECT jsonb_typeof(fields) = ''array''
       AND jsonb_array_length(fields) BETWEEN 1 AND 64
       AND NOT EXISTS (
            SELECT 1
              FROM jsonb_array_elements(fields) AS entry(value)
             WHERE jsonb_typeof(value) <> ''string''
                OR length(btrim(value #>> ''{}'')) NOT BETWEEN 1 AND 255
       )
';

CREATE TABLE IF NOT EXISTS event_repair_t (
    host_id                          UUID NOT NULL,
    repair_id                        UUID NOT NULL,
    failure_id                       UUID NOT NULL,
    status                           VARCHAR(32) NOT NULL DEFAULT 'AWAITING_APPROVAL',
    reason                           VARCHAR(2048) NOT NULL,
    policy_registry_version          VARCHAR(64) NOT NULL,
    repair_schema_version            VARCHAR(64) NOT NULL,
    original_transaction_fingerprint VARCHAR(64) NOT NULL,
    corrected_transaction_fingerprint VARCHAR(64) NOT NULL,
    changed_event_count              INTEGER NOT NULL,
    requested_by                     VARCHAR(255) NOT NULL,
    requested_ts                     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    decision_by                      VARCHAR(255),
    decision_ts                      TIMESTAMPTZ,
    approved_by                      VARCHAR(255),
    approved_ts                      TIMESTAMPTZ,
    applied_by                       VARCHAR(255),
    applied_ts                       TIMESTAMPTZ,
    completed_ts                     TIMESTAMPTZ,
    created_ts                       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts                       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_repair_pk PRIMARY KEY(host_id, repair_id),
    CONSTRAINT event_repair_failure_fk FOREIGN KEY(host_id, failure_id)
        REFERENCES event_failure_transaction_t(host_id, failure_id) ON DELETE RESTRICT,
    CONSTRAINT event_repair_target_uk UNIQUE(host_id, repair_id, failure_id),
    CONSTRAINT event_repair_status_ck CHECK(status IN (
        'AWAITING_APPROVAL', 'APPROVED', 'APPLIED', 'CANCELLED', 'REJECTED'
    )),
    CONSTRAINT event_repair_reason_ck CHECK(length(btrim(reason)) > 0),
    CONSTRAINT event_repair_versions_ck CHECK(
        length(btrim(policy_registry_version)) > 0
        AND length(btrim(repair_schema_version)) > 0
    ),
    CONSTRAINT event_repair_fingerprints_ck CHECK(
        original_transaction_fingerprint ~ '^[0-9a-f]{64}$'
        AND corrected_transaction_fingerprint ~ '^[0-9a-f]{64}$'
        AND corrected_transaction_fingerprint <> original_transaction_fingerprint
    ),
    CONSTRAINT event_repair_count_ck CHECK(changed_event_count > 0),
    CONSTRAINT event_repair_actor_pairs_ck CHECK(
        (decision_by IS NULL) = (decision_ts IS NULL)
        AND (approved_by IS NULL) = (approved_ts IS NULL)
        AND (applied_by IS NULL) = (applied_ts IS NULL)
        AND (decision_by IS NULL OR decision_by <> requested_by)
        AND (approved_by IS NULL OR approved_by <> requested_by)
    ),
    CONSTRAINT event_repair_lifecycle_ck CHECK(
        (status = 'AWAITING_APPROVAL'
            AND decision_by IS NULL AND approved_by IS NULL
            AND applied_by IS NULL AND completed_ts IS NULL)
        OR (status = 'APPROVED'
            AND decision_by IS NOT NULL AND approved_by = decision_by
            AND approved_ts = decision_ts
            AND applied_by IS NULL AND completed_ts IS NULL)
        OR (status = 'APPLIED'
            AND decision_by IS NOT NULL AND approved_by = decision_by
            AND approved_ts = decision_ts
            AND applied_by IS NOT NULL AND completed_ts = applied_ts)
        OR (status = 'REJECTED'
            AND decision_by IS NOT NULL AND approved_by IS NULL
            AND applied_by IS NULL AND completed_ts = decision_ts)
        OR (status = 'CANCELLED'
            AND applied_by IS NULL AND completed_ts IS NOT NULL
            AND ((decision_by IS NULL AND approved_by IS NULL)
                 OR (decision_by IS NOT NULL AND approved_by = decision_by
                     AND approved_ts = decision_ts)))
    ),
    CONSTRAINT event_repair_times_ck CHECK(
        created_ts >= requested_ts
        AND updated_ts >= requested_ts
        AND (decision_ts IS NULL OR decision_ts >= requested_ts)
        AND (approved_ts IS NULL OR approved_ts >= requested_ts)
        AND (applied_ts IS NULL OR applied_ts >= approved_ts)
        AND (completed_ts IS NULL OR completed_ts >= requested_ts)
    )
);

DO $event_repair_parent_keys_v2$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conrelid = 'event_failure_transaction_t'::regclass
           AND conname = 'event_failure_transaction_scope_parent_v2_uk'
    ) THEN
        ALTER TABLE event_failure_transaction_t
            ADD CONSTRAINT event_failure_transaction_scope_parent_v2_uk UNIQUE(
                host_id, failure_id, projection_name, consumer_group, status
            );
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conrelid = 'event_failure_event_t'::regclass
           AND conname = 'event_failure_event_repair_member_v2_uk'
    ) THEN
        ALTER TABLE event_failure_event_t
            ADD CONSTRAINT event_failure_event_repair_member_v2_uk UNIQUE(
                host_id, failure_id, event_ordinal, event_id, payload_digest
            );
    END IF;
END
$event_repair_parent_keys_v2$;

CREATE TABLE IF NOT EXISTS event_failure_scope_t (
    host_id          UUID NOT NULL,
    failure_id       UUID NOT NULL,
    projection_name  VARCHAR(128) NOT NULL,
    consumer_group   VARCHAR(255) NOT NULL,
    scope_type       VARCHAR(32) NOT NULL,
    scope_key        VARCHAR(1024) NOT NULL,
    status           VARCHAR(16) NOT NULL,
    created_ts       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_failure_scope_pk PRIMARY KEY(
        host_id, failure_id, scope_type, scope_key
    ),
    -- Projection and consumer identity are immutable; this cascade is for status only.
    CONSTRAINT event_failure_scope_parent_fk FOREIGN KEY(
        host_id, failure_id, projection_name, consumer_group, status
    ) REFERENCES event_failure_transaction_t(
        host_id, failure_id, projection_name, consumer_group, status
    ) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT event_failure_scope_type_ck CHECK(scope_type IN (
        'GRAPH_ROOT', 'AGGREGATE', 'HOST', 'DB_PARTITION',
        'KAFKA_PARTITION', 'PROJECTION'
    )),
    CONSTRAINT event_failure_scope_key_ck CHECK(length(btrim(scope_key)) > 0),
    CONSTRAINT event_failure_scope_status_ck CHECK(status IN ('OPEN', 'RESOLVED', 'WAIVED'))
);

CREATE TABLE IF NOT EXISTS event_repair_event_t (
    host_id                    UUID NOT NULL,
    repair_id                  UUID NOT NULL,
    failure_id                 UUID NOT NULL,
    event_ordinal              INTEGER NOT NULL,
    original_event_id          VARCHAR(255) NOT NULL,
    original_payload_digest    VARCHAR(64) NOT NULL,
    corrected_payload_format   VARCHAR(32) NOT NULL,
    corrected_payload_storage  VARCHAR(32) NOT NULL,
    corrected_payload_digest   VARCHAR(64) NOT NULL,
    corrected_payload_plain    BYTEA,
    corrected_payload_ciphertext BYTEA,
    corrected_payload_object_uri VARCHAR(2048),
    corrected_payload_object_version VARCHAR(255),
    corrected_payload_key_id   VARCHAR(255),
    corrected_payload_wrapped_key BYTEA,
    corrected_payload_iv       BYTEA,
    corrected_payload_bytes    BIGINT NOT NULL,
    corrected_event_schema_version VARCHAR(64) NOT NULL,
    changed_field_names        JSONB NOT NULL,
    created_ts                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_repair_event_pk PRIMARY KEY(host_id, repair_id, event_ordinal),
    CONSTRAINT event_repair_event_repair_fk FOREIGN KEY(host_id, repair_id, failure_id)
        REFERENCES event_repair_t(host_id, repair_id, failure_id) ON DELETE RESTRICT,
    CONSTRAINT event_repair_event_original_fk FOREIGN KEY(
        host_id, failure_id, event_ordinal, original_event_id, original_payload_digest
    ) REFERENCES event_failure_event_t(
        host_id, failure_id, event_ordinal, event_id, payload_digest
    ) ON DELETE RESTRICT,
    CONSTRAINT event_repair_event_ordinal_ck CHECK(event_ordinal >= 0),
    CONSTRAINT event_repair_event_digests_ck CHECK(
        original_payload_digest ~ '^[0-9a-f]{64}$'
        AND corrected_payload_digest ~ '^[0-9a-f]{64}$'
        AND corrected_payload_digest <> original_payload_digest
    ),
    CONSTRAINT event_repair_event_schema_ck CHECK(
        length(btrim(corrected_event_schema_version)) > 0
    ),
    CONSTRAINT event_repair_event_changed_fields_ck CHECK(
        event_replay_changed_fields_valid_v2(changed_field_names)
    ),
    CONSTRAINT event_repair_event_payload_storage_ck CHECK(
        (corrected_payload_storage = 'DATABASE_PLAIN'
            AND corrected_payload_plain IS NOT NULL
            AND octet_length(corrected_payload_plain) = corrected_payload_bytes
            AND corrected_payload_bytes > 0
            AND corrected_payload_digest = encode(sha256(corrected_payload_plain), 'hex')
            AND corrected_payload_ciphertext IS NULL
            AND corrected_payload_object_uri IS NULL
            AND corrected_payload_object_version IS NULL
            AND corrected_payload_key_id IS NULL
            AND corrected_payload_wrapped_key IS NULL
            AND corrected_payload_iv IS NULL)
    )
);

COMMENT ON COLUMN event_repair_event_t.corrected_payload_storage IS
    'R1 permits DATABASE_PLAIN only; encrypted/object columns are reserved until stable content and storage digests are modeled separately';

ALTER TABLE event_replay_item_t
    ADD COLUMN IF NOT EXISTS repair_id UUID;
ALTER TABLE event_replay_item_t
    DROP CONSTRAINT IF EXISTS event_replay_item_repair_target_v2_fk,
    ADD CONSTRAINT event_replay_item_repair_target_v2_fk FOREIGN KEY(
        host_id, repair_id, failure_id
    ) REFERENCES event_repair_t(host_id, repair_id, failure_id) ON DELETE RESTRICT;

ALTER TABLE event_failure_transaction_t
    DROP CONSTRAINT IF EXISTS event_failure_transaction_resolution_repair_v2_fk,
    ADD CONSTRAINT event_failure_transaction_resolution_repair_v2_fk FOREIGN KEY(
        host_id, resolved_by_repair_id, failure_id
    ) REFERENCES event_repair_t(host_id, repair_id, failure_id) ON DELETE RESTRICT;

CREATE OR REPLACE FUNCTION validate_event_repair_members_v2()
RETURNS trigger LANGUAGE plpgsql AS '
DECLARE
    v_host UUID;
    v_repair UUID;
    v_expected INTEGER;
    v_actual INTEGER;
BEGIN
    v_host := COALESCE(NEW.host_id, OLD.host_id);
    v_repair := COALESCE(NEW.repair_id, OLD.repair_id);
    SELECT changed_event_count INTO v_expected
      FROM event_repair_t
     WHERE host_id = v_host AND repair_id = v_repair;
    IF v_expected IS NULL THEN RETURN NULL; END IF;
    SELECT count(*) INTO v_actual
      FROM event_repair_event_t
     WHERE host_id = v_host AND repair_id = v_repair;
    IF v_actual <> v_expected THEN
        RAISE EXCEPTION ''repair % member count %, expected %'', v_repair, v_actual, v_expected;
    END IF;
    RETURN NULL;
END ';

DROP TRIGGER IF EXISTS event_repair_member_count_parent_v2 ON event_repair_t;
CREATE CONSTRAINT TRIGGER event_repair_member_count_parent_v2
AFTER INSERT OR UPDATE OF changed_event_count ON event_repair_t
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION validate_event_repair_members_v2();
DROP TRIGGER IF EXISTS event_repair_member_count_child_v2 ON event_repair_event_t;
CREATE CONSTRAINT TRIGGER event_repair_member_count_child_v2
AFTER INSERT OR UPDATE OR DELETE ON event_repair_event_t
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION validate_event_repair_members_v2();

CREATE OR REPLACE FUNCTION protect_event_repair_v2()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF TG_OP = ''INSERT'' THEN
        IF NEW.status <> ''AWAITING_APPROVAL'' THEN
            RAISE EXCEPTION ''repair must begin awaiting approval'';
        END IF;
        RETURN NEW;
    END IF;
    IF TG_OP = ''DELETE''
       OR NEW.host_id IS DISTINCT FROM OLD.host_id
       OR NEW.repair_id IS DISTINCT FROM OLD.repair_id
       OR NEW.failure_id IS DISTINCT FROM OLD.failure_id
       OR NEW.reason IS DISTINCT FROM OLD.reason
       OR NEW.policy_registry_version IS DISTINCT FROM OLD.policy_registry_version
       OR NEW.repair_schema_version IS DISTINCT FROM OLD.repair_schema_version
       OR NEW.original_transaction_fingerprint IS DISTINCT FROM OLD.original_transaction_fingerprint
       OR NEW.corrected_transaction_fingerprint IS DISTINCT FROM OLD.corrected_transaction_fingerprint
       OR NEW.changed_event_count IS DISTINCT FROM OLD.changed_event_count
       OR NEW.requested_by IS DISTINCT FROM OLD.requested_by
       OR NEW.requested_ts IS DISTINCT FROM OLD.requested_ts
       OR NEW.created_ts IS DISTINCT FROM OLD.created_ts
       OR NEW.updated_ts < OLD.updated_ts
       OR OLD.status IN (''APPLIED'', ''CANCELLED'', ''REJECTED'')
       OR (OLD.status = ''AWAITING_APPROVAL''
           AND NEW.status NOT IN (''APPROVED'', ''CANCELLED'', ''REJECTED''))
       OR (OLD.status = ''APPROVED''
           AND NEW.status NOT IN (''APPLIED'', ''CANCELLED'')) THEN
        RAISE EXCEPTION ''repair identity, evidence, and lifecycle are immutable'';
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_repair_guard_v2 ON event_repair_t;
CREATE TRIGGER event_repair_guard_v2
BEFORE INSERT OR UPDATE OR DELETE ON event_repair_t
FOR EACH ROW EXECUTE FUNCTION protect_event_repair_v2();

CREATE OR REPLACE FUNCTION protect_event_repair_event_v2()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF TG_OP <> ''INSERT'' THEN
        RAISE EXCEPTION ''repair event bytes and audit summary are append-only'';
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_repair_event_guard_v2 ON event_repair_event_t;
CREATE TRIGGER event_repair_event_guard_v2
BEFORE UPDATE OR DELETE ON event_repair_event_t
FOR EACH ROW EXECUTE FUNCTION protect_event_repair_event_v2();

CREATE OR REPLACE FUNCTION protect_event_failure_event_v1()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF TG_OP = ''DELETE'' AND event_replay_retention_delete_enabled_v1() THEN RETURN OLD; END IF;
    IF TG_OP = ''DELETE'' THEN
        RAISE EXCEPTION ''archived failure event rows are immutable'';
    END IF;
    IF OLD.payload_storage = ''DELETED''
       OR NEW.host_id IS DISTINCT FROM OLD.host_id
       OR NEW.failure_id IS DISTINCT FROM OLD.failure_id
       OR NEW.event_ordinal IS DISTINCT FROM OLD.event_ordinal
       OR NEW.event_id IS DISTINCT FROM OLD.event_id
       OR NEW.event_type IS DISTINCT FROM OLD.event_type
       OR NEW.aggregate_id IS DISTINCT FROM OLD.aggregate_id
       OR NEW.aggregate_type IS DISTINCT FROM OLD.aggregate_type
       OR NEW.aggregate_version IS DISTINCT FROM OLD.aggregate_version
       OR NEW.root_instance_id IS DISTINCT FROM OLD.root_instance_id
       OR NEW.graph_revision IS DISTINCT FROM OLD.graph_revision
       OR NEW.clone_request_id IS DISTINCT FROM OLD.clone_request_id
       OR NEW.source_processor IS DISTINCT FROM OLD.source_processor
       OR NEW.source_topic IS DISTINCT FROM OLD.source_topic
       OR NEW.source_partition IS DISTINCT FROM OLD.source_partition
       OR NEW.source_offset IS DISTINCT FROM OLD.source_offset
       OR NEW.source_key IS DISTINCT FROM OLD.source_key
       OR NEW.source_headers IS DISTINCT FROM OLD.source_headers
       OR NEW.payload_format IS DISTINCT FROM OLD.payload_format
       OR NEW.payload_digest IS DISTINCT FROM OLD.payload_digest
       OR NEW.event_schema_version IS DISTINCT FROM OLD.event_schema_version
       OR NEW.policy_registry_version IS DISTINCT FROM OLD.policy_registry_version
       OR NEW.repair_schema_version IS DISTINCT FROM OLD.repair_schema_version
       OR NEW.encrypted_payload_bytes IS DISTINCT FROM OLD.encrypted_payload_bytes
       OR NEW.decrypted_payload_bytes IS DISTINCT FROM OLD.decrypted_payload_bytes
       OR NEW.sensitive_payload IS DISTINCT FROM OLD.sensitive_payload
       OR NEW.created_ts IS DISTINCT FROM OLD.created_ts
       OR NEW.payload_storage <> ''DELETED''
       OR NEW.payload_plain IS NOT NULL
       OR NEW.payload_ciphertext IS NOT NULL
       OR NEW.payload_object_uri IS NOT NULL
       OR NEW.payload_object_version IS NOT NULL
       OR NEW.payload_key_id IS NOT NULL
       OR NEW.payload_wrapped_key IS NOT NULL
       OR NEW.payload_iv IS NOT NULL
       OR NEW.payload_deleted_ts IS NULL
       OR NEW.payload_deleted_reason IS NULL
       OR length(btrim(NEW.payload_deleted_reason)) = 0 THEN
        RAISE EXCEPTION ''archived failure event rows are immutable except payload deletion'';
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_failure_event_guard_v1 ON event_failure_event_t;
CREATE TRIGGER event_failure_event_guard_v1
BEFORE UPDATE OR DELETE ON event_failure_event_t
FOR EACH ROW EXECUTE FUNCTION protect_event_failure_event_v1();

CREATE OR REPLACE FUNCTION event_replay_reconciliation_enabled_v2()
RETURNS boolean LANGUAGE sql STABLE AS '
    SELECT COALESCE(current_setting(''lightapi.event_replay_reconciliation'', TRUE), '''') = ''on''
';

CREATE OR REPLACE FUNCTION protect_event_failure_identity_v1()
RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
    IF NEW.host_id IS DISTINCT FROM OLD.host_id
       OR NEW.failure_id IS DISTINCT FROM OLD.failure_id
       OR NEW.projection_name IS DISTINCT FROM OLD.projection_name
       OR NEW.consumer_group IS DISTINCT FROM OLD.consumer_group
       OR NEW.first_source_processor IS DISTINCT FROM OLD.first_source_processor
       OR NEW.original_transaction_id IS DISTINCT FROM OLD.original_transaction_id
       OR NEW.content_fingerprint IS DISTINCT FROM OLD.content_fingerprint
       OR NEW.event_count IS DISTINCT FROM OLD.event_count
       OR NEW.encrypted_payload_bytes IS DISTINCT FROM OLD.encrypted_payload_bytes
       OR NEW.decrypted_payload_bytes IS DISTINCT FROM OLD.decrypted_payload_bytes
       OR NEW.dependency_scopes IS DISTINCT FROM OLD.dependency_scopes
       OR NEW.policy_registry_version IS DISTINCT FROM OLD.policy_registry_version
       OR NEW.first_failed_ts IS DISTINCT FROM OLD.first_failed_ts
       OR NEW.created_ts IS DISTINCT FROM OLD.created_ts
       OR NEW.failure_count < OLD.failure_count
       OR NEW.last_failed_ts < OLD.last_failed_ts
       OR (OLD.status <> ''OPEN'' AND (
           NEW.status IS DISTINCT FROM OLD.status
           OR NEW.resolved_ts IS DISTINCT FROM OLD.resolved_ts
           OR NEW.resolved_by_request_id IS DISTINCT FROM OLD.resolved_by_request_id
           OR NEW.resolution_code IS DISTINCT FROM OLD.resolution_code
           OR NEW.resolved_by_repair_id IS DISTINCT FROM OLD.resolved_by_repair_id)
           AND NOT (
               OLD.status = ''RESOLVED''
               AND NEW.status = ''OPEN''
               AND event_replay_reconciliation_enabled_v2()
               AND NEW.resolved_ts IS NULL
               AND NEW.resolved_by_request_id IS NULL
               AND NEW.resolution_code IS NULL
               AND NEW.resolved_by_repair_id IS NULL)) THEN
        RAISE EXCEPTION ''canonical failure identity and terminal resolution are immutable'';
    END IF;
    RETURN NEW;
END ';

DROP TRIGGER IF EXISTS event_failure_identity_guard_v1 ON event_failure_transaction_t;
CREATE TRIGGER event_failure_identity_guard_v1
BEFORE UPDATE ON event_failure_transaction_t
FOR EACH ROW EXECUTE FUNCTION protect_event_failure_identity_v1();

CREATE INDEX IF NOT EXISTS event_failure_open_scope_v2_idx
    ON event_failure_scope_t(
        host_id, projection_name, consumer_group, scope_type, scope_key
    ) WHERE status = 'OPEN';
CREATE INDEX IF NOT EXISTS event_repair_failure_v2_idx
    ON event_repair_t(host_id, failure_id, status, requested_ts DESC);
CREATE INDEX IF NOT EXISTS event_repair_status_v2_idx
    ON event_repair_t(host_id, status, requested_ts DESC);

REVOKE SELECT (payload_plain) ON event_failure_event_t FROM PUBLIC;
REVOKE SELECT (corrected_payload_plain, corrected_payload_ciphertext,
               corrected_payload_wrapped_key, corrected_payload_iv)
    ON event_repair_event_t FROM PUBLIC;

COMMENT ON COLUMN event_failure_event_t.payload_plain IS
    'Immutable canonical replay bytes for DATABASE_PLAIN; digest exact stored bytes before parsing';
COMMENT ON COLUMN event_repair_event_t.corrected_payload_plain IS
    'Immutable corrected canonical bytes; never exposed by list/query APIs';
COMMENT ON TABLE event_failure_scope_t IS
    'Normalized failure scopes maintained by capture for indexed ordered-scope command guards';


COMMIT;

-- PDB-1 authoritative LLM control-plane schema. The upgrade patches are
-- inlined here so fresh-install/container initialization is self-contained.
-- Keep the marked blocks synchronized with their corresponding upgrade files.
-- BEGIN INLINED patch_20260719_01_llm_control_plane.sql
BEGIN;

CREATE TABLE IF NOT EXISTS llm_model_catalog_t (
    host_id UUID NOT NULL,
    model_catalog_id UUID NOT NULL,
    provider_type VARCHAR(32) NOT NULL,
    physical_model_id VARCHAR(255) NOT NULL,
    model_family VARCHAR(126) NOT NULL,
    model_version VARCHAR(64),
    lifecycle_status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
    context_token_limit BIGINT NOT NULL CHECK(context_token_limit > 0),
    output_token_limit BIGINT NOT NULL CHECK(output_token_limit > 0),
    modalities JSONB NOT NULL DEFAULT '[]'::jsonb CHECK(jsonb_typeof(modalities) = 'array'),
    operations JSONB NOT NULL DEFAULT '[]'::jsonb CHECK(jsonb_typeof(operations) = 'array'),
    declared_capabilities JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(declared_capabilities) = 'object'),
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, model_catalog_id),
    FOREIGN KEY(host_id) REFERENCES host_t(host_id) ON DELETE CASCADE,
    UNIQUE(host_id, provider_type, physical_model_id),
    CHECK(lifecycle_status IN ('DRAFT','ACTIVE','DEPRECATED','RETIRED'))
);

CREATE TABLE IF NOT EXISTS llm_model_registration_t (
    host_id UUID NOT NULL,
    model_registration_id UUID NOT NULL,
    model_catalog_id UUID NOT NULL,
    environment VARCHAR(32) NOT NULL,
    regions JSONB NOT NULL DEFAULT '[]'::jsonb CHECK(jsonb_typeof(regions) = 'array'),
    data_classifications JSONB NOT NULL DEFAULT '[]'::jsonb CHECK(jsonb_typeof(data_classifications) = 'array'),
    capability_restrictions JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(capability_restrictions) = 'object'),
    lifecycle_status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, model_registration_id),
    FOREIGN KEY(host_id) REFERENCES host_t(host_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, model_catalog_id) REFERENCES llm_model_catalog_t(host_id, model_catalog_id) ON DELETE RESTRICT,
    UNIQUE(host_id, model_catalog_id, environment),
    CHECK(lifecycle_status IN ('DRAFT','ACTIVE','SUSPENDED','RETIRED'))
);

CREATE TABLE IF NOT EXISTS llm_provider_account_t (
    host_id UUID NOT NULL,
    provider_account_id UUID NOT NULL,
    account_name VARCHAR(126) NOT NULL,
    provider_type VARCHAR(32) NOT NULL,
    billing_principal VARCHAR(255) NOT NULL,
    quota_group_id VARCHAR(126) NOT NULL,
    capacity_metadata JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(capacity_metadata) = 'object'),
    lifecycle_status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, provider_account_id),
    FOREIGN KEY(host_id) REFERENCES host_t(host_id) ON DELETE CASCADE,
    UNIQUE(host_id, provider_type, account_name),
    CHECK(lifecycle_status IN ('DRAFT','ACTIVE','SUSPENDED','RETIRED'))
);

CREATE TABLE IF NOT EXISTS llm_provider_deployment_t (
    host_id UUID NOT NULL,
    provider_deployment_id UUID NOT NULL,
    model_registration_id UUID NOT NULL,
    provider_account_id UUID NOT NULL,
    deployment_name VARCHAR(126) NOT NULL,
    provider_type VARCHAR(32) NOT NULL,
    physical_model_id VARCHAR(255) NOT NULL,
    base_url TEXT NOT NULL CHECK(base_url ~ '^https://'),
    region VARCHAR(64),
    transport_bounds JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(transport_bounds) = 'object'),
    quota_group_id VARCHAR(126) NOT NULL,
    conformance_state VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN',
    conformance_digest VARCHAR(71),
    conformance_valid_until TIMESTAMPTZ,
    conformance_result JSONB,
    refresh_before_seconds INTEGER CHECK(refresh_before_seconds IS NULL OR refresh_before_seconds > 0),
    lifecycle_status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, provider_deployment_id),
    FOREIGN KEY(host_id, model_registration_id) REFERENCES llm_model_registration_t(host_id, model_registration_id) ON DELETE RESTRICT,
    FOREIGN KEY(host_id, provider_account_id) REFERENCES llm_provider_account_t(host_id, provider_account_id) ON DELETE RESTRICT,
    UNIQUE(host_id, deployment_name),
    CHECK(conformance_state IN ('UNKNOWN','PENDING','PASS','FAIL','EXPIRED','QUARANTINED')),
    CHECK(lifecycle_status IN ('DRAFT','VALIDATING','ACTIVE','SUSPENDED','RETIRED')),
    CHECK(conformance_valid_until IS NULL OR conformance_digest IS NOT NULL)
);

ALTER TABLE llm_provider_deployment_t
    ADD COLUMN IF NOT EXISTS conformance_result JSONB;
-- Compact PASS flags from an older schema are not production attestations.
-- Quarantine them during upgrade so the stronger constraint can be installed
-- without treating unaudited capability declarations as evidence.
UPDATE llm_provider_deployment_t
   SET conformance_state = 'QUARANTINED'
 WHERE conformance_state = 'PASS'
   AND NOT ((
       conformance_result IS NOT NULL
       AND conformance_digest IS NOT NULL
       AND conformance_valid_until IS NOT NULL
       AND jsonb_typeof(conformance_result) = 'object'
       AND conformance_result->>'schemaVersion' = '1'
       AND conformance_result->>'state' = 'pass'
       AND conformance_result->>'digest' = conformance_digest
       AND conformance_result->>'provider' = provider_type
       AND conformance_result->>'physicalModel' = physical_model_id
       AND CASE
           WHEN conformance_result->>'validUntil' ~ '^\d{4}-\d{2}-\d{2}T'
           THEN (conformance_result->>'validUntil')::timestamptz = conformance_valid_until
           ELSE FALSE
       END
       AND jsonb_typeof(conformance_result->'capabilities') = 'object'
       AND jsonb_typeof(conformance_result->'capabilityEvidence') = 'object'
   ) IS TRUE);
ALTER TABLE llm_provider_deployment_t
    DROP CONSTRAINT IF EXISTS llm_provider_deployment_conformance_result_shape_ck;
ALTER TABLE llm_provider_deployment_t
    ADD CONSTRAINT llm_provider_deployment_conformance_result_shape_ck CHECK(
        (conformance_result IS NULL OR jsonb_typeof(conformance_result) = 'object') IS TRUE
    );
ALTER TABLE llm_provider_deployment_t
    DROP CONSTRAINT IF EXISTS llm_provider_deployment_pass_result_ck;
ALTER TABLE llm_provider_deployment_t
    ADD CONSTRAINT llm_provider_deployment_pass_result_ck CHECK(
        (conformance_state <> 'PASS' OR (
            conformance_result IS NOT NULL
            AND conformance_digest IS NOT NULL
            AND conformance_valid_until IS NOT NULL
            AND conformance_result->>'schemaVersion' = '1'
            AND conformance_result->>'state' = 'pass'
            AND conformance_result->>'digest' = conformance_digest
            AND conformance_result->>'provider' = provider_type
            AND conformance_result->>'physicalModel' = physical_model_id
            AND (conformance_result->>'validUntil')::timestamptz = conformance_valid_until
            AND jsonb_typeof(conformance_result->'capabilities') = 'object'
            AND jsonb_typeof(conformance_result->'capabilityEvidence') = 'object'
        )) IS TRUE
    );

CREATE TABLE IF NOT EXISTS llm_provider_credential_t (
    host_id UUID NOT NULL,
    provider_credential_id UUID NOT NULL,
    provider_deployment_id UUID NOT NULL,
    credential_version INTEGER NOT NULL CHECK(credential_version > 0),
    secret_reference VARCHAR(1024) NOT NULL CHECK(secret_reference ~ '^[A-Za-z][A-Za-z0-9+.-]*://'),
    effective_ts TIMESTAMPTZ NOT NULL,
    expires_ts TIMESTAMPTZ,
    lifecycle_status VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, provider_credential_id),
    FOREIGN KEY(host_id, provider_deployment_id) REFERENCES llm_provider_deployment_t(host_id, provider_deployment_id) ON DELETE RESTRICT,
    UNIQUE(host_id, provider_deployment_id, credential_version),
    CHECK(expires_ts IS NULL OR expires_ts > effective_ts),
    CHECK(lifecycle_status IN ('PENDING','ACTIVE','ROTATING','REVOKED','EXPIRED'))
);

CREATE TABLE IF NOT EXISTS llm_public_alias_t (
    host_id UUID NOT NULL,
    public_alias_id UUID NOT NULL,
    environment VARCHAR(32) NOT NULL,
    alias_name VARCHAR(126) NOT NULL,
    operations JSONB NOT NULL DEFAULT '[]'::jsonb CHECK(jsonb_typeof(operations) = 'array'),
    required_capabilities JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(required_capabilities) = 'object'),
    max_input_tokens BIGINT CHECK(max_input_tokens IS NULL OR max_input_tokens > 0),
    max_output_tokens BIGINT CHECK(max_output_tokens IS NULL OR max_output_tokens > 0),
    max_request_bytes BIGINT CHECK(max_request_bytes IS NULL OR max_request_bytes > 0),
    data_classification VARCHAR(32),
    logging_mode VARCHAR(16) NOT NULL DEFAULT 'METADATA',
    pii_mode VARCHAR(16) NOT NULL DEFAULT 'DENY',
    lifecycle_status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
    replacement_alias_id UUID,
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, public_alias_id),
    FOREIGN KEY(host_id) REFERENCES host_t(host_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, replacement_alias_id) REFERENCES llm_public_alias_t(host_id, public_alias_id) ON DELETE RESTRICT,
    UNIQUE(host_id, environment, alias_name),
    CHECK(logging_mode IN ('NONE','METADATA','REDACTED')),
    CHECK(pii_mode IN ('DENY','REDACT','TOKENIZE','ALLOW')),
    CHECK(lifecycle_status IN ('DRAFT','ACTIVE','DEPRECATED','RETIRED')),
    CHECK(replacement_alias_id IS NULL OR replacement_alias_id <> public_alias_id)
);

CREATE TABLE IF NOT EXISTS llm_alias_route_t (
    host_id UUID NOT NULL,
    alias_route_id UUID NOT NULL,
    public_alias_id UUID NOT NULL,
    provider_deployment_id UUID NOT NULL,
    route_priority INTEGER NOT NULL CHECK(route_priority >= 0),
    route_weight INTEGER NOT NULL DEFAULT 1 CHECK(route_weight > 0),
    fallback_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    canary_percent NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK(canary_percent >= 0 AND canary_percent <= 100),
    residency_conditions JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(residency_conditions) = 'object'),
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, alias_route_id),
    FOREIGN KEY(host_id, public_alias_id) REFERENCES llm_public_alias_t(host_id, public_alias_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, provider_deployment_id) REFERENCES llm_provider_deployment_t(host_id, provider_deployment_id) ON DELETE RESTRICT,
    UNIQUE(host_id, public_alias_id, provider_deployment_id),
    UNIQUE(host_id, public_alias_id, route_priority),
    CHECK(route_weight = 1),
    CHECK(canary_percent = 0)
);

CREATE TABLE IF NOT EXISTS llm_pricing_version_t (
    host_id UUID NOT NULL,
    pricing_version_id UUID NOT NULL,
    provider_deployment_id UUID NOT NULL,
    pricing_version INTEGER NOT NULL CHECK(pricing_version > 0),
    input_micros_per_million BIGINT NOT NULL CHECK(input_micros_per_million >= 0),
    output_micros_per_million BIGINT NOT NULL CHECK(output_micros_per_million >= 0),
    cached_input_micros_per_million BIGINT CHECK(cached_input_micros_per_million IS NULL OR cached_input_micros_per_million >= 0),
    effective_ts TIMESTAMPTZ NOT NULL,
    expires_ts TIMESTAMPTZ,
    source VARCHAR(255) NOT NULL,
    approved_by VARCHAR(126) NOT NULL,
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, pricing_version_id),
    FOREIGN KEY(host_id, provider_deployment_id) REFERENCES llm_provider_deployment_t(host_id, provider_deployment_id) ON DELETE RESTRICT,
    UNIQUE(host_id, provider_deployment_id, pricing_version),
    CHECK(expires_ts IS NULL OR expires_ts > effective_ts)
);

CREATE TABLE IF NOT EXISTS llm_model_policy_t (
    host_id UUID NOT NULL,
    model_policy_id UUID NOT NULL,
    policy_name VARCHAR(126) NOT NULL,
    access_policy JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(access_policy) = 'object'),
    budget_policy JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(budget_policy) = 'object'),
    content_policy JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(content_policy) = 'object'),
    cache_policy JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(cache_policy) = 'object'),
    pii_policy JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(pii_policy) = 'object'),
    native_extension_policy JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(native_extension_policy) = 'object'),
    lifecycle_status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, model_policy_id),
    FOREIGN KEY(host_id) REFERENCES host_t(host_id) ON DELETE CASCADE,
    UNIQUE(host_id, policy_name),
    CHECK(lifecycle_status IN ('DRAFT','ACTIVE','SUSPENDED','RETIRED'))
);

CREATE TABLE IF NOT EXISTS llm_model_policy_binding_t (
    host_id UUID NOT NULL,
    model_policy_binding_id UUID NOT NULL,
    model_policy_id UUID NOT NULL,
    subject_type VARCHAR(16) NOT NULL,
    subject_id VARCHAR(255) NOT NULL,
    public_alias_id UUID,
    agent_default BOOLEAN NOT NULL DEFAULT FALSE,
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, model_policy_binding_id),
    FOREIGN KEY(host_id, model_policy_id) REFERENCES llm_model_policy_t(host_id, model_policy_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, public_alias_id) REFERENCES llm_public_alias_t(host_id, public_alias_id) ON DELETE RESTRICT,
    UNIQUE(host_id, model_policy_id, subject_type, subject_id, public_alias_id),
    CHECK(subject_type IN ('AGENT','CLIENT','PRINCIPAL','PRODUCT_PROFILE')),
    CHECK(NOT agent_default OR public_alias_id IS NOT NULL)
);

CREATE UNIQUE INDEX IF NOT EXISTS llm_policy_binding_agent_default_uk
    ON llm_model_policy_binding_t(host_id, model_policy_id, subject_type, subject_id)
    WHERE active IS TRUE AND agent_default IS TRUE;

CREATE TABLE IF NOT EXISTS llm_projection_resource_t (
    host_id UUID NOT NULL,
    environment VARCHAR(32) NOT NULL,
    projection_resource_id UUID NOT NULL,
    resource_type VARCHAR(32) NOT NULL,
    resource_key VARCHAR(255) NOT NULL,
    resource_version BIGINT NOT NULL CHECK(resource_version > 0),
    sequence_id BIGINT NOT NULL CHECK(sequence_id > 0),
    schema_version INTEGER NOT NULL CHECK(schema_version > 0),
    payload JSONB NOT NULL CHECK(jsonb_typeof(payload) = 'object'),
    payload_digest VARCHAR(71) NOT NULL CHECK(payload_digest ~ '^sha256:[0-9a-f]{64}$'),
    lifecycle_status VARCHAR(16) NOT NULL DEFAULT 'CANDIDATE',
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, environment, projection_resource_id),
    FOREIGN KEY(host_id) REFERENCES host_t(host_id) ON DELETE CASCADE,
    UNIQUE(host_id, environment, resource_key, resource_version),
    UNIQUE(host_id, environment, sequence_id),
    CHECK(lifecycle_status IN ('CANDIDATE','PUBLISHED','RETIRED'))
);

CREATE TABLE IF NOT EXISTS llm_gateway_publication_t (
    host_id UUID NOT NULL,
    environment VARCHAR(32) NOT NULL,
    gateway_publication_id UUID NOT NULL,
    publication_version BIGINT NOT NULL CHECK(publication_version > 0),
    manifest JSONB NOT NULL CHECK(jsonb_typeof(manifest) = 'object'),
    manifest_digest VARCHAR(71) NOT NULL CHECK(manifest_digest ~ '^sha256:[0-9a-f]{64}$'),
    minimum_gateway_version VARCHAR(32) NOT NULL,
    enabled_routing_features JSONB NOT NULL DEFAULT '[]'::jsonb CHECK(jsonb_typeof(enabled_routing_features) = 'array'),
    validation_result JSONB NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(validation_result) = 'object'),
    publication_state VARCHAR(16) NOT NULL DEFAULT 'CANDIDATE',
    rollback_of_publication_id UUID,
    delivery_state VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    delivery_evidence JSONB,
    aggregate_version BIGINT NOT NULL DEFAULT 1 CHECK(aggregate_version > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_user VARCHAR(126) NOT NULL DEFAULT SESSION_USER,
    PRIMARY KEY(host_id, environment, gateway_publication_id),
    FOREIGN KEY(host_id) REFERENCES host_t(host_id) ON DELETE CASCADE,
    FOREIGN KEY(host_id, environment, rollback_of_publication_id) REFERENCES llm_gateway_publication_t(host_id, environment, gateway_publication_id) ON DELETE RESTRICT,
    UNIQUE(host_id, environment, publication_version),
    UNIQUE(host_id, environment, manifest_digest),
    CHECK(publication_state IN ('CANDIDATE','VALIDATED','PUBLISHED','FAILED','ROLLED_BACK')),
    CHECK(delivery_state IN ('PENDING','ACKNOWLEDGED','FAILED'))
);

CREATE OR REPLACE FUNCTION llm_reject_published_digest_mutation()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN
    IF OLD.lifecycle_status = 'PUBLISHED'
       AND (NEW.payload_digest <> OLD.payload_digest OR NEW.payload <> OLD.payload) THEN
        RAISE EXCEPTION 'published LLM projection resources are immutable';
    END IF;
    RETURN NEW;
END
$function$;

DROP TRIGGER IF EXISTS llm_projection_resource_immutable_trg ON llm_projection_resource_t;
CREATE TRIGGER llm_projection_resource_immutable_trg
BEFORE UPDATE ON llm_projection_resource_t
FOR EACH ROW EXECUTE FUNCTION llm_reject_published_digest_mutation();

CREATE OR REPLACE FUNCTION llm_reject_published_manifest_mutation()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN
    IF OLD.publication_state IN ('PUBLISHED','ROLLED_BACK')
       AND (NEW.manifest_digest <> OLD.manifest_digest OR NEW.manifest <> OLD.manifest) THEN
        RAISE EXCEPTION 'published LLM gateway manifests are immutable';
    END IF;
    RETURN NEW;
END
$function$;

DROP TRIGGER IF EXISTS llm_gateway_publication_immutable_trg ON llm_gateway_publication_t;
CREATE TRIGGER llm_gateway_publication_immutable_trg
BEFORE UPDATE ON llm_gateway_publication_t
FOR EACH ROW EXECUTE FUNCTION llm_reject_published_manifest_mutation();

ALTER TABLE agent_definition_t
    ADD COLUMN IF NOT EXISTS model_alias_id UUID,
    ADD COLUMN IF NOT EXISTS model_policy_id UUID;

ALTER TABLE agent_definition_t ALTER COLUMN model_provider DROP NOT NULL;
ALTER TABLE agent_definition_t ALTER COLUMN model_name DROP NOT NULL;

ALTER TABLE agent_definition_t DROP CONSTRAINT IF EXISTS agent_definition_model_selection_ck;
ALTER TABLE agent_definition_t ADD CONSTRAINT agent_definition_model_selection_ck CHECK (
    NOT (model_alias_id IS NOT NULL AND model_policy_id IS NOT NULL)
    AND (
        model_alias_id IS NOT NULL
        OR model_policy_id IS NOT NULL
        OR (model_provider IS NOT NULL AND model_name IS NOT NULL)
    )
    AND ((model_provider IS NULL) = (model_name IS NULL))
    AND ((model_alias_id IS NULL AND model_policy_id IS NULL) OR api_key_ref IS NULL)
);

ALTER TABLE agent_definition_t DROP CONSTRAINT IF EXISTS agent_definition_model_alias_fk;
ALTER TABLE agent_definition_t ADD CONSTRAINT agent_definition_model_alias_fk
    FOREIGN KEY(host_id, model_alias_id) REFERENCES llm_public_alias_t(host_id, public_alias_id) ON DELETE RESTRICT;
ALTER TABLE agent_definition_t DROP CONSTRAINT IF EXISTS agent_definition_model_policy_fk;
ALTER TABLE agent_definition_t ADD CONSTRAINT agent_definition_model_policy_fk
    FOREIGN KEY(host_id, model_policy_id) REFERENCES llm_model_policy_t(host_id, model_policy_id) ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS llm_deployment_conformance_due_idx
    ON llm_provider_deployment_t(host_id, conformance_valid_until)
    WHERE active IS TRUE AND lifecycle_status = 'ACTIVE';
CREATE INDEX IF NOT EXISTS llm_projection_resource_sequence_idx
    ON llm_projection_resource_t(host_id, environment, sequence_id);
CREATE INDEX IF NOT EXISTS llm_publication_current_idx
    ON llm_gateway_publication_t(host_id, environment, publication_version DESC)
    WHERE active IS TRUE;

COMMIT;
-- END INLINED patch_20260719_01_llm_control_plane.sql

-- BEGIN INLINED patch_20260719_03_llm_production_integration.sql
-- DIST-1 / LA-1: distinguish public aliases from operator-approved,
-- agent-bound compatibility aliases. Additive and idempotent.
BEGIN;

ALTER TABLE llm_public_alias_t
    ADD COLUMN IF NOT EXISTS alias_visibility VARCHAR(24) NOT NULL DEFAULT 'PUBLIC';
ALTER TABLE llm_public_alias_t
    ADD COLUMN IF NOT EXISTS bound_agent_def_id UUID;

ALTER TABLE llm_public_alias_t
    DROP CONSTRAINT IF EXISTS llm_public_alias_visibility_ck;
ALTER TABLE llm_public_alias_t
    ADD CONSTRAINT llm_public_alias_visibility_ck CHECK (
        (alias_visibility = 'PUBLIC' AND bound_agent_def_id IS NULL)
        OR (alias_visibility = 'INTERNAL_LEGACY' AND bound_agent_def_id IS NOT NULL)
    );

ALTER TABLE llm_public_alias_t
    DROP CONSTRAINT IF EXISTS llm_public_alias_bound_agent_fk;
ALTER TABLE llm_public_alias_t
    ADD CONSTRAINT llm_public_alias_bound_agent_fk
    FOREIGN KEY(host_id, bound_agent_def_id)
    REFERENCES agent_definition_t(host_id, agent_def_id) ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS llm_public_alias_bound_agent_idx
    ON llm_public_alias_t(host_id, bound_agent_def_id)
    WHERE alias_visibility = 'INTERNAL_LEGACY' AND active IS TRUE;

COMMIT;
-- END INLINED patch_20260719_03_llm_production_integration.sql

-- BEGIN INLINED patch_20260721_01_llm_model_rename.sql
-- Preserve existing catalog data while adopting the final LLM model naming.
-- The guards make this safe on a fresh baseline that already has the new names.
BEGIN;

DO $migration$
DECLARE
    constraint_rename record;
BEGIN
    IF to_regclass('llm_model_catalog_t') IS NOT NULL THEN
        IF to_regclass('llm_model_t') IS NOT NULL THEN
            RAISE EXCEPTION 'cannot rename llm_model_catalog_t: llm_model_t already exists';
        END IF;
        ALTER TABLE llm_model_catalog_t RENAME TO llm_model_t;
    END IF;

    IF to_regclass('llm_model_t') IS NULL THEN
        RAISE EXCEPTION 'LLM model table is missing';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = current_schema()
           AND table_name = 'llm_model_t'
           AND column_name = 'model_catalog_id'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
             WHERE table_schema = current_schema()
               AND table_name = 'llm_model_t'
               AND column_name = 'model_id'
        ) THEN
            RAISE EXCEPTION 'llm_model_t contains both model_catalog_id and model_id';
        END IF;
        ALTER TABLE llm_model_t RENAME COLUMN model_catalog_id TO model_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = current_schema()
           AND table_name = 'llm_model_registration_t'
           AND column_name = 'model_catalog_id'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
             WHERE table_schema = current_schema()
               AND table_name = 'llm_model_registration_t'
               AND column_name = 'model_id'
        ) THEN
            RAISE EXCEPTION 'llm_model_registration_t contains both model_catalog_id and model_id';
        END IF;
        ALTER TABLE llm_model_registration_t RENAME COLUMN model_catalog_id TO model_id;
    END IF;

    FOR constraint_rename IN
        SELECT * FROM (VALUES
            ('llm_model_t', 'llm_model_catalog_t_pkey', 'llm_model_t_pkey'),
            ('llm_model_t', 'llm_model_catalog_t_host_id_fkey', 'llm_model_t_host_id_fkey'),
            ('llm_model_t', 'llm_model_catalog_t_host_id_provider_type_physical_model_id_key', 'llm_model_t_host_id_provider_type_physical_model_id_key'),
            ('llm_model_t', 'llm_model_catalog_t_lifecycle_status_check', 'llm_model_t_lifecycle_status_check'),
            ('llm_model_t', 'llm_model_catalog_t_context_token_limit_check', 'llm_model_t_context_token_limit_check'),
            ('llm_model_t', 'llm_model_catalog_t_output_token_limit_check', 'llm_model_t_output_token_limit_check'),
            ('llm_model_t', 'llm_model_catalog_t_modalities_check', 'llm_model_t_modalities_check'),
            ('llm_model_t', 'llm_model_catalog_t_operations_check', 'llm_model_t_operations_check'),
            ('llm_model_t', 'llm_model_catalog_t_declared_capabilities_check', 'llm_model_t_declared_capabilities_check'),
            ('llm_model_t', 'llm_model_catalog_t_aggregate_version_check', 'llm_model_t_aggregate_version_check'),
            ('llm_model_registration_t', 'llm_model_registration_t_host_id_model_catalog_id_fkey', 'llm_model_registration_t_host_id_model_id_fkey'),
            ('llm_model_registration_t', 'llm_model_registration_t_host_id_model_catalog_id_environme_key', 'llm_model_registration_t_host_id_model_id_environment_key')
        ) AS names(table_name, old_name, new_name)
    LOOP
        IF EXISTS (
            SELECT 1
              FROM pg_constraint constraint_entry
              JOIN pg_class relation ON relation.oid = constraint_entry.conrelid
              JOIN pg_namespace namespace ON namespace.oid = relation.relnamespace
             WHERE namespace.nspname = current_schema()
               AND relation.relname = constraint_rename.table_name
               AND constraint_entry.conname = constraint_rename.old_name
        ) THEN
            IF EXISTS (
                SELECT 1
                  FROM pg_constraint constraint_entry
                  JOIN pg_class relation ON relation.oid = constraint_entry.conrelid
                  JOIN pg_namespace namespace ON namespace.oid = relation.relnamespace
                 WHERE namespace.nspname = current_schema()
                   AND relation.relname = constraint_rename.table_name
                   AND constraint_entry.conname = constraint_rename.new_name
            ) THEN
                RAISE EXCEPTION 'cannot rename constraint %: % already exists',
                    constraint_rename.old_name, constraint_rename.new_name;
            END IF;
            EXECUTE format(
                'ALTER TABLE %I RENAME CONSTRAINT %I TO %I',
                constraint_rename.table_name,
                constraint_rename.old_name,
                constraint_rename.new_name
            );
        END IF;
    END LOOP;


    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = current_schema()
           AND table_name = 'llm_model_t'
           AND column_name = 'model_id'
    ) OR NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = current_schema()
           AND table_name = 'llm_model_registration_t'
           AND column_name = 'model_id'
    ) THEN
        RAISE EXCEPTION 'LLM model rename migration is incomplete';
    END IF;
END
$migration$;

COMMIT;
-- END INLINED patch_20260721_01_llm_model_rename.sql

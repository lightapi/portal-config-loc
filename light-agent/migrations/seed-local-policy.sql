BEGIN;

CREATE TEMP TABLE local_agent_policy_seed_input(
    host_id UUID NOT NULL,
    agent_def_id UUID NOT NULL
) ON COMMIT DROP;
INSERT INTO local_agent_policy_seed_input(host_id, agent_def_id)
VALUES (:'host_id'::UUID, :'agent_def_id'::UUID);

DO $$
DECLARE
    selected_definition agent_definition_t%ROWTYPE;
    snapshot_id UUID;
    definition_digest TEXT;
    profile_digest TEXT;
    model_digest TEXT;
    catalog_digest TEXT;
    memory_digest TEXT;
    execution_digest TEXT;
    channel_digest TEXT;
    boundary_digest TEXT;
    policy_document_text TEXT;
    policy_document JSONB;
    policy_digest_value TEXT;
    snapshot_hash TEXT;
BEGIN
    SELECT *
      INTO selected_definition
      FROM agent_definition_t
     WHERE (host_id, agent_def_id) = (
         SELECT host_id, agent_def_id FROM local_agent_policy_seed_input
     )
       AND active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'local Agent definition %/% is missing or inactive',
            (SELECT host_id FROM local_agent_policy_seed_input),
            (SELECT agent_def_id FROM local_agent_policy_seed_input);
    END IF;

    definition_digest := 'sha256:' || encode(sha256(convert_to(
        jsonb_build_object(
            'agentDefId', selected_definition.agent_def_id,
            'aggregateVersion', selected_definition.aggregate_version,
            'materializerId', selected_definition.materializer_id,
            'materializerVersion', selected_definition.materializer_version
        )::TEXT, 'UTF8')), 'hex');
    profile_digest := 'sha256:' || encode(sha256(convert_to(
        selected_definition.product_profile, 'UTF8')), 'hex');
    model_digest := 'sha256:' || encode(sha256(convert_to(
        jsonb_build_object(
            'modelAliasId', selected_definition.model_alias_id,
            'modelPolicyId', selected_definition.model_policy_id,
            'modelProvider', selected_definition.model_provider,
            'modelName', selected_definition.model_name
        )::TEXT, 'UTF8')), 'hex');
    catalog_digest := 'sha256:' || encode(sha256(convert_to('{}', 'UTF8')), 'hex');
    memory_digest := 'sha256:' || encode(sha256(convert_to('{}', 'UTF8')), 'hex');
    execution_digest := 'sha256:' || encode(sha256(convert_to(
        jsonb_build_object(
            'maximumSessionSeconds', selected_definition.maximum_session_seconds,
            'maximumTurnSeconds', selected_definition.maximum_turn_seconds
        )::TEXT, 'UTF8')), 'hex');
    channel_digest := 'sha256:' || encode(sha256(convert_to('{}', 'UTF8')), 'hex');
    boundary_digest := 'sha256:' || encode(sha256(convert_to('{}', 'UTF8')), 'hex');

    snapshot_hash := md5(concat_ws(':', selected_definition.host_id,
        selected_definition.agent_def_id, selected_definition.aggregate_version,
        definition_digest, profile_digest, model_digest, catalog_digest,
        memory_digest, execution_digest, channel_digest, boundary_digest));
    snapshot_id := (substr(snapshot_hash, 1, 8) || '-' ||
        substr(snapshot_hash, 9, 4) || '-7' || substr(snapshot_hash, 14, 3) ||
        '-8' || substr(snapshot_hash, 18, 3) || '-' ||
        substr(snapshot_hash, 21, 12))::UUID;

    policy_document_text := format(
        '{"snapshotId":"%s","definitionDigest":"%s","productProfileDigest":"%s","modelDigest":"%s","catalogDigest":"%s","memoryDigest":"%s","executionDigest":"%s","channelDigest":"%s","dataBoundaryDigest":"%s","tools":{}}',
        snapshot_id, definition_digest, profile_digest, model_digest,
        catalog_digest, memory_digest, execution_digest, channel_digest,
        boundary_digest);
    policy_document := policy_document_text::JSONB;
    policy_digest_value := 'sha256:' || encode(sha256(convert_to(
        policy_document_text, 'UTF8')), 'hex');

    INSERT INTO agent_policy_snapshot_t(
        host_id, policy_snapshot_id, agent_def_id, definition_digest,
        product_profile_digest, model_digest, catalog_digest, memory_digest,
        execution_digest, channel_digest, data_boundary_digest,
        resolved_snapshot, policy_digest
    ) VALUES (
        selected_definition.host_id, snapshot_id,
        selected_definition.agent_def_id, definition_digest, profile_digest,
        model_digest, catalog_digest, memory_digest, execution_digest,
        channel_digest, boundary_digest, policy_document, policy_digest_value
    ) ON CONFLICT(host_id, policy_snapshot_id) DO NOTHING;

    IF NOT EXISTS (
        SELECT 1
          FROM agent_policy_snapshot_t snapshot
         WHERE snapshot.host_id = selected_definition.host_id
           AND snapshot.agent_def_id = selected_definition.agent_def_id
           AND snapshot.policy_snapshot_id = snapshot_id
           AND snapshot.policy_digest = policy_digest_value
           AND snapshot.revoked_ts IS NULL
    ) THEN
        RAISE EXCEPTION 'local Agent policy snapshot identity collision';
    END IF;

    UPDATE agent_definition_t
       SET policy_snapshot_id = snapshot_id,
           policy_snapshot = policy_document,
           policy_digest = policy_digest_value,
           update_ts = CURRENT_TIMESTAMP
     WHERE host_id = selected_definition.host_id
       AND agent_def_id = selected_definition.agent_def_id;
END $$;

COMMIT;

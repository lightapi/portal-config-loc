BEGIN;

ALTER TABLE agent_definition_t
    ADD COLUMN IF NOT EXISTS policy_snapshot_id UUID;

UPDATE agent_definition_t definition
   SET policy_snapshot_id = snapshot.policy_snapshot_id
  FROM agent_policy_snapshot_t snapshot
 WHERE definition.policy_snapshot_id IS NULL
   AND definition.policy_digest IS NOT NULL
   AND snapshot.host_id = definition.host_id
   AND snapshot.agent_def_id = definition.agent_def_id
   AND snapshot.policy_digest = definition.policy_digest
   AND snapshot.revoked_ts IS NULL;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM agent_definition_t definition
         WHERE definition.policy_digest IS NOT NULL
           AND definition.policy_snapshot_id IS NULL
    ) THEN
        RAISE EXCEPTION
            'agent definitions with a policy digest must resolve to one active policy snapshot before upgrade';
    END IF;
END $$;

ALTER TABLE agent_definition_t
    DROP CONSTRAINT IF EXISTS agent_definition_policy_snapshot_fk;
ALTER TABLE agent_policy_snapshot_t
    DROP CONSTRAINT IF EXISTS agent_policy_snapshot_agent_identity_uk;
ALTER TABLE agent_policy_snapshot_t
    ADD CONSTRAINT agent_policy_snapshot_agent_identity_uk
    UNIQUE(host_id, agent_def_id, policy_snapshot_id);

ALTER TABLE agent_definition_t
    ADD CONSTRAINT agent_definition_policy_snapshot_fk
    FOREIGN KEY(host_id, agent_def_id, policy_snapshot_id)
    REFERENCES agent_policy_snapshot_t(host_id, agent_def_id, policy_snapshot_id)
    ON DELETE RESTRICT;

COMMIT;

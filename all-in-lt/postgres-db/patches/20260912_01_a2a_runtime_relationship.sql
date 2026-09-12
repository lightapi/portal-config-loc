SET search_path=configserver;
-- Gateway API association and A2A runtime are separate instances.
-- Run with search_path set to the target Portal schema.
BEGIN;
CREATE UNIQUE INDEX IF NOT EXISTS instance_api_agent_identity_uk
    ON instance_api_t(host_id,instance_api_id,api_version_id);
ALTER TABLE agent_a2a_binding_t DROP CONSTRAINT IF EXISTS agent_a2a_binding_instance_agent_fk;
ALTER TABLE agent_a2a_binding_t ADD CONSTRAINT agent_a2a_binding_instance_agent_fk
    FOREIGN KEY(host_id,instance_api_id,agent_def_id)
    REFERENCES instance_api_t(host_id,instance_api_id,api_version_id) ON DELETE CASCADE;
ALTER TABLE agent_a2a_binding_t DROP CONSTRAINT IF EXISTS agent_a2a_binding_runtime_fk;
ALTER TABLE agent_a2a_binding_t ADD CONSTRAINT agent_a2a_binding_runtime_fk
    FOREIGN KEY(host_id,runtime_instance_id)
    REFERENCES instance_t(host_id,instance_id) ON DELETE CASCADE;
INSERT INTO cascade_relationship_policy_t
(parent_schema,parent_table,child_schema,child_table,constraint_name,delete_action,restore_action,policy_description)
VALUES (current_schema(),'instance_t',current_schema(),'agent_a2a_binding_t','agent_a2a_binding_runtime_fk','IGNORE','NONE','A2A runtime binding lifecycle is command-owned and independently audited')
ON CONFLICT(parent_schema,parent_table,child_schema,child_table,constraint_name)
DO UPDATE SET delete_action=EXCLUDED.delete_action,restore_action=EXCLUDED.restore_action,policy_description=EXCLUDED.policy_description;
COMMIT;

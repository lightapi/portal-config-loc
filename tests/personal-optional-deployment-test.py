#!/usr/bin/env python3
"""Full-stack deployment has no profile switches; diagnostics remain available."""
import json, os, subprocess, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
INSTALL=ROOT.parent/'light-portal-install'
class OptionalDeployment(unittest.TestCase):
    def test_full_stack_has_no_compose_profiles(self):
        import yaml
        services=yaml.safe_load((ROOT/'all-in-lt/docker-compose.yml').read_text())['services']
        self.assertTrue(all('profiles' not in service for service in services.values()))
        overlay=yaml.safe_load((ROOT/'all-in-lt/workflow-actions/compose.yml').read_text())['services']
        for name in set(services) | set(overlay):
            self.assertNotIn('codex-personal', name)
            self.assertNotIn('claude-personal', name)
        self.assertNotIn('COMPOSE_PROFILES', (ROOT/'scripts/deploy-local.sh').read_text())
    def test_required_services_exclude_retired_personal_agents(self):
        script=(ROOT/'scripts/deploy-local.sh').read_text()
        body=script[script.index('required_runtime_services() {'):script.index('\nlog_required_service_diagnostics()')]
        for actions in ['', '/prepared/workflow-actions']:
            with self.subTest(workflow_actions=bool(actions)):
                env=dict(os.environ, REPO_DIR='/workspace/portal-config-loc',
                         DOCKER_COMPOSE_DIR='/workspace/portal-config-loc/all-in-lt',
                         WORKFLOW_ACTIONS_DIR=actions)
                services=subprocess.check_output(['bash','-c',body+'\nrequired_runtime_services'],env=env,text=True).splitlines()
                for service in ['postgres', 'light-workflow', 'light-a2a']:
                    self.assertIn(service, services)
                for service in ['light-agent-claude-personal', 'light-agent-claude-personal-workflow',
                                'light-agent-codex-personal', 'light-agent-codex-personal-workflow']:
                    self.assertNotIn(service, services)
    def test_installer_diagnostics_do_not_validate_broken_enrollment(self):
        script=(INSTALL/'install.sh').read_text()
        start=script.index('compose() {');body=script[start:script.index('\nload_env_file_var()',start)]
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);runtime=root/'light-workflow-runner-claude-personal/.runtime';runtime.mkdir(parents=True);(runtime/'runner.yml').touch()
            code='docker() { echo "docker-called"; }; python3() { return 42; }; light_portal_env_file=/nonexistent\n'+body
            for action in ['down','ps','logs']:
                result=subprocess.run(['bash','-c',code+'\ncompose '+action],cwd=root,capture_output=True,text=True)
                self.assertEqual(result.returncode,0,result.stderr);self.assertIn('docker-called',result.stdout)
            result=subprocess.run(['bash','-c',code+'\ncompose up'],cwd=root,capture_output=True,text=True)
            self.assertNotEqual(result.returncode,0);self.assertNotIn('docker-called',result.stdout)
if __name__=='__main__':unittest.main()

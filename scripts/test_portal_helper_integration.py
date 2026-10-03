"""Real helper entry points with only mocked container/database commands."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
KEYS = ('PORTAL_HYBRID_COMMAND_IMAGE', 'PORTAL_HYBRID_QUERY_IMAGE')


def pair(character):
    return {key: 'networknt/portal-hybrid-' + side + '@sha256:' + character * 64
            for key, side in zip(KEYS, ('command', 'query'))}


def write_env(path, values):
    path.write_text(''.join(key + '=' + value + '\n' for key, value in values.items()))


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class HelperIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for relative in ('scripts/import-event-deltas.sh', 'scripts/wait-for-postgres.sh',
                         'scripts/check-lt-release-images.py', 'scripts/portal-image-fragment.py',
                         'scripts/portal-packaged-images.sh', 'all-in-lt/docker-compose.yml',
                         'all-in-lt/light-identity-issuer/issuer-tokens.sh'):
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)
            target.chmod(0o755)
        self.release = self.root / 'release.env'
        checker = load_module('checker', ROOT / 'scripts/check-lt-release-images.py')
        values = {key: 'networknt/test:batch' for key in checker.required_images(ROOT / 'all-in-lt/docker-compose.yml')}
        values.update({key: 'networknt/portal-hybrid-' + side + ':2.2.1' for key, side in zip(KEYS, ('command', 'query'))})
        write_env(self.release, values)
        self.fragment = self.root / 'portal.env'
        write_env(self.fragment, pair('a'))
        self.local = self.root / 'private.env'
        write_env(self.local, pair('b'))
        self.calls = self.root / 'calls.jsonl'
        fake_bin = self.root / 'bin'
        fake_bin.mkdir()
        fake = fake_bin / 'docker'
        fake.write_text('#!' + sys.executable + '\nimport json,os,sys\n'
                        'with open(os.environ["MOCK_CALLS"],"a") as f: f.write(json.dumps({"argv":sys.argv[1:],"pair":{k:os.environ.get(k) for k in ' + repr(KEYS) + '}})+"\\n")\n')
        fake.chmod(0o755)
        (self.root / 'empty-deltas').mkdir()
        self.env = {key: value for key, value in os.environ.items()
                    if key not in (*KEYS, 'PORTAL_IMAGE_ENV_FILE') and not key.startswith('PG')
                    and 'DATABASE' not in key and 'JDBC' not in key and '_DB_' not in key}
        self.env.update(PATH=str(fake_bin) + ':' + self.env['PATH'], CONTAINER_CMD=str(fake),
                        COMPOSE_CMD=str(fake) + ' compose', MOCK_CALLS=str(self.calls),
                        RELEASE_IMAGE_ENV_FILE=str(self.release), LIGHT_PORTAL_ENV_FILE=str(self.local),
                        EVENT_DELTA_DIR=str(self.root / 'empty-deltas'))

    def run_helper(self, helper, env):
        script = 'scripts/import-event-deltas.sh' if helper == 'import' else 'all-in-lt/light-identity-issuer/issuer-tokens.sh'
        args = ['bash', str(self.root / script)] + ([] if helper == 'import' else ['list'])
        result = subprocess.run(args, cwd=self.root, env=env, stdin=subprocess.DEVNULL, capture_output=True, text=True)
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()] if self.calls.exists() else []
        return result, calls

    def test_standalone_import_fragment_wins_over_old_release_process_and_local_file(self):
        env = dict(self.env, PORTAL_IMAGE_ENV_FILE=str(self.fragment), **{key: 'old-process-tag' for key in KEYS})
        result, calls = self.run_helper('import', env)
        self.assertEqual(result.returncode, 0, result.stderr)
        up = next(call for call in calls if 'up' in call['argv'])
        self.assertEqual(up['pair'], pair('a'))
        self.assertEqual(up['argv'][-2:], ['hybrid-command', 'hybrid-query'])
        self.assertTrue(all(call['pair'] == pair('a') for call in calls))

    def test_issuer_fragment_wins_before_stop_run_and_up(self):
        result, calls = self.run_helper('issuer', dict(self.env, PORTAL_IMAGE_ENV_FILE=str(self.fragment)))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([next(word for word in call['argv'] if word in ('stop', 'run', 'up')) for call in calls], ['stop', 'run', 'up'])
        self.assertTrue(all(call['pair'] == pair('a') for call in calls))

    def test_old_tags_without_fragment_refuse_before_all_side_effects(self):
        for helper in ('import', 'issuer'):
            with self.subTest(helper=helper):
                env = dict(self.env, LIGHT_PORTAL_ENV_FILE=str(self.root / 'absent'))
                result, calls = self.run_helper(helper, env)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, [])

    def test_invalid_or_incomplete_fragment_refuses_before_all_side_effects(self):
        for contents in ('PORTAL_HYBRID_COMMAND_IMAGE=networknt/portal-hybrid-command:2.2.1\n',
                         ''.join(key + '=' + value + '\n' for key, value in pair('a').items()) + 'EXTRA=value\n'):
            self.fragment.write_text(contents)
            for helper in ('import', 'issuer'):
                with self.subTest(helper=helper, contents=contents):
                    result, calls = self.run_helper(helper, dict(self.env, PORTAL_IMAGE_ENV_FILE=str(self.fragment)))
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(calls, [])

    def test_local_env_and_process_precedence_match_compose(self):
        module = load_module('portal_images', ROOT / 'scripts/portal-image-fragment.py')
        self.assertEqual(module.effective_images([self.release, self.local], {}), pair('b'))
        self.assertEqual(module.effective_images([self.release, self.local], pair('c')), pair('c'))
        with self.assertRaises(ValueError):
            module.effective_images([self.release, self.local], {KEYS[0]: ''})
        for helper in ('import', 'issuer'):
            result, calls = self.run_helper(helper, dict(self.env, **pair('c')))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(all(call['pair'] == pair('c') for call in calls))
            self.calls.unlink()

    def test_release_checker_itself_rejects_old_tags_and_accepts_fragment(self):
        checker = load_module('checker', ROOT / 'scripts/check-lt-release-images.py')
        script = ROOT / 'scripts/check-lt-release-images.py'
        args = [sys.executable, '-B', str(script), str(ROOT / 'all-in-lt/docker-compose.yml'), str(self.release)]
        self.assertNotEqual(subprocess.run(args, env=self.env, capture_output=True).returncode, 0)
        self.assertEqual(subprocess.run(args, env=dict(self.env, PORTAL_IMAGE_ENV_FILE=str(self.fragment)), capture_output=True).returncode, 0)


if __name__ == '__main__':
    unittest.main()

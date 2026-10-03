import os
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
DIGEST = 'a' * 64
VALUES = {f'PORTAL_HYBRID_{side.upper()}_IMAGE': f'networknt/portal-hybrid-{side}@sha256:{DIGEST}' for side in ('command', 'query')}


class PackagedImagesTests(unittest.TestCase):
    def test_full_stack_checker_keeps_non_portal_requirements(self):
        spec = importlib.util.spec_from_file_location('checker', ROOT / 'scripts/check-lt-release-images.py')
        checker = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(checker)
        required = checker.required_images(ROOT / 'all-in-lt/docker-compose.yml')
        self.assertIn('LIGHT_WORKFLOW_IMAGE', required)
        self.assertIn('LIGHT_IDENTITY_ISSUER_IMAGE', required)
        self.assertTrue(set(VALUES).isdisjoint(required))
        with tempfile.TemporaryDirectory() as directory:
            env_file = Path(directory) / 'release.env'
            pair = ''.join(f'{key}={value}\n' for key, value in VALUES.items())
            env_file.write_text(''.join(f'{key}=networknt/test:release\n' for key in required) + pair)
            self.assertEqual(checker.validate(ROOT / 'all-in-lt/docker-compose.yml', env_file), [])
            env_file.write_text(''.join(f'{key}=networknt/test:release\n' for key in required if key != 'LIGHT_WORKFLOW_IMAGE') + pair)
            self.assertIn('LIGHT_WORKFLOW_IMAGE', ' '.join(checker.validate(ROOT / 'all-in-lt/docker-compose.yml', env_file)))

    def test_fragment_valid_and_invalid(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / 'images.env'
            valid = ''.join(f'{key}={value}\n' for key, value in VALUES.items())
            for text, expected in [(valid, 0), (valid + 'OTHER=secret\n', 1), (valid + valid, 1), (valid.replace('@sha256:' + DIGEST, ':latest'), 1), (valid.splitlines()[0], 1)]:
                file.write_text(text)
                result = subprocess.run(['python3', '-B', str(ROOT / 'scripts/portal-image-fragment.py'), str(file)], capture_output=True)
                self.assertEqual(result.returncode, expected)

    def test_fragment_overrides_process_and_release_file(self):
        with tempfile.TemporaryDirectory() as directory:
            fragment = Path(directory) / 'images.env'
            fragment.write_text(''.join(f'{key}={value}\n' for key, value in VALUES.items()))
            release_file = Path(directory) / 'release.env'
            release_file.write_text(''.join(f'{key}=release-file-old-value\n' for key in VALUES))
            env = dict(os.environ, DEPLOY_LOCAL_SOURCE_ONLY='true', PORTAL_IMAGE_ENV_FILE=str(fragment), RELEASE_IMAGE_ENV_FILE=str(release_file), **{key: 'old-value' for key in VALUES})
            code = 'source scripts/deploy-local.sh lt status; configure_release_image_env; configure_portal_packaged_images; printf "%s\\n" "$PORTAL_HYBRID_COMMAND_IMAGE" "$PORTAL_HYBRID_QUERY_IMAGE"'
            result = subprocess.run(['bash', '-c', code], cwd=ROOT, env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines()[-2:], list(VALUES.values()))

    def test_all_in_lt_skips_only_hybrid_zip_assets(self):
        env = dict(os.environ, DEPLOY_LOCAL_SOURCE_ONLY='true')
        code = 'source scripts/deploy-local.sh lt status; extract_archive_if_missing() { printf "%s\\n" "$1"; }; ensure_release_assets'
        result = subprocess.run(['bash', '-c', code], cwd=ROOT, env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('hybrid-command.zip', result.stdout)
        self.assertNotIn('hybrid-query.zip', result.stdout)
        self.assertIn('lightapi.zip', result.stdout)
        other = subprocess.run(['bash', '-c', code.replace('lt status', 'kafka status')], cwd=ROOT, env=env, capture_output=True, text=True)
        self.assertEqual(other.returncode, 0, other.stderr)
        self.assertIn('hybrid-command.zip', other.stdout)
        self.assertIn('hybrid-query.zip', other.stdout)

    def test_seven_unsafe_forms_still_refuse(self):
        for args in [[], ['lt'], ['lt', 'restart'], ['lt', 'rust'], ['lt', 'rust', 'restart'], ['lt', 'restart', 'light-workflow'], ['lt', 'rust', 'restart', 'controller']]:
            result = subprocess.run(['bash', 'scripts/deploy-local.sh', *args], cwd=ROOT, capture_output=True, text=True)
            self.assertEqual(result.returncode, 2, args)
            self.assertIn('W7_DEPLOY_REFUSED', result.stderr)


if __name__ == '__main__':
    unittest.main()

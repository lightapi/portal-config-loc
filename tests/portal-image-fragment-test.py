#!/usr/bin/env python3
"""Accept equivalent Docker Hub names without broadening repository trust."""
import importlib.util
from pathlib import Path
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/portal-image-fragment.py'
spec = importlib.util.spec_from_file_location('portal_fragment', SCRIPT)
fragment = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fragment)


class PortalImageFragmentTests(unittest.TestCase):
    def test_hub_tags_and_digests_in_fragments_env_files_and_process_overrides(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'images.env'
            for prefix in ('', 'docker.io/'):
                for suffix in (':release-01', '@sha256:' + 'a' * 64):
                    with self.subTest(prefix=prefix, suffix=suffix):
                        values = {key: prefix + 'networknt/portal-hybrid-' + side + suffix
                                  for key, side in fragment.EXPECTED.items()}
                        path.write_text(''.join(key + '=' + value + '\n' for key, value in values.items()))
                        self.assertEqual(fragment.read_fragment(path), values)
                        self.assertEqual(fragment.effective_images([path], {}), values)
                        self.assertEqual(fragment.effective_images([], values), values)

    def test_invalid_registry_repository_side_and_digest_are_refused(self):
        valid = {key: 'docker.io/networknt/portal-hybrid-' + side + ':release-01'
                 for key, side in fragment.EXPECTED.items()}
        for image in ('evil.example/networknt/portal-hybrid-command:release-01',
                      'docker.io/other/portal-hybrid-command:release-01',
                      'docker.io/networknt/portal-hybrid-query:release-01',
                      'docker.io/networknt/portal-hybrid-command@sha256:invalid',
                      'docker.io/networknt/portal-hybrid-command',
                      'dockerXio/networknt/portal-hybrid-command:release-01'):
            with self.subTest(image=image), self.assertRaises(ValueError):
                fragment.validate(dict(valid, PORTAL_HYBRID_COMMAND_IMAGE=image))


if __name__ == '__main__':
    unittest.main()

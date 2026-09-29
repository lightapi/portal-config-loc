"""Exercise the generator through its CLI without changing workspace artifacts."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / 'portal-db'
PREFIX = 'CREATE DATABASE configserver;\n\\c configserver;\n\n'


class BootstrapGenerationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        workspace = Path(self.temp.name)
        (workspace / 'portal-db').symlink_to(SOURCE, target_is_directory=True)
        root = workspace / 'portal-config-loc'
        (root / 'scripts').mkdir(parents=True)
        self.script = root / 'scripts/generate-postgres-init.py'
        shutil.copyfile(ROOT / 'scripts/generate-postgres-init.py', self.script)
        seed = (SOURCE / 'postgres/init-lightapi.sql').read_text()
        previous = subprocess.check_output(
            ['git', '-C', str(SOURCE), 'show', 'HEAD:postgres/ddl.sql'], text=True)
        self.old = PREFIX + previous + '\n\n' + seed
        self.new = PREFIX + (SOURCE / 'postgres/ddl.sql').read_text() + '\n\n' + seed
        self.paths = [root / profile / 'postgres-db/init.sql'
                      for profile in ('all-in-lt', 'all-in-pg', 'all-in-one')]
        self.paths.append(workspace / 'light-portal-install/postgres-db/init.sql')
        for path in self.paths:
            path.parent.mkdir(parents=True)
            path.write_text(self.old)

    def run_cli(self, *args):
        return subprocess.run([sys.executable, str(self.script), '--installer', *args],
                              text=True, capture_output=True)

    def assert_rejected_without_writes(self):
        before = [path.read_bytes() for path in self.paths]
        result = self.run_cli()
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(all(path.read_bytes() == content
                            for path, content in zip(self.paths, before)), 'rejected batch changed a file')

    def test_known_baseline_and_repeated_generation(self):
        self.assertEqual(self.run_cli().returncode, 0)
        self.assertTrue(all(path.read_text() == self.new for path in self.paths))
        self.assertEqual(self.run_cli().returncode, 0)
        self.assertEqual(self.run_cli('--check').returncode, 0)

    def test_schema_older_than_head_is_an_accepted_upgrade_baseline(self):
        revisions = subprocess.check_output(
            ['git', '-C', str(SOURCE), 'log', '--format=%H', 'HEAD', '--', 'postgres/ddl.sql'],
            text=True).splitlines()
        self.assertGreaterEqual(len(revisions), 3)
        historical = subprocess.check_output(
            ['git', '-C', str(SOURCE), 'show', f'{revisions[2]}:postgres/ddl.sql'],
            text=True)
        seed = (SOURCE / 'postgres/init-lightapi.sql').read_text()
        self.paths[0].write_text(PREFIX + historical + '\n\n' + seed)
        self.assertEqual(self.run_cli().returncode, 0)
        self.assertEqual(self.paths[0].read_text(), self.new)

    def test_schema_edit_in_last_destination_aborts_entire_batch(self):
        self.paths[-1].write_text(self.old.replace('SET row_security = off;',
                                                  'SET row_security = on;'))
        self.assert_rejected_without_writes()

    def test_added_schema_statement_is_rejected_without_writes(self):
        self.paths[1].write_text(self.old.replace('SET row_security = off;',
            'SET row_security = off;\nCREATE TABLE distribution_local_t(id integer);'))
        self.assert_rejected_without_writes()

    def test_seed_edit_aborts_entire_batch(self):
        self.paths[-1].write_text(self.old + '\n-- distribution seed customization\n')
        self.assert_rejected_without_writes()

    def test_mismatched_restriction_pair_is_rejected(self):
        self.paths[0].write_text(self.old.replace('\\unrestrict ', '\\unrestrict wrong_'))
        self.assert_rejected_without_writes()

    def test_check_never_writes(self):
        self.paths[0].write_text(self.new.replace('SET row_security = off;', 'SET row_security = on;'))
        before = [path.read_bytes() for path in self.paths]
        self.assertNotEqual(self.run_cli('--check').returncode, 0)
        self.assertTrue(all(path.read_bytes() == content for path, content in zip(self.paths, before)))

    def test_plain_check_includes_installer(self):
        for path in self.paths:
            path.write_text(self.new)
        self.paths[-1].write_text(self.new.replace('SET row_security = off;', 'SET row_security = on;'))
        result = subprocess.run([sys.executable, str(self.script), '--check'],
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('light-portal-install', result.stderr)


if __name__ == '__main__':
    unittest.main()

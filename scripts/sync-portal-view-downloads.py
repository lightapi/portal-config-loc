#!/usr/bin/env python3
"""Synchronize pinned download helpers and tests; check is read-only by default."""
import argparse
import ast
import copy
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
import tempfile

REPOS = ('portal-config-bootstrap', 'portal-config-dev', 'light-portal-install')
SYMBOLS = ('download_opener', 'fetch')
SUPPORT = 'portal_view_download_contract.py'
MANIFEST = 'portal-view-download-source.json'


def functions(text, path):
    try:
        nodes = {node.name: node for node in ast.parse(text).body
                 if isinstance(node, ast.FunctionDef)}
    except SyntaxError as error:
        raise ValueError(f'{path}:{error.lineno}: invalid Python: {error.msg}') from error
    for name in (*SYMBOLS, 'stage'):
        if name not in nodes:
            raise ValueError(f'{path}: required function {name} is missing')
    return nodes


def fingerprint(node):
    node = copy.deepcopy(node)
    if node.body and isinstance(node.body[0], ast.Expr) and isinstance(
            node.body[0].value, ast.Constant) and isinstance(node.body[0].value.value, str):
        node.body.pop(0)
    for child in ast.walk(node):
        child._fields = tuple(field for field in child._fields if field != 'type_params')
    return hashlib.sha256(ast.dump(node).encode()).hexdigest()


def temporary_copy(path, data, mode):
    fd, name = tempfile.mkstemp(prefix='.' + path.name + '.sync-', dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, 'wb') as output:
            output.write(data)
            output.flush()
            os.fchmod(output.fileno(), mode)
            os.fsync(output.fileno())
        return temporary
    except BaseException:
        temporary.unlink(missing_ok=True)
        raise


def publish(updates):
    """Prepare all writes, replace each file atomically, and roll back on errors."""
    prepared, applied, retained = [], [], set()
    try:
        for path, data in updates:
            mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o644
            backup = temporary_copy(path, path.read_bytes(), mode) if path.exists() else None
            prepared.append((path, backup, None))
            replacement = temporary_copy(path, data, mode)
            prepared[-1] = (path, backup, replacement)
        for path, backup, replacement in prepared:
            os.replace(replacement, path)
            applied.append((path, backup))
    except BaseException as error:
        failures = []
        for path, backup in reversed(applied):
            try:
                if backup is None:
                    path.unlink()
                else:
                    os.replace(backup, path)
            except OSError as recovery_error:
                if backup is not None:
                    retained.add(backup)
                failures.append(f'{path}: {recovery_error}; backup={backup}')
        if failures:
            raise RuntimeError('write failed; rollback incomplete: ' + '; '.join(failures)) from error
        raise
    finally:
        for _, backup, replacement in prepared:
            for temporary in (backup, replacement):
                if temporary is not None and temporary not in retained:
                    temporary.unlink(missing_ok=True)


def synchronize(workspace, write=False):
    canonical = workspace / 'portal-config-loc/scripts'
    source_path = canonical / 'portal_view_release.py'
    source = source_path.read_text()
    nodes = functions(source, source_path)
    lines = source.splitlines(keepends=True)
    snippets = {name: ''.join(lines[nodes[name].lineno - 1:nodes[name].end_lineno])
                for name in SYMBOLS}
    support = (canonical / SUPPORT).read_bytes()
    manifest = (json.dumps({
        'canonicalSource': 'lightapi/portal-config-loc/scripts/portal_view_release.py',
        'symbols': {name: fingerprint(nodes[name]) for name in (*SYMBOLS, 'stage')},
        'fixtureSha256': hashlib.sha256(support).hexdigest(),
    }, indent=2, sort_keys=True) + '\n').encode()
    drift, updates = [], []
    for repo in ('portal-config-loc', *REPOS):
        scripts = workspace / repo / 'scripts'
        if repo != 'portal-config-loc':
            path = scripts / 'portal_view_release.py'
            text = path.read_text()
            target = functions(text, path)
            # Compare the full signature and body, independent of statement positions.
            if fingerprint(target['stage']) != fingerprint(nodes['stage']):
                raise ValueError(f'{path}: stage contract differs (signature or body)')
            target_lines = text.splitlines(keepends=True)
            for name in sorted(SYMBOLS, key=lambda key: target[key].lineno, reverse=True):
                node = target[name]
                current = ''.join(target_lines[node.lineno - 1:node.end_lineno])
                if current != snippets[name]:
                    drift.append(f'{repo}: {name}')
                    target_lines[node.lineno - 1:node.end_lineno] = [snippets[name]]
            replacement = ''.join(target_lines).encode()
            if replacement != text.encode():
                updates.append((path, replacement))
        for name, data in ((SUPPORT, support), (MANIFEST, manifest)):
            path = scripts / name
            if not path.is_file() or path.read_bytes() != data:
                drift.append(f'{repo}: {name}')
                updates.append((path, data))
    # All sources parse and all stage contracts match before publication starts.
    if write:
        publish(updates)
    return drift


def main(argv=None):
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--workspace', type=Path, default=Path(__file__).resolve().parents[2])
    mode = cli.add_mutually_exclusive_group()
    mode.add_argument('--check', action='store_true', help='read-only drift check (default)')
    mode.add_argument('--write', action='store_true', help='copy canonical helpers and fixture')
    args = cli.parse_args(argv)
    try:
        drift = synchronize(args.workspace, args.write)
    except (OSError, ValueError, RuntimeError) as error:
        print('Portal View download sync refused: ' + str(error), file=sys.stderr)
        return 2
    for item in drift:
        print(('updated ' if args.write else 'drift: ') + item)
    if not drift:
        print('Portal View download helpers and contract fixture are synchronized')
    return 0 if args.write or not drift else 1


if __name__ == '__main__':
    sys.exit(main())

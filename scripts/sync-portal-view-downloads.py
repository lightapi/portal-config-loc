#!/usr/bin/env python3
"""Check or synchronize the canonical download helpers and contract fixture."""
import argparse
import ast
from pathlib import Path
import sys

REPOS = ('portal-config-bootstrap', 'portal-config-dev', 'light-portal-install')
SYMBOLS = ('download_opener', 'fetch', 'download_batch')
SUPPORT = 'portal_view_download_contract.py'


def functions(text):
    return {node.name: node for node in ast.parse(text).body
            if isinstance(node, ast.FunctionDef)}


def synchronize(workspace, write=False):
    canonical = workspace / 'portal-config-loc/scripts'
    source = (canonical / 'portal_view_release.py').read_text()
    nodes = functions(source)
    lines = source.splitlines(keepends=True)
    snippets = {name: ''.join(lines[nodes[name].lineno - 1:nodes[name].end_lineno])
                for name in SYMBOLS}
    support = (canonical / SUPPORT).read_bytes()
    drift = []
    updates = []
    for repo in REPOS:
        scripts = workspace / repo / 'scripts'
        path = scripts / 'portal_view_release.py'
        text = path.read_text()
        target = functions(text)
        target_lines = text.splitlines(keepends=True)
        # Refuse a caller that no longer validates the downloader before mkdir.
        expected = ast.dump(nodes['stage'].body[1])
        if len(target['stage'].body) < 2 or ast.dump(target['stage'].body[1]) != expected:
            raise ValueError(str(path) + ': stage admission differs from canonical source')
        for name in sorted(SYMBOLS, key=lambda key: target[key].lineno, reverse=True):
            node = target[name]
            current = ''.join(target_lines[node.lineno - 1:node.end_lineno])
            if current != snippets[name]:
                drift.append(repo + ': ' + name)
                target_lines[node.lineno - 1:node.end_lineno] = [snippets[name]]
        replacement = ''.join(target_lines)
        if replacement != text:
            updates.append((path, replacement.encode()))
        support_path = scripts / SUPPORT
        if not support_path.is_file() or support_path.read_bytes() != support:
            drift.append(repo + ': ' + SUPPORT)
            updates.append((support_path, support))
    # Read and validate every target before changing any checkout.
    if write:
        for path, data in updates:
            path.write_bytes(data)
    return drift


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--workspace', type=Path, default=Path(__file__).resolve().parents[2])
    mode = cli.add_mutually_exclusive_group()
    mode.add_argument('--check', action='store_true', help='read-only drift check (default)')
    mode.add_argument('--write', action='store_true', help='copy canonical helpers and fixture')
    args = cli.parse_args()
    try:
        drift = synchronize(args.workspace, args.write)
    except (OSError, ValueError, KeyError) as error:
        print('Portal View download sync refused: ' + str(error), file=sys.stderr)
        return 2
    for item in drift:
        print(('updated ' if args.write else 'drift: ') + item)
    if not drift:
        print('Portal View download helpers and contract fixture are synchronized')
    return 0 if args.write or not drift else 1


if __name__ == '__main__':
    sys.exit(main())

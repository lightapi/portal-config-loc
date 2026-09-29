#!/usr/bin/env python3
"""Assemble complete local bootstrap SQL from the sibling canonical Portal DB."""
import argparse
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check', action='store_true')
parser.add_argument('--installer', action='store_true', help='also regenerate the sibling light-portal-install artifact')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = root.parent / 'portal-db' / 'postgres'
ddl = (source / 'ddl.sql').read_text()
seed = (source / 'init-lightapi.sql').read_text()
if re.search(r'(?m)^\s*\\i(?:r)?\s', ddl + seed):
    raise SystemExit('canonical bootstrap inputs must be standalone')
prefix = 'CREATE DATABASE configserver;\n\\c configserver;\n\n'
bootstrap = prefix + ddl + '\n\n' + seed
# Ignore only pg_dump's random restriction token, not schema content or versions.
def normalized_schema(text):
    return re.sub(r'^(\\(?:un)?restrict) \w+$', r'\1 TOKEN', text, flags=re.M).strip()


historical_revisions = subprocess.check_output(
    ['git', '-C', str(source.parent), 'log', '--format=%H', 'HEAD', '--', 'postgres/ddl.sql'],
    text=True).splitlines()
known_schemas = {normalized_schema(ddl)}
destinations = [root / profile / 'postgres-db' / 'init.sql'
                for profile in ('all-in-lt', 'all-in-pg', 'all-in-one')]
if args.installer or args.check:
    destinations.append(root.parent / 'light-portal-install' / 'postgres-db' / 'init.sql')
# Validate the entire batch before the first write, including the schema body.
for path in destinations:
    old = path.read_text()
    starts = re.findall(r'^\\restrict (\w+)$', old, re.M)
    ends = list(re.finditer(r'^\\unrestrict (\w+)\n', old, re.M))
    if not old.startswith(prefix) or len(starts) != 1 or len(ends) != 1 or starts[0] != ends[0][1]:
        raise SystemExit(f'{path}: invalid bootstrap prefix or restriction pair')
    end = ends[0]
    schema = normalized_schema(old[len(prefix):end.end()])
    while schema not in known_schemas and historical_revisions:
        revision = historical_revisions.pop(0)
        historical_ddl = subprocess.check_output(
            ['git', '-C', str(source), 'show', f'{revision}:postgres/ddl.sql'], text=True)
        known_schemas.add(normalized_schema(historical_ddl))
    if schema not in known_schemas or old[end.end():].strip() != seed.strip():
        raise SystemExit(f'{path}: review distribution-specific schema or seed content before regenerating')
    if args.check:
        if old != bootstrap:
            raise SystemExit(f'{path}: bootstrap differs from canonical inputs')
for path in destinations:
    if not args.check:
        path.write_text(bootstrap)
    print(f'{path.parent.parent.name}: canonical bootstrap {"verified" if args.check else "generated"}')

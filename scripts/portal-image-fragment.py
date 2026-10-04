#!/usr/bin/env python3
"""Resolve Portal image tags or digests without shell evaluation."""
import argparse
import os
from pathlib import Path
import re

EXPECTED = {
    'PORTAL_HYBRID_COMMAND_IMAGE': 'command',
    'PORTAL_HYBRID_QUERY_IMAGE': 'query',
}


def validate(values):
    if set(values) != set(EXPECTED):
        raise ValueError('Portal image selection must contain both overrides')
    for key, side in EXPECTED.items():
        if not re.fullmatch('networknt/portal-hybrid-' + side + r'(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}|@sha256:[0-9a-f]{64})', values[key]):
            raise ValueError('Portal images require an image tag or digest: ' + key)
    return values


def read_fragment(path):
    values = {}
    for line in Path(path).read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        key, separator, value = line.partition('=')
        if not separator or key not in EXPECTED or key in values:
            raise ValueError('Invalid Portal-only image fragment')
        values[key] = value
    return validate(values)


def effective_images(env_files, environ=None):
    """Compose order: later env files, then process environment, then fragment."""
    environ = os.environ if environ is None else environ
    values = {}
    for filename in env_files:
        if not filename or not Path(filename).is_file():
            continue
        for line in Path(filename).read_text().splitlines():
            key, separator, value = line.strip().partition('=')
            if separator and key in EXPECTED:
                # Only literal image references are accepted. No interpolation,
                # commands or full-file evaluation, even in a private env file.
                if len(value) >= 2 and value[0] in ('"', "'") and value[-1] == value[0]:
                    value = value[1:-1]
                values[key] = value
    values.update({key: environ[key] for key in EXPECTED if key in environ})
    if environ.get('PORTAL_IMAGE_ENV_FILE'):
        values = read_fragment(environ['PORTAL_IMAGE_ENV_FILE'])
    return validate(values)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('fragment', nargs='?')
    parser.add_argument('--effective', action='store_true')
    parser.add_argument('--env-file', action='append', default=[])
    args = parser.parse_args()
    try:
        if args.effective and args.fragment is None:
            values = effective_images(args.env_file)
        elif args.fragment and not args.effective and not args.env_file:
            values = read_fragment(args.fragment)
        else:
            parser.error('supply a fragment or --effective with ordered --env-file arguments')
        for key in EXPECTED:
            print(key + '=' + values[key])
    except (ValueError, OSError):
        # Private environment and fragment contents are never echoed on errors.
        parser.exit(1, 'Portal image selection refused: supply both image tags or digests in the environment files or an optional Portal-only fragment\n')


if __name__ == '__main__':
    main()

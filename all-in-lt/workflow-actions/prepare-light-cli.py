#!/usr/bin/env python3
"""Let the Light CLI use the Gateway's /mcp route with a user token alone.

Development-only, in the same spirit as prepare-portal-ingress.py: it edits the live Gateway
caller policy, so it prepares first, activates only with --activate, saves what it replaces,
and can roll back. It never prints credential material.

The Light CLI is open source and downloadable anywhere, so it cannot keep an application
secret or certificate; the only thing that identifies a call is the user's own token. What such
a caller may do is decided by the user's roles and the route's ACL. See
`light-portal-doc/src/design/light-oauth/device-authorization.md` and
`light-fabric/docs/src/design/light-cli.md`.

What it changes, and nothing else:

* sets `policy.interactiveUserOnly = true`: a request with NO application credential
  (`x-scope-token`) is admitted on its user token alone, as an interactive caller with no action
  reference. A request that presents an application credential is judged exactly as before, and
  a request that claims a workflow action without one is refused;
* removes the `com.networknt.light-cli-1.0.0` certificate-trusted app profile that an earlier
  version of this script added (the CLI no longer enrols or presents a certificate). The extra CA
  file in the Gateway's client CA bundle is harmless and is left alone.

The Gateway image must be a build that knows `interactiveUserOnly`: an older one refuses to start
on the unknown field, and this script then restores the previous policy itself.

Usage:
    prepare-light-cli.py [--output DIR]                  prepare and show, change nothing
    prepare-light-cli.py [--output DIR] --activate       install, restart, verify
    prepare-light-cli.py --rollback DIR                  restore what DIR saved
"""
import argparse
import hashlib
import json
import re
import ssl
import subprocess
import sys
import time
from pathlib import Path

SERVICE = 'com.networknt.light-cli-1.0.0'
GATEWAY = 'light-gateway'
POLICY_DEST = '/config/workflow-actions.yml'
PKI_DEST = '/run/workflow-actions'
HERE = Path(__file__).resolve().parent
GATEWAY_CA = HERE.parent / 'light-gateway-rust' / 'config' / 'ca.pem'
CERT_BLOCK = re.compile(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', re.S)


def run(*args, check=True):
    return subprocess.run(args, check=check, capture_output=True).stdout


def die(message):
    print('error: ' + message, file=sys.stderr)
    sys.exit(1)


def certificates(pem_text):
    return [(block, ssl.PEM_cert_to_DER_cert(block)) for block in CERT_BLOCK.findall(pem_text)]


def read_gateway_file(path):
    try:
        return run('docker', 'exec', GATEWAY, 'cat', path)
    except subprocess.CalledProcessError:
        die(f'could not read {path} in {GATEWAY}. Is the Gateway running, and is the workflow-actions '
            'overlay active (workflow-actions/.runtime/enabled, created by prepare.py)?')


def parse_policy(raw):
    text = raw.decode()
    if not text.startswith('authorization: '):
        die('the Gateway policy is not in the expected `authorization: {json}` form')
    return json.loads(text.removeprefix('authorization: '))


def render_policy(config):
    return ('authorization: ' + json.dumps(config, separators=(',', ':')) + '\n').encode()


def mounts():
    listing = json.loads(run('docker', 'inspect', GATEWAY))[0]
    sources = {m['Destination']: m['Source'] for m in listing['Mounts']}
    for wanted in (POLICY_DEST, PKI_DEST):
        if wanted not in sources:
            die(f'{GATEWAY} has no mount at {wanted}; the workflow-actions overlay is not active')
    return sources[POLICY_DEST], sources[PKI_DEST], listing['Config']['Image']


def private(path, data):
    import os
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'wb') as handle:
        handle.write(data if isinstance(data, bytes) else data.encode())


def install(out, policy_file):
    """Write into the Gateway's read-only policy mount through a throwaway root container.

    The policy is written in place (`cat >`), never replaced, so the Gateway's bind
    mount keeps pointing at the same file.
    """
    policy_path, pki_path, image = mounts()
    script = f'set -eu; cat /source/{policy_file} > /policy'
    run('docker', 'run', '--rm', '--network', 'none', '--user', '0',
        '-v', f'{out}:/source:ro', '-v', f'{policy_path}:/policy', '-v', f'{pki_path}:/pki',
        image, 'sh', '-ec', script)


def gateway_answers(deadline_seconds=90):
    """The Gateway is back when /mcp answers over verified TLS (any HTTP status)."""
    end = time.time() + deadline_seconds
    while time.time() < end:
        result = subprocess.run(
            ['curl', '-s', '-m', '5', '-o', '/dev/null', '-w', '%{http_code}', '--cacert', str(GATEWAY_CA),
             '--resolve', 'localhost:443:127.0.0.1', '-X', 'POST', 'https://localhost/mcp',
             '-H', 'content-type: application/json', '-d', '{}'], capture_output=True, text=True)
        if result.stdout.strip() not in ('', '000'):
            return True
        time.sleep(2)
    return False


def restart_and_verify(since):
    run('docker', 'restart', GATEWAY)
    ok = gateway_answers()
    logs = run('docker', 'logs', '--since', since, GATEWAY, check=False).decode(errors='replace')
    problems = [line for line in logs.splitlines()
                if re.search(r'\b(ERROR|PANIC|panicked)\b', line) or re.search(r'invalid.*(policy|workflow)', line, re.I)]
    return ok, problems


def sha(data):
    return hashlib.sha256(data).hexdigest()


def rollback(directory, force=False):
    saved = Path(directory)
    previous = saved / 'gateway-policy.previous.yml'
    proposed = saved / 'gateway-policy.proposed.yml'
    if not previous.exists() or not proposed.exists():
        die(f'{saved} does not hold a saved previous and proposed policy')
    live = read_gateway_file(POLICY_DEST)
    if live != proposed.read_bytes() and not force:
        die('the live policy differs from the one this run installed, so someone changed it since. '
            'Reconcile the later edits by hand rather than overwriting them, or pass --force.')
    install(saved, previous.name)
    ok, problems = restart_and_verify(time.strftime('%Y-%m-%dT%H:%M:%S', time.gmtime()))
    print('Restored the previous policy.' + ('' if ok else ' WARNING: the Gateway did not answer after the restart.'))
    for line in problems[:5]:
        print('  log: ' + line[:200])
    sys.exit(0 if ok else 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--output', type=Path, help='new private directory for the saved and proposed files')
    parser.add_argument('--activate', action='store_true', help='install, restart the Gateway, and verify')
    parser.add_argument('--rollback', type=Path, metavar='DIR', help='restore the policy DIR saved')
    parser.add_argument('--force', action='store_true', help='with --rollback: overwrite a policy changed since')
    args = parser.parse_args()

    if args.rollback:
        rollback(args.rollback, args.force)

    previous = read_gateway_file(POLICY_DEST)
    config = parse_policy(previous)
    policy = config['policy']
    apps = policy['apps']

    if policy.get('interactiveUserOnly') is True and SERVICE not in apps:
        print('Already configured: the route admits user-token-only callers and has no CLI certificate profile.')
        return
    policy['interactiveUserOnly'] = True
    apps.pop(SERVICE, None)
    proposed = render_policy(config)

    out = args.output or (HERE / '.runtime' / ('light-cli-' + time.strftime('%Y%m%d-%H%M%S')))
    out = out.resolve()
    out.mkdir(mode=0o700, parents=True, exist_ok=False)
    private(out / 'gateway-policy.previous.yml', previous)
    private(out / 'gateway-policy.proposed.yml', proposed)
    private(out / 'manifest.json', json.dumps({
        'previousPolicySha256': sha(previous), 'proposedPolicySha256': sha(proposed),
        'interactiveUserOnly': True, 'removedProfile': SERVICE,
    }, indent=2))

    before = json.loads(previous.decode().removeprefix('authorization: '))['policy']
    print(f'Prepared in {out}')
    print(f'  interactiveUserOnly: {before.get("interactiveUserOnly", False)} -> True')
    print(f'  policy apps before : {sorted(before["apps"])}')
    print(f'  policy apps after  : {sorted(apps)}')

    if not args.activate:
        print('Nothing changed. Re-run with --activate to install, restart the Gateway and verify.')
        return

    since = time.strftime('%Y-%m-%dT%H:%M:%S', time.gmtime())
    assert read_gateway_file(POLICY_DEST) == previous, 'the policy changed while this ran; aborting'
    install(out, 'gateway-policy.proposed.yml')
    assert read_gateway_file(POLICY_DEST) == proposed, 'the installed policy does not match the proposal'
    ok, problems = restart_and_verify(since)
    if not ok or problems:
        print('The Gateway did not come back cleanly; restoring the previous policy.', file=sys.stderr)
        for line in problems[:5]:
            print('  log: ' + line[:200], file=sys.stderr)
        install(out, 'gateway-policy.previous.yml')
        restored, _ = restart_and_verify(time.strftime('%Y-%m-%dT%H:%M:%S', time.gmtime()))
        print('Previous policy restored; the Gateway ' + ('is answering.' if restored else 'is NOT answering: investigate.'),
              file=sys.stderr)
        sys.exit(1)
    print('Activated: the Gateway restarted and answers over TLS.')
    print(f'To undo: {Path(sys.argv[0]).name} --rollback {out}')


if __name__ == '__main__':
    main()

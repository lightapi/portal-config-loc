#!/usr/bin/env python3
"""Ensure an initialized local Compose installation is running, without setup."""
import importlib.util
import grp
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import time
import re
import ssl
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'all-in-lt'
PROJECT = 'all-in-lt'


def demand(ok, message):
    if not ok:
        raise ValueError(message)


def run(argv, *, env=None, input=None):
    result = subprocess.run(argv, cwd=BASE, env=env, input=input, text=True,
                            capture_output=True, timeout=180)
    demand(result.returncode == 0,
           'Local command failed (' + Path(argv[0]).name + '); check local service logs and Docker access.')
    return result.stdout.strip()


def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / (name + '.py'))
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


def containers():
    ids = run(['docker', 'ps', '-aq', '--filter', 'label=com.docker.compose.project=' + PROJECT]).split()
    demand(ids, 'Initialized all-in-lt containers are missing; restore the existing local installation.')
    items = json.loads(run(['docker', 'inspect', *ids]))
    result = {}
    for item in items:
        service = item['Config']['Labels']['com.docker.compose.service']
        demand(service not in result, 'Duplicate local service containers: ' + service + '; resolve the duplicate.')
        result[service] = item
    return result


def configuration(current):
    env = os.environ.copy()
    release = Path(env.get('RELEASE_IMAGE_ENV_FILE', str(ROOT.parent / '.release-state/docker-images.env')))
    private = Path(env.get('LIGHT_PORTAL_ENV_FILE', str(Path(env.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'lightapi/light-portal.env')))
    for path in (release, private):
        demand(path.is_file(), 'Required local environment file is missing: ' + str(path) + '; restore it.')
    readiness = current.get('w7-controller-page-readiness')
    demand(readiness, 'Completed local Controller readiness container is missing; restore the initialized installation.')
    identity = readiness['Config']['User'].split(':')
    demand(len(identity) == 2 and all(x.isdigit() for x in identity),
           'Local Controller readiness identity is unavailable; restore its existing container.')
    env.update(W7_READINESS_UID=identity[0], W7_READINESS_GID=identity[1],
               LOCAL_UID=str(os.getuid()), LOCAL_GID=str(os.getgid()),
               PORTAL_WORKSPACE_ROOT=str(ROOT.parent), IMPORT_EVENTS='false')
    # Compose's established precedence: release, then private Portal selections.
    # Remove inherited image overrides so these files select the local images.
    for key in list(env):
        if key.endswith('_IMAGE'):
            del env[key]
    cmd = shlex.split(env.get('COMPOSE_CMD', 'docker compose'))
    cmd += ['--project-name', PROJECT, '--env-file', str(release), '--env-file', str(private),
            '-f', str(BASE / 'docker-compose.yml'), '-f', str(BASE / 'docker-compose.local-fresh.yml')]
    credentials = BASE / 'light-workflow-runner-personal/.runtime/credentials.compose.yml'
    if credentials.exists():
        cmd += ['-f', str(credentials)]
    actions = BASE / 'workflow-actions/.runtime'
    if (actions / 'enabled').exists():
        env['WORKFLOW_ACTIONS_DIR'] = str(actions / 'active')
        env['WORKFLOW_ACTION_AUTHORIZATION'] = (actions / 'active/workflow/action-authorization.json').read_text()
        cmd += ['-f', str(BASE / 'workflow-actions/compose.yml')]
    config = json.loads(run(cmd + ['config', '--format', 'json'], env=env))
    demand(config['name'] == PROJECT, 'Unexpected Compose project; restore all-in-lt configuration.')
    return config, cmd, env


def ordered(services):
    result, visiting = [], set()
    def visit(name):
        demand(name not in visiting, 'Compose dependency cycle; correct local configuration.')
        if name in result:
            return
        visiting.add(name)
        for dependency in services[name].get('depends_on', {}):
            visit(dependency)
        visiting.remove(name)
        result.append(name)
    for name in services:
        visit(name)
    return result


def plan(config, current):
    services = config['services']
    order = ordered(services)
    pending = []
    oneshots = {dep for svc in services.values() for dep, rule in svc.get('depends_on', {}).items()
                if rule.get('condition') == 'service_completed_successfully'}
    for name in order:
        demand(name in current, 'Initialized service container is missing: ' + name + '; restore the existing container before startup.')
        item = current[name]
        image = services[name].get('image')
        demand(image, 'Local image selection is missing for ' + name + '; correct light-portal.env.')
        try:
            selected = run(['docker', 'image', 'inspect', image, '--format', '{{.Id}}'])
        except ValueError:
            raise ValueError('Selected local image is missing for ' + name + '; restore the locally built image selected by light-portal.env.') from None
        state = item['State']
        if name in oneshots:
            demand(state['Status'] == 'exited' and state['ExitCode'] == 0,
                   'Required initialization one-shot is incomplete: ' + name + '; inspect its logs before startup.')
            continue
        demand(name != 'postgres' or selected == item['Image'],
               'Selected PostgreSQL image differs; review database image compatibility before changing the preserved database service.')
        demand(state['Status'] in ('running', 'exited', 'created'),
               'Service ' + name + ' is in an unsafe state; inspect its logs before startup.')
        # Docker retains the final shutdown health result on stopped containers.
        # Only a running container has a current health result; start stopped
        # containers and require fresh readiness before starting dependents.
        demand(state['Status'] != 'running' or state.get('Health', {}).get('Status') != 'unhealthy',
               'Service ' + name + ' is unhealthy; inspect its logs before startup.')
        if state['Status'] != 'running' or selected != item['Image']:
            pending.append(name)
    return pending, oneshots


def wait(item):
    deadline = time.monotonic() + 180
    while True:
        state = json.loads(run(['docker', 'inspect', item['Id']]))[0]['State']
        if state['Status'] == 'running' and state.get('Health', {}).get('Status', 'healthy') == 'healthy':
            return
        demand(time.monotonic() < deadline and state['Status'] == 'running',
               'Service readiness failed: ' + item['Config']['Labels']['com.docker.compose.service'] + '; inspect its logs.')
        time.sleep(2)


def protected():
    fresh = module('check-local-fresh-start')
    state = fresh.check(BASE / 'postgres-db/operations/.runtime/w7/prepared.json')
    parser = module('local-parser-companion')
    snapshot = json.loads(fresh.sql('configserver', 'BEGIN READ ONLY;' + parser.EXPORT + 'COMMIT;'))
    inventory = parser.inventory(parser.records(snapshot))
    catalog = fresh.sql('configserver', 'BEGIN READ ONLY;' + parser.CATALOG + 'COMMIT;')
    demand(fresh.sql('postgres', "SELECT count(*) FROM pg_database WHERE datname='llm_audit';") == '1',
           'Required llm_audit database is missing; restore the completed local audit installation.')
    return state, inventory, catalog


def readiness(current):
    """Bounded TLS checks use the installation's existing public trust sources."""
    def ca(service):
        for mount in current[service]['Mounts']:
            source = Path(mount['Source'])
            if mount['Destination'] == '/config/ca.pem' and source.is_file():
                return source
            if mount['Type'] == 'bind' and source.is_dir() and (source / 'ca.pem').is_file():
                return source / 'ca.pem'
        return BASE / 'light-controller-rust/ca.pem'
    def request(url, trust, authorization=None, expected=200):
        context = ssl.create_default_context(cafile=str(trust))
        headers = {'Authorization': authorization} if authorization else {}
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}),
                                            urllib.request.HTTPSHandler(context=context))
        try:
            with opener.open(urllib.request.Request(url, headers=headers), timeout=15) as response:
                demand(response.status == expected, 'Local endpoint readiness failed; inspect service logs.')
        except Exception:
            raise ValueError('Local endpoint readiness failed: ' + url + '; inspect service logs and existing TLS configuration.') from None
    request('https://localhost:8436/ready', ca('light-workflow'))
    request('https://localhost/health', ca('light-gateway'))
    request('https://localhost:8444/health', ca('llm-gateway'))
    request('https://localhost:3000/', ROOT.parent / 'portal-view/server.pem')
    auth = (BASE / 'postgres-db/operations/.runtime/w7/controller-page-authorization').read_text().strip()
    if ':' in auth:
        auth = auth.split(':', 1)[1].strip()
    request('https://localhost:8438/internal/execution/results/page?limit=1',
            ca('controller'), auth)
    # Export public certificates only; keystore passwords never enter argv/logs.
    import yaml
    defaults = yaml.safe_load((ROOT.parent / 'light-4j/server-config/src/main/resources/config/server.yml').read_text())
    values = yaml.safe_load((BASE / 'hybrid-query/node1/values.yml').read_text())
    password = values.get('server.keystorePass', defaults['keystorePass'])
    if password.startswith('${'):
        password = password.split(':', 1)[1][:-1]
    env = os.environ.copy()
    env['LOCAL_STARTUP_CERT_PASSWORD'] = password
    pem = run(['keytool', '-list', '-rfc', '-keystore', str(BASE / 'hybrid-query/node1/server.keystore'),
               '-storepass:env', 'LOCAL_STARTUP_CERT_PASSWORD'], env=env)
    certificates = re.findall(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', pem, re.S)
    demand(certificates, 'Local Portal public trust could not be read; restore the existing keystore.')
    context = ssl.create_default_context(cadata='\n'.join(certificates))
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), urllib.request.HTTPSHandler(context=context))
    for port, service in ((8439, 'command'), (8440, 'query')):
        url = f'https://localhost:{port}/health/com.networknt.portal.hybrid.{service}-1.0.0'
        try:
            with opener.open(url, timeout=15) as response:
                demand(response.status == 200, 'Portal readiness failed; inspect service logs.')
        except Exception:
            raise ValueError('Portal ' + service + ' readiness failed; inspect service logs and existing TLS configuration.') from None
    # Retain the existing supplementary private group and normal primary GID.
    gid = int(current['w7-controller-page-readiness']['Config']['User'].split(':')[1])
    group = grp.getgrgid(gid).gr_name
    primary = grp.getgrgid(os.getgid()).gr_name
    command = shlex.join(['python3', '-B', str(ROOT / 'scripts/personal-runner-lifecycle.py'),
                         'check', str(BASE), '--timeout', '10'])
    run(['sg', group, '-c', shlex.join(['sg', primary, '-c', command])])


def ensure():
    current = containers()
    config, compose, env = configuration(current)
    pending, oneshots = plan(config, current)  # Complete preflight before starts.
    state_path = BASE / 'postgres-db/operations/.runtime/w7/prepared.json'
    demand(state_path.is_file(), 'Completed local initialization record is missing; restore ' + str(state_path) + '.')
    # Database must run to perform read-only schema checks. Never recreate it.
    if 'postgres' in pending:
        run(['docker', 'start', current['postgres']['Id']])
        wait(current['postgres'])
        pending.remove('postgres')
        print('Started existing service: postgres')
    before = protected()
    for name in pending:
        for dep in config['services'][name].get('depends_on', {}):
            if dep not in oneshots:
                wait(current[dep])
        selected = run(['docker', 'image', 'inspect', config['services'][name]['image'], '--format', '{{.Id}}'])
        if selected != current[name]['Image']:
            run(compose + ['up', '-d', '--no-deps', '--no-build', '--pull', 'never', '--force-recreate', name], env=env)
            current[name] = containers()[name]
            demand(current[name]['Image'] == selected, 'Selected image changed during startup for ' + name + '; retain state and inspect local tags.')
            print('Updated changed local image: ' + name, flush=True)
        else:
            run(['docker', 'start', current[name]['Id']])
            print('Started existing service: ' + name, flush=True)
        wait(current[name])
    for name, item in current.items():
        if name not in oneshots:
            wait(item)
    readiness(current)
    demand(protected() == before, 'Protected local data changed during startup; retain state and investigate.')
    print('LOCAL_STACK_READY: selected application images verified; successful one-shots reused; schema/ACL checks passed; four v2 gates OFF.')
    print('Unchanged services retained; no builds, pulls, replay, password changes or initialization performed.')


def control(action):
    current = containers()
    _, cmd, env = configuration(current)
    args = {'stop': ['stop', '--timeout', '30'],
            'status': ['ps', '--all'],
            'logs': ['logs', '-f', '--tail=100']}[action]
    # Inherit stdout for status/logs; never render secret-bearing config.
    # stop retains completed one-shots and initialized containers for bare lt.
    result = subprocess.run(cmd + args, cwd=BASE, env=env)
    demand(result.returncode == 0, 'Local ' + action + ' failed; check Docker access and service logs.')
    if action == 'stop':
        print('Local services stopped; initialized containers and volumes retained. Start with ./scripts/deploy-local.sh lt')


if __name__ == '__main__':
    try:
        if len(sys.argv) == 1:
            ensure()
        else:
            demand(len(sys.argv) == 2 and sys.argv[1] in ('stop', 'status', 'logs'),
                   'Use bare lt, lt stop, lt status or lt logs.')
            control(sys.argv[1])
    except (ValueError, OSError, KeyError, subprocess.SubprocessError) as error:
        message = str(error) if isinstance(error, ValueError) else 'Local prerequisites could not be read; check Docker access and existing private configuration.'
        print('LOCAL_STARTUP_REFUSED: ' + message, file=sys.stderr)
        sys.exit(2)

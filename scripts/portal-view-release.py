#!/usr/bin/env python3
"""Explicit local release command. Importing this module performs no effects."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import shlex
import ssl
import subprocess
import sys
import urllib.parse
import urllib.request

import portal_view_release as release

BASE = Path(__file__).resolve().parents[1] / 'all-in-lt'
ROOT = BASE / 'light-gateway-rust/lightapi'
CONFIG = BASE / 'light-gateway-rust/config'


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise release.ActivationError('readback redirects are refused')


def stack_module():
    spec = importlib.util.spec_from_file_location('portal_release_stack', Path(__file__).with_name('ensure-local-stack.py'))
    stack = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(stack)
    return stack


class RealRunner:
    def __init__(self, readback_url=None, stack=None, execute=None, opener_factory=None):
        self.stack = stack or stack_module()
        self.execute = execute or subprocess.run
        self.opener_factory = opener_factory or urllib.request.build_opener
        self.current = self.stack.containers()
        self.config, self.cmd, self.env = self.stack.configuration(self.current)
        self.services = [name for name in ('light-gateway', 'workflow-mcp-test-gateway') if name in self.current]
        release.require('light-gateway' in self.services, 'initialized light-gateway is missing')
        self.image = self.config.get('services', {}).get('light-gateway', {}).get('image')
        release.require(isinstance(self.image, str) and self.image, 'target gateway image is missing')
        release.require(all(name in self.config['services'] for name in self.services), 'gateway service absent from Compose configuration')
        self.recreate_command = shlex.join(self.cmd + ['up', '-d', '--no-deps', '--force-recreate', *self.services])
        port = self.env.get('LIGHT_GATEWAY_HOST_PORT', os.environ.get('LIGHT_GATEWAY_HOST_PORT', '443'))
        self.url = readback_url or 'https://local.localhost:' + port + '/'
        parsed = urllib.parse.urlsplit(self.url)
        release.require(parsed.scheme == 'https' and parsed.hostname and not parsed.username
                        and not parsed.password and not parsed.fragment, 'readback URL must be HTTPS without credentials or fragment')
        self.opener = None  # CA inspection is deferred until readback.

    def validate_offline(self, release_dir, runtime_config, key_dir, mount_path, handler_config):
        args = ['docker', 'run', '--rm', '--network', 'none', '--pull', 'never']
        mounts = [(release.directory(release_dir), '/release'),
                  (release.regular(runtime_config), '/runtime/portal-config.json'),
                  (release.directory(key_dir), '/keys')]
        if handler_config is not None:
            mounts.append((release.regular(handler_config), '/runtime/handler.yml'))
        for source, destination in mounts:
            release.require(',' not in str(source), 'comma in Docker bind source')
            args += ['--mount', 'type=bind,src=' + str(source.resolve()) + ',dst=' + destination + ',readonly']
        args += [self.image, '/app/light-gateway', 'validate-portal-release',
                 '--release-dir', '/release', '--runtime-config', '/runtime/portal-config.json',
                 '--key-dir', '/keys', '--mount-path', mount_path]
        if handler_config is not None:
            args += ['--handler-config', '/runtime/handler.yml']
        result = self.execute(args, cwd=self.stack.BASE, env=self.env, capture_output=True, text=True, timeout=180)
        try:
            report = json.loads(result.stdout)
        except (ValueError, TypeError) as error:
            raise release.ActivationError('gateway image does not support validate-portal-release or returned invalid JSON') from error
        release.require(isinstance(report, dict), 'invalid offline validation result')
        release.require(result.returncode == 0 and report.get('status') == 'ok',
                        'offline validation failed: ' + str(report.get('error', 'invalid status/exit code')))
        release.require(type(report.get('capability')) is int and report['capability'] >= 1
                        and isinstance(report.get('version'), str)
                        and isinstance(report.get('manifestDigest'), str)
                        and re.fullmatch('[0-9a-f]{64}', report['manifestDigest'])
                        and isinstance(report.get('runtimeConfigDigest'), str)
                        and re.fullmatch('[0-9a-f]{64}', report['runtimeConfigDigest']), 'incomplete offline validation result')
        return report

    def recreate_gateways(self):
        # Reuse the exact supported Compose configuration, without startup setup.
        self.stack.run(self.cmd + ['up', '-d', '--no-deps', '--force-recreate', *self.services], env=self.env)
        current = self.stack.containers()
        for name in self.services:
            release.require(name in current, 'gateway missing after recreate: ' + name)
            self.stack.wait(current[name])

    def trust(self):
        if self.opener is not None:
            return self.opener
        ca = None
        for mount in self.current['light-gateway'].get('Mounts', []):
            source = Path(mount['Source'])
            if mount['Destination'] == '/config/ca.pem' and source.is_file():
                ca = source
                break
            if mount.get('Type') == 'bind' and mount['Destination'] == '/config' and (source / 'ca.pem').is_file():
                ca = source / 'ca.pem'
                break
        fallback = self.stack.BASE / 'light-controller-rust/ca.pem'
        if ca is None and fallback.is_file():
            ca = fallback
        context = ssl.create_default_context(cafile=str(ca)) if ca else ssl.create_default_context()
        if ca is None and urllib.parse.urlsplit(self.url).hostname == 'local.localhost':
            # Plan-permitted local-only fallback; never use it for another host.
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            print('PORTAL_VIEW_RELEASE: local.localhost readback uses local-only unverified TLS (CA unavailable)', file=sys.stderr)
        self.opener = self.opener_factory(urllib.request.ProxyHandler({}), urllib.request.HTTPSHandler(context=context), NoRedirect())
        return self.opener

    def read_release_digest(self):
        try:
            with self.trust().open(urllib.request.Request(self.url, method='HEAD'), timeout=10) as response:
                release.require(response.status == 200, 'HEAD readback did not return HTTP 200')
                return response.headers.get('X-Portal-Release-Digest')
        except OSError as error:
            raise release.ActivationError('HEAD release readback failed') from error

    def gateway_healthy(self):
        try:
            with self.trust().open(urllib.request.Request(self.url, method='GET'), timeout=10) as response:
                return response.status == 200
        except OSError:
            return False


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise UsageError(message)


class UsageError(Exception):
    pass


def parser():
    cli = Parser(description='Explicit verified Portal View release lifecycle (never run by bare lt)')
    commands = cli.add_subparsers(dest='command', required=True, parser_class=Parser)
    staging = commands.add_parser('stage')
    staging.add_argument('--version', required=True)
    staging.add_argument('--from-dir', type=Path)
    for name in ('activate', 'rollback', 'recover', 'recreate'):
        command = commands.add_parser(name)
        command.add_argument('--readback-url')
        command.add_argument('--mount-path', default='/')
        command.add_argument('--handler-config', type=Path)
        if name == 'activate':
            command.add_argument('--version', required=True)
            command.add_argument('--pointer-only', action='store_true')
        if name == 'recreate':
            command.add_argument('--expect-legacy', action='store_true')
    commands.add_parser('status')
    return cli


def source_for(args, env):
    if args.from_dir is not None:
        return args.from_dir
    enclosing = env.get('LIGHT_PORTAL_VERSION')
    release.require(enclosing is not None and enclosing != '', 'remote stage requires explicit LIGHT_PORTAL_VERSION (enclosing release), separate from --version')
    release.component(enclosing)
    base = env.get('LIGHT_PORTAL_ASSET_BASE_URL', 'https://cdn.networknt.com').rstrip('/')
    parsed = urllib.parse.urlsplit(base)
    release.require(parsed.scheme == 'https' and parsed.hostname and not parsed.username
                    and not parsed.password and not parsed.query and not parsed.fragment, 'asset base must be HTTPS without credentials/query/fragment')
    return base + '/light-portal/releases/' + enclosing + '/portal-view'


def main(argv=None, runner_factory=RealRunner):
    try:
        args = parser().parse_args(argv)
        if args.command == 'status':
            print('PORTAL_VIEW_RELEASE: ' + json.dumps(release.status(ROOT), sort_keys=True))
        elif args.command == 'stage':
            release.component(args.version)
            release.stage(source_for(args, os.environ), args.version, ROOT, CONFIG / 'portal-view-release-keys')
            print('PORTAL_VIEW_RELEASE: staged ' + args.version + '; serving unchanged')
        else:
            if args.command == 'activate':
                release.component(args.version)
            real = runner_factory(args.readback_url)
            runner = release.Runner(real.validate_offline, real.recreate_gateways, real.read_release_digest, real.gateway_healthy)
            ctx = release.Context(runner, CONFIG / 'portal-config.json', CONFIG / 'portal-view-release-keys', args.mount_path, args.handler_config)
            if hasattr(real, 'recreate_command'):
                ctx.recreate_command = real.recreate_command
            if args.command == 'activate':
                release.activate(args.version, ROOT, ctx, args.pointer_only)
            elif args.command == 'rollback':
                release.rollback(ROOT, ctx)
            elif args.command == 'recover':
                release.recover(ROOT, ctx)
            else:
                release.recreate(ROOT, ctx, args.expect_legacy)
            print('PORTAL_VIEW_RELEASE: ' + args.command + ' complete')
        return 0
    except UsageError as error:
        print('PORTAL_VIEW_RELEASE: usage: ' + str(error), file=sys.stderr)
        return 1
    except release.RecoveryFailed as error:
        print('PORTAL_VIEW_RECOVERY_FAILED: ' + str(error), file=sys.stderr)
        return 3
    except (release.ActivationError, OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print('PORTAL_VIEW_ACTIVATION_REFUSED: ' + str(error), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())

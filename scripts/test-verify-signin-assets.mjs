#!/usr/bin/env node

import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { validateSigninInput } from './verify-signin-assets.mjs';

const root = mkdtempSync(join(tmpdir(), 'signin-assets-test-'));

function createBundle(name, javascript, includeStylesheet = true) {
  const bundle = join(root, name);
  mkdirSync(join(bundle, 'assets'), { recursive: true });
  writeFileSync(
    join(bundle, 'index.html'),
    `<!doctype html><script type="module" src="/assets/app.js"></script>${
      includeStylesheet ? '<link rel="stylesheet" href="/assets/app.css">' : ''
    }`,
  );
  writeFileSync(join(bundle, 'assets', 'app.js'), javascript);
  if (includeStylesheet) {
    writeFileSync(join(bundle, 'assets', 'app.css'), 'body {}');
  }
  return bundle;
}

function expectFailure(name, action, expectedMessage) {
  try {
    action();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (!message.includes(expectedMessage)) {
      throw new Error(`${name}: unexpected failure: ${message}`);
    }
    return;
  }
  throw new Error(`${name}: expected validation to fail`);
}

try {
  const valid = createBundle(
    'valid',
    'fetch(logoutUrl, { method: "POST", credentials: "include" });',
  );
  validateSigninInput(valid);

  const legacy = createBundle(
    'legacy-get',
    'fetch(logoutUrl, { credentials: "include" });',
  );
  expectFailure('legacy GET', () => validateSigninInput(legacy), 'without an explicit method');

  const noCredentialedPost = createBundle(
    'no-credentialed-post',
    'fetch(callbackUrl, { method: "GET", credentials: "include", redirect: "follow" });',
  );
  expectFailure(
    'missing credentialed POST',
    () => validateSigninInput(noCredentialedPost),
    'no explicit credentialed POST fetch was found',
  );

  const missingAsset = createBundle(
    'missing-asset',
    'fetch(logoutUrl, { method: "POST", credentials: "include" });',
    false,
  );
  writeFileSync(
    join(missingAsset, 'index.html'),
    '<script type="module" src="/assets/app.js"></script><link rel="stylesheet" href="/assets/missing.css">',
  );
  expectFailure(
    'missing asset',
    () => validateSigninInput(missingAsset),
    'referenced asset is missing',
  );

  const archive = join(root, 'signin.zip');
  const zipped = spawnSync('zip', ['-qr', archive, '.'], { cwd: valid, encoding: 'utf8' });
  if (zipped.error || zipped.status !== 0) {
    throw new Error(`create signin.zip fixture: ${zipped.error?.message ?? zipped.stderr}`);
  }
  validateSigninInput(archive);

  console.log('signin asset verifier tests passed');
} finally {
  rmSync(root, { recursive: true, force: true });
}

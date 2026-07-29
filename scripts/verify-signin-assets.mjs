#!/usr/bin/env node

import {
  existsSync,
  lstatSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  realpathSync,
  rmSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, extname, join, relative, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

function walkFiles(root, predicate) {
  const files = [];
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    const path = join(root, entry.name);
    if (entry.isDirectory()) {
      files.push(...walkFiles(path, predicate));
    } else if (entry.isFile() && predicate(path)) {
      files.push(path);
    }
  }
  return files;
}

function findIndexes(root) {
  if (lstatSync(root).isFile()) {
    if (basename(root) !== 'index.html') {
      throw new Error(`${root}: expected an index.html file, directory, or signin.zip`);
    }
    return [root];
  }

  const directIndex = join(root, 'index.html');
  if (existsSync(directIndex)) {
    return [directIndex];
  }
  return walkFiles(root, (path) => basename(path) === 'index.html');
}

function localReferences(html) {
  const references = [];
  const attribute = /(?:src|href)\s*=\s*["']([^"']+)["']/g;
  for (const match of html.matchAll(attribute)) {
    const reference = match[1].split(/[?#]/, 1)[0];
    if (
      reference &&
      !reference.startsWith('//') &&
      !reference.startsWith('data:') &&
      !reference.startsWith('http:') &&
      !reference.startsWith('https:') &&
      !reference.startsWith('#')
    ) {
      references.push(reference);
    }
  }
  return references;
}

function referencedPath(siteRoot, indexPath, reference) {
  const candidate = reference.startsWith('/')
    ? resolve(siteRoot, reference.slice(1))
    : resolve(dirname(indexPath), reference);
  const relativePath = relative(siteRoot, candidate);
  if (relativePath === '..' || relativePath.startsWith(`..${sep}`)) {
    throw new Error(`${indexPath}: local reference escapes the asset root: ${reference}`);
  }
  return candidate;
}

function validateSite(indexPath) {
  const siteRoot = dirname(indexPath);
  const html = readFileSync(indexPath, 'utf8');
  for (const reference of localReferences(html)) {
    const assetPath = referencedPath(siteRoot, indexPath, reference);
    if (!existsSync(assetPath)) {
      throw new Error(`${indexPath}: referenced asset is missing: ${reference}`);
    }
  }

  const scripts = walkFiles(siteRoot, (path) => extname(path) === '.js');
  if (scripts.length === 0) {
    throw new Error(`${siteRoot}: no JavaScript assets found`);
  }
  const javascript = scripts.map((path) => readFileSync(path, 'utf8')).join('\n');
  const compact = javascript.replace(/\s+/g, '');
  const implicitCredentialGet = /fetch\([^,]{1,500},\{credentials:(["'`])include\1\}\)/;
  if (implicitCredentialGet.test(compact)) {
    throw new Error(`${siteRoot}: found a credentialed fetch without an explicit method`);
  }

  const explicitPostThenCredentials =
    /method:(["'`])POST\1[^{}]{0,300}credentials:(["'`])include\2/;
  const explicitCredentialsThenPost =
    /credentials:(["'`])include\1[^{}]{0,300}method:(["'`])POST\2/;
  if (
    !explicitPostThenCredentials.test(compact) &&
    !explicitCredentialsThenPost.test(compact)
  ) {
    throw new Error(`${siteRoot}: no explicit credentialed POST fetch was found`);
  }

  return { siteRoot, scriptCount: scripts.length };
}

function extractArchive(archivePath) {
  const extractionRoot = mkdtempSync(join(tmpdir(), 'signin-assets-'));
  const result = spawnSync('unzip', ['-q', archivePath, '-d', extractionRoot], {
    encoding: 'utf8',
  });
  if (result.error) {
    rmSync(extractionRoot, { recursive: true, force: true });
    throw new Error(`cannot execute unzip: ${result.error.message}`);
  }
  if (result.status !== 0) {
    rmSync(extractionRoot, { recursive: true, force: true });
    throw new Error(`${archivePath}: unzip failed: ${result.stderr.trim()}`);
  }
  return extractionRoot;
}

export function validateSigninInput(input) {
  const inputPath = realpathSync(resolve(input));
  let root = inputPath;
  let extractionRoot;
  try {
    if (lstatSync(inputPath).isFile() && extname(inputPath).toLowerCase() === '.zip') {
      extractionRoot = extractArchive(inputPath);
      root = extractionRoot;
    }
    const indexes = findIndexes(root);
    if (indexes.length === 0) {
      throw new Error(`${inputPath}: no index.html found`);
    }
    return indexes.map(validateSite);
  } finally {
    if (extractionRoot) {
      rmSync(extractionRoot, { recursive: true, force: true });
    }
  }
}

function main() {
  const inputs = process.argv.slice(2);
  if (inputs.length === 0) {
    console.error(
      'Usage: node scripts/verify-signin-assets.mjs <signin.zip|signin-dist> [...]',
    );
    process.exitCode = 2;
    return;
  }

  try {
    for (const input of inputs) {
      const sites = validateSigninInput(input);
      for (const site of sites) {
        console.log(`verified signin assets: ${site.siteRoot} (${site.scriptCount} scripts)`);
      }
    }
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  main();
}

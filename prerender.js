#!/usr/bin/env node
// prerender.js — fast XSLT rendering for forester output
//
// Design:
//  1. Compile default.xsl → SEF once, caching it keyed by a hash of the XSL
//     theme files. Subsequent builds that don't touch the theme skip the 4-5s
//     compile entirely.
//  2. Run all XML→HTML transforms in a single Node.js process (SaxonJS loaded
//     once) using Promise.all, so they run concurrently.

const { execFile } = require('child_process');
const { promisify } = require('util');
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');

const exec = promisify(execFile);

const outputDir = path.resolve(process.argv[2] || process.cwd());
// Cache lives in forest/ (parent of output/), which is never cleaned by build.sh.
const cacheDir = path.join(outputDir, '..');
const CACHED_SEF  = path.join(cacheDir, '.sef-cache.json');
const CACHED_HASH = path.join(cacheDir, '.sef-cache.hash');
// XSL files that together make up the stylesheet.
const XSL_FILES = ['default.xsl', 'core.xsl', 'metadata.xsl', 'links.xsl', 'tree.xsl'];
// Local xslt3 binary installed via package.json.
const XSLT3 = path.join(__dirname, 'node_modules/.bin/xslt3');

const SaxonJS = require('saxon-js');

// --------------------------------------------------------------------------
// Compute a hash over all XSL theme files so we know when to recompile.
function themeHash() {
  const h = crypto.createHash('sha256');
  for (const f of XSL_FILES) {
    const p = path.join(outputDir, f);
    h.update(fs.existsSync(p) ? fs.readFileSync(p) : Buffer.alloc(0));
  }
  return h.digest('hex');
}

// --------------------------------------------------------------------------
// Return the SEF content (string), compiling from XSL only when necessary.
async function getSef() {
  const current = themeHash();
  const stored  = fs.existsSync(CACHED_HASH) ? fs.readFileSync(CACHED_HASH, 'utf8') : null;

  if (current === stored && fs.existsSync(CACHED_SEF)) {
    process.stdout.write('  Stylesheet unchanged — using cache.\n');
    return fs.readFileSync(CACHED_SEF, 'utf8');
  }

  process.stdout.write('  Compiling stylesheet... ');
  const t = Date.now();
  const tmp = path.join(outputDir, '.tmp-default.sef.json');
  await exec(XSLT3, ['-xsl:default.xsl', `-export:${tmp}`, '-nogo'], { cwd: outputDir });
  const sef = fs.readFileSync(tmp, 'utf8');
  fs.rmSync(tmp, { force: true });

  // Persist the cache.
  fs.writeFileSync(CACHED_SEF,  sef);
  fs.writeFileSync(CACHED_HASH, current);
  console.log(`${((Date.now() - t) / 1000).toFixed(1)}s`);
  return sef;
}

// --------------------------------------------------------------------------
async function main() {
  const dirs = fs.readdirSync(outputDir, { withFileTypes: true })
    .filter(e => e.isDirectory() && fs.existsSync(path.join(outputDir, e.name, 'index.xml')))
    .map(e => e.name);

  if (dirs.length === 0) return;

  const sef = await getSef();

  // Write SEF to a temp file so SaxonJS can load it by path.
  const sefPath = path.join(outputDir, '.active-default.sef.json');
  fs.writeFileSync(sefPath, sef);

  process.stdout.write(`  Transforming ${dirs.length} pages... `);
  const t = Date.now();
  try {
    await Promise.all(dirs.map(dir =>
      SaxonJS.transform({
        stylesheetFileName: sefPath,
        sourceFileName: path.join(outputDir, dir, 'index.xml'),
        destination: 'serialized',
      }, 'async').then(result =>
        fs.promises.writeFile(path.join(outputDir, dir, 'index.html'), result.principalResult)
      )
    ));
  } finally {
    fs.rmSync(sefPath, { force: true });
  }
  console.log(`${((Date.now() - t) / 1000).toFixed(1)}s`);
}

main().catch(err => { console.error(err.message || err); process.exit(1); });

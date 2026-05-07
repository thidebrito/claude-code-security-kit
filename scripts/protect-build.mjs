#!/usr/bin/env node
/**
 * protect-build.mjs — Pipeline de proteção de autoria
 *
 * Aplica em ordem:
 *   1. Gera UUID v4 da build
 *   2. Calcula SHA-256 de cada arquivo do dist/
 *   3. Injeta watermarks invisíveis em HTML/CSS/JS
 *   4. Gera protection-manifest.json
 *   5. Roda OpenTimestamps (stamp) — opcional via flag
 *   6. Salva .ots no repo SECURITY
 *
 * Uso:
 *   node protect-build.mjs <projeto-path>
 *   node protect-build.mjs <projeto-path> --dry-run
 *   node protect-build.mjs <projeto-path> --skip-timestamp
 *   node protect-build.mjs <projeto-path> --dist-dir build  # default: dist
 */

import { readFile, writeFile, readdir, stat, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, basename, relative, dirname, extname } from 'node:path';
import { createHash, randomUUID } from 'node:crypto';
import { execSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const SECURITY_REPO = join(__dirname, '..');

// ─── Args parsing ─────────────────────────────────────
const args = process.argv.slice(2);
let projectPath = null;
let distDir = 'dist';
let dryRun = false;
let skipTimestamp = false;
let verbose = false;

for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === '--dry-run') dryRun = true;
  else if (a === '--skip-timestamp') skipTimestamp = true;
  else if (a === '--verbose' || a === '-v') verbose = true;
  else if (a === '--dist-dir') { distDir = args[++i]; }
  else if (!a.startsWith('--')) projectPath = a;
}

if (!projectPath) {
  console.error('Uso: node protect-build.mjs <projeto-path> [--dry-run] [--skip-timestamp] [--dist-dir dist]');
  process.exit(2);
}

// ─── Validate project path ────────────────────────────
projectPath = projectPath.replace('~', process.env.HOME);
if (!existsSync(projectPath)) {
  console.error(`❌ Projeto não existe: ${projectPath}`);
  process.exit(2);
}

const projectName = basename(projectPath);

// Detect dist dir
const possibleDirs = [distDir, 'dist', 'build', 'out', '.next/static'];
let actualDistDir = null;
for (const d of possibleDirs) {
  const p = join(projectPath, d);
  if (existsSync(p)) {
    actualDistDir = p;
    break;
  }
}

// Se não tem dist, usar a raiz do projeto (caso de HTML puro standalone)
if (!actualDistDir) {
  // Ver se tem index.html na raiz
  if (existsSync(join(projectPath, 'index.html'))) {
    actualDistDir = projectPath;
    console.log('ℹ️  Sem dist/, processando raiz do projeto (HTML puro)');
  } else {
    console.error(`❌ Nenhum dist/, build/, out/ ou index.html na raiz encontrado em ${projectPath}`);
    console.error('   Rode "npm run build" antes ou passe --dist-dir <pasta>');
    process.exit(2);
  }
}

// ─── 1. Gerar UUID ────────────────────────────────────
const buildUuid = randomUUID();
const buildIso = new Date().toISOString();
const buildTimestamp = buildIso.replace(/[:.]/g, '-').replace('T', '_').slice(0, 17);
const uuidShort = buildUuid.slice(0, 8);

console.log('');
console.log('🛡️  protect-build.mjs');
console.log(`   Projeto:   ${projectName}`);
console.log(`   Path:      ${projectPath}`);
console.log(`   Dist:      ${actualDistDir}`);
console.log(`   Build UUID: ${buildUuid}`);
console.log(`   Build at:   ${buildIso}`);
console.log(`   Dry-run:    ${dryRun ? 'SIM' : 'não'}`);
console.log('');

// ─── 2. Listar arquivos do dist ───────────────────────
async function walkDir(dir, baseDir = dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (entry.name.startsWith('.')) continue;  // pular .DS_Store, .git, etc.
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      // Pular node_modules e similares
      if (['node_modules', '.git', 'reports', 'timestamps', '.security-cache'].includes(entry.name)) continue;
      files.push(...await walkDir(full, baseDir));
    } else {
      files.push({ full, rel: relative(baseDir, full) });
    }
  }
  return files;
}

console.log('🔎 Mapeando arquivos do build...');
const allFiles = await walkDir(actualDistDir);
console.log(`   ${allFiles.length} arquivos encontrados`);

// ─── 3. Aplicar watermarks ────────────────────────────
const CANONICAL_SOURCE = 'yourdomain.com';
const AUTHOR_NAME = 'Your Name';
const watermarkData = `${AUTHOR_NAME}|${buildIso}|${buildUuid}`;
const watermarkB64 = Buffer.from(watermarkData, 'utf8').toString('base64');

const HTML_META = `
  <!-- TDB-AUTHENTICITY: ${createHash('sha256').update(watermarkData).digest('hex').slice(0, 32)} -->
  <meta name="x-author" content="${AUTHOR_NAME}">
  <meta name="x-author-id" content="${buildUuid}">
  <meta name="x-built-at" content="${buildIso}">
  <meta name="x-canonical-source" content="${CANONICAL_SOURCE}">`;

const JS_INJECT = `\n;(function(){try{window.__TDB__=atob("${watermarkB64}");}catch(e){}})();`;

const CSS_INJECT = `/* © ${AUTHOR_NAME} · ${buildIso.slice(0, 10)} · uuid:${uuidShort} · ${CANONICAL_SOURCE} */\n`;

let modifiedHtml = 0, modifiedJs = 0, modifiedCss = 0;

for (const f of allFiles) {
  const ext = extname(f.full).toLowerCase();

  if (ext === '.html') {
    const content = await readFile(f.full, 'utf8');
    // Inserir após <head> (case-insensitive, primeira ocorrência)
    if (/<head[^>]*>/i.test(content) && !content.includes('x-author-id')) {
      const newContent = content.replace(/<head[^>]*>/i, (m) => m + HTML_META);
      if (!dryRun) await writeFile(f.full, newContent, 'utf8');
      modifiedHtml++;
      if (verbose) console.log(`   ✓ HTML watermarked: ${f.rel}`);
    }
  } else if (ext === '.js' || ext === '.mjs') {
    const content = await readFile(f.full, 'utf8');
    if (!content.includes('window.__TDB__')) {
      const newContent = content + JS_INJECT;
      if (!dryRun) await writeFile(f.full, newContent, 'utf8');
      modifiedJs++;
      if (verbose) console.log(`   ✓ JS watermarked: ${f.rel}`);
    }
  } else if (ext === '.css') {
    const content = await readFile(f.full, 'utf8');
    if (!content.startsWith('/*') || !content.includes(AUTHOR_NAME)) {
      const newContent = CSS_INJECT + content;
      if (!dryRun) await writeFile(f.full, newContent, 'utf8');
      modifiedCss++;
      if (verbose) console.log(`   ✓ CSS watermarked: ${f.rel}`);
    }
  }
}

console.log(`💧 Watermarks injetados: ${modifiedHtml} HTML, ${modifiedJs} JS, ${modifiedCss} CSS`);

// ─── 4. Calcular hashes SHA-256 ────────────────────────
console.log('🔐 Calculando SHA-256 de cada arquivo...');
const filesManifest = [];
let totalBytes = 0;

for (const f of allFiles) {
  const content = await readFile(f.full);
  const sha = createHash('sha256').update(content).digest('hex');
  filesManifest.push({
    path: f.rel,
    bytes: content.length,
    sha256: sha,
  });
  totalBytes += content.length;
}

// Hash agregado: hash de todos os hashes ordenados por path
const sortedManifest = [...filesManifest].sort((a, b) => a.path.localeCompare(b.path));
const aggregateHash = createHash('sha256')
  .update(sortedManifest.map(f => `${f.path}:${f.sha256}`).join('\n'))
  .digest('hex');

console.log(`   ${filesManifest.length} arquivos hasheados (${(totalBytes / 1024).toFixed(1)} KB total)`);
console.log(`   Aggregate SHA-256: ${aggregateHash}`);

// ─── 5. Gerar protection-manifest.json ─────────────────
const manifest = {
  schema: 'thidebrito-security/protection-manifest/1.0.0',
  project: projectName,
  build_uuid: buildUuid,
  built_at: buildIso,
  author: AUTHOR_NAME,
  canonical_source: CANONICAL_SOURCE,
  files_count: filesManifest.length,
  files_total_bytes: totalBytes,
  aggregate_sha256: aggregateHash,
  watermarks: {
    html_meta: modifiedHtml > 0,
    js_base64: modifiedJs > 0,
    css_comment: modifiedCss > 0,
  },
  files: sortedManifest,
};

const manifestPath = join(actualDistDir, 'protection-manifest.json');
if (!dryRun) {
  await writeFile(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
}
console.log(`📜 Manifest gerado: ${manifestPath}`);

// ─── 6. OpenTimestamps ─────────────────────────────────
let otsPath = null;
if (!skipTimestamp && !dryRun) {
  console.log('⏱️  Aplicando OpenTimestamps (pode levar ~10s)...');
  const timestampsDir = join(SECURITY_REPO, 'timestamps', projectName);
  await mkdir(timestampsDir, { recursive: true });

  const otsTarget = join(timestampsDir, `${buildTimestamp}_${uuidShort}.json`);

  // Copiar manifest pra timestamps dir (vamos carimbar lá)
  await writeFile(otsTarget, JSON.stringify(manifest, null, 2), 'utf8');

  // Stamp via npx opentimestamps
  const result = spawnSync('npx', ['--yes', 'opentimestamps', 'stamp', otsTarget], {
    cwd: SECURITY_REPO,
    stdio: 'pipe',
    encoding: 'utf8',
  });

  if (result.status === 0) {
    otsPath = `${otsTarget}.ots`;
    console.log(`✅ OpenTimestamps stamp criado: ${otsPath}`);
    console.log('   ℹ️  Aguardar ~3-6h e rodar `npx opentimestamps upgrade <arquivo.ots>`');
    console.log('      pra confirmar a ancoragem no Bitcoin.');
  } else {
    console.warn('⚠️  OpenTimestamps stamp falhou (continuando sem timestamp):');
    console.warn(result.stderr || result.stdout);
  }
} else if (skipTimestamp) {
  console.log('⏭  --skip-timestamp ativo, pulando OpenTimestamps');
}

// ─── 7. Atualizar manifest com path do .ots ────────────
if (otsPath && !dryRun) {
  manifest.ots_proof = relative(SECURITY_REPO, otsPath);
  await writeFile(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
}

// ─── Resumo final ─────────────────────────────────────
console.log('');
console.log('═══════════════════════════════════════════════════════');
console.log(`✅ Proteção aplicada em ${projectName}`);
console.log('');
console.log(`   Build UUID:      ${buildUuid}`);
console.log(`   Aggregate SHA:   ${aggregateHash.slice(0, 16)}...`);
console.log(`   Manifest:        ${relative(projectPath, manifestPath)}`);
if (otsPath) console.log(`   Timestamp:       ${relative(SECURITY_REPO, otsPath)}`);
console.log(`   Watermarks:      ${modifiedHtml + modifiedJs + modifiedCss} arquivos`);
console.log(`   Files protected: ${filesManifest.length} (${(totalBytes / 1024).toFixed(1)} KB)`);
if (dryRun) {
  console.log('');
  console.log('   ⚠️  DRY-RUN: nenhum arquivo foi modificado');
}
console.log('═══════════════════════════════════════════════════════');
console.log('');
console.log('Próximo passo:');
console.log(`   cd ${projectPath} && vercel deploy --prod`);
console.log('');

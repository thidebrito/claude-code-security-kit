/**
 * vite-plugin-tdb-protect.mjs — Plugin Vite que roda protect-build no closeBundle
 *
 * Uso em vite.config.ts:
 *
 *   import tdbProtect from '$HOME/PROJETOS/claude-code-security-kit/scripts/vite-plugin-tdb-protect.mjs';
 *
 *   export default defineConfig({
 *     plugins: [
 *       react(),
 *       tdbProtect({ enabled: process.env.NODE_ENV === 'production' })
 *     ]
 *   });
 *
 * Opções:
 *   - enabled: boolean (default: NODE_ENV === 'production')
 *   - skipTimestamp: boolean (default: false) — útil em CI sem rede
 *   - distDir: string (default: 'dist')
 */

import { spawnSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PROTECT_SCRIPT = join(__dirname, 'protect-build.mjs');

export default function tdbProtect(options = {}) {
  const {
    enabled = process.env.NODE_ENV === 'production',
    skipTimestamp = false,
    distDir = 'dist',
    verbose = false,
  } = options;

  return {
    name: 'tdb-protect',
    apply: 'build',  // só roda no `vite build`
    closeBundle: {
      sequential: true,
      order: 'post',
      handler() {
        if (!enabled) {
          console.log('[tdb-protect] disabled (set enabled: true em vite.config)');
          return;
        }

        const projectPath = resolve(process.cwd());
        console.log(`\n[tdb-protect] Aplicando proteção em ${projectPath}`);

        const args = [PROTECT_SCRIPT, projectPath, '--dist-dir', distDir];
        if (skipTimestamp) args.push('--skip-timestamp');
        if (verbose) args.push('--verbose');

        const result = spawnSync('node', args, {
          stdio: 'inherit',
          cwd: projectPath,
        });

        if (result.status !== 0) {
          // Não falha o build — só avisa
          console.warn('[tdb-protect] Falhou (exit ' + result.status + ') — build continua sem proteção');
        }
      },
    },
  };
}

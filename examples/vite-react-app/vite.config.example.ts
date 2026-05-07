/**
 * Example vite.config.ts with Claude Code Security Kit integration
 *
 * Adapt the import path to where you cloned the kit.
 */

import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Replace with your actual path:
import tdbProtect from '/Users/<your-user>/PROJETOS/claude-code-security-kit/scripts/vite-plugin-tdb-protect.mjs';

export default defineConfig({
  plugins: [
    react(),
    tdbProtect({
      enabled: process.env.NODE_ENV === 'production',
      skipTimestamp: false,
      distDir: 'dist',
      verbose: false,
    }),
  ],

  // Your normal config below
  build: {
    outDir: 'dist',
    sourcemap: false,  // recommend false in prod (less surface for IP theft)
  },
});

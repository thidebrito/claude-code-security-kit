# Vite + React Example

How to integrate Claude Code Security Kit in a Vite + React project.

## Setup

In your `vite.config.ts`:

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tdbProtect from '~/PROJETOS/claude-code-security-kit/scripts/vite-plugin-tdb-protect.mjs';

export default defineConfig({
  plugins: [
    react(),
    tdbProtect({
      enabled: process.env.NODE_ENV === 'production',
      skipTimestamp: false,  // set to true in CI to skip OpenTimestamps call
      distDir: 'dist',
      verbose: false,
    }),
  ],
});
```

## How it works

The plugin runs in Vite's `closeBundle` hook (after `vite build` completes), so:

1. Your build runs as normal → outputs to `dist/`
2. Plugin kicks in → applies Layer C to `dist/`
3. Watermarks injected, manifest generated, OpenTimestamps stamped
4. `vite build` exits cleanly

In **dev mode** (`vite dev`), the plugin is bypassed automatically — no impact on hot reload.

## Custom configuration

```typescript
tdbProtect({
  enabled: true,           // force enable (default: NODE_ENV === 'production')
  skipTimestamp: true,     // skip OpenTimestamps (faster, useful in CI)
  distDir: 'build',        // override dist folder name
  verbose: true,           // show every file processed
})
```

## CI/CD considerations

In your GitHub Actions / CI pipeline:

```yaml
- name: Build
  env:
    NODE_ENV: production
  run: npm run build  # plugin runs automatically

- name: Upgrade timestamps after deploy
  run: |
    sleep 6h
    npx opentimestamps upgrade ~/PROJETOS/claude-code-security-kit/timestamps/<project>/*.ots
```

## Disabling for specific builds

```bash
# Disable plugin for one build:
NODE_ENV=development npm run build
```

Or pass `enabled: false` and toggle via env var.

## Combining with package.json

Recommended `scripts` in your project:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "build:protected": "NODE_ENV=production vite build",
    "deploy": "npm run build:protected && vercel --prod"
  }
}
```

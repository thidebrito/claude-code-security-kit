# Examples

Reference projects showing how to integrate Claude Code Security Kit in different stacks.

| Example | Stack | What it demonstrates |
|---|---|---|
| [`plain-html-lp/`](plain-html-lp/) | Plain HTML/CSS/JS | Layer C (`protect-build`) on a static landing page, no build step |
| [`vite-react-app/`](vite-react-app/) | Vite + React | Layer C via `vite-plugin-tdb-protect` (auto on `vite build`) |

## Run an example

```bash
cd examples/plain-html-lp

# Apply Layer C protection
node ../../scripts/protect-build.mjs . --skip-timestamp

# Inspect the watermarked HTML
grep "x-author" index.html
cat protection-manifest.json
```

## Integration in your own project

Copy the relevant config from an example and adapt:
- `vercel.json` → for Vercel deploy with pre-deploy hook
- `vite.config.ts` → for Vite plugin integration
- `package.json` scripts → for local dev workflow

## Want to add an example?

PRs welcome! Good examples to add:
- Next.js app
- Astro site
- Node.js Express API
- Python FastAPI
- Go web server

See [CONTRIBUTING.md](../CONTRIBUTING.md).

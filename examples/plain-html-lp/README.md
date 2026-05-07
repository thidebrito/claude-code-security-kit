# Plain HTML Landing Page Example

Minimal HTML/CSS/JS landing page demonstrating Layer C (authorship proof).

## Files
- `index.html` — entry point
- `styles.css` — basic dark theme
- `app.js` — demo CTA handler

## Apply Layer C protection

```bash
# From kit root:
node scripts/protect-build.mjs examples/plain-html-lp --skip-timestamp

# Or from this folder:
node ../../scripts/protect-build.mjs . --skip-timestamp
```

After running, you'll see:

### In `index.html` `<head>`:
```html
<!-- TDB-AUTHENTICITY: ... -->
<meta name="x-author" content="Your Name">
<meta name="x-author-id" content="<UUID>">
<meta name="x-built-at" content="2026-...">
<meta name="x-canonical-source" content="yourdomain.com">
```

### In `app.js`:
```js
;(function(){try{window.__TDB__=atob("...");}catch(e){}})();
```

### In `styles.css` (prepended):
```css
/* © Your Name · 2026-... · uuid:... · yourdomain.com */
```

### New file: `protection-manifest.json`
```json
{
  "schema": "thidebrito-security/protection-manifest/1.0.0",
  "build_uuid": "...",
  "files_count": 3,
  "aggregate_sha256": "...",
  ...
}
```

## With Vercel auto-deploy

Add to your `vercel.json`:
```json
{
  "buildCommand": "bash $HOME/PROJETOS/claude-code-security-kit/scripts/pre-deploy.sh"
}
```

Now every Vercel deploy automatically runs Layer C protection.

## Verify the timestamp later

After 6 hours (Bitcoin confirmation):
```bash
npx opentimestamps verify protection-manifest.json
# Should show: Bitcoin block #N attests existence
```

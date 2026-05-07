# FAQ — Extended

For shorter answers, see the [README FAQ section](../README.md#-faq).

## Setup & Installation

### Q: Does this work with Cursor / Copilot Workspace / other AI agents?
A: Layer A (hooks) is built for **Claude Code's** `~/.claude/settings.json` hook system specifically. Layers B and C are tool-agnostic.

PRs welcome to add adapters for other agents — see [CONTRIBUTING.md](../CONTRIBUTING.md).

### Q: Can I install just one layer?
A: Yes. Each layer is independent.
- **Layer B only:** copy `templates/` and `scripts/`, ignore `claude-code-bundle/`
- **Layer C only:** use `scripts/protect-build.mjs` directly, no install
- **Layer A:** requires `install.sh` (configures Claude Code)

### Q: Can I install in a different folder than `~/PROJETOS/claude-code-security-kit`?
A: Yes, but you'll need to update paths in scripts. Easier to use the default path.

---

## Daily usage

### Q: How do I know if a hook blocked something?
A: You'll see stderr output like:
```
❌ BLOQUEIO: ...
```
The git command will exit with non-zero status. Claude Code (or your terminal) shows the message.

### Q: How often should I run `audit-projects.sh`?
A: Recommendations:
- **Weekly:** for active development
- **Monthly:** for maintenance mode
- **After major changes:** when you add/remove projects from your ecosystem

The `security-session-start` hook does a *light* health-check on every session, so you don't need full audits constantly.

### Q: Can I disable hooks for a specific project (not globally)?
A: Currently no — hooks are global to Claude Code. Workaround: use `SKIP_HOOKS=1` env var when working on that project.

PRs welcome to support per-project `.security-config.json`.

---

## Layer C — Authorship Proof

### Q: How is `OpenTimestamps` different from just publishing the SHA-256 somewhere?
A: OpenTimestamps:
1. Aggregates your hash with thousands of others into a Merkle tree
2. Submits the root to Bitcoin blockchain (immutable, decentralized)
3. After ~3-6h, your hash is "anchored" to a Bitcoin block — verifiable forever

**Just a public SHA-256:** anyone can backdate it, you control it.
**OpenTimestamps:** independent third-party (Bitcoin) confirms when the hash existed.

### Q: Has OpenTimestamps been accepted as evidence in court?
A: Yes — there are public cases in the US, EU, and Brazil. It's based on standard cryptographic primitives (SHA-256 + blockchain). Disclaimer: I'm not a lawyer; consult one if you need to use it formally.

### Q: What if OpenTimestamps servers go down?
A: There are 4+ public calendar servers. The kit can be configured to use any combination. Even if all go down, your `.ots` file already contains the proof — you just can't get *new* timestamps until they recover.

### Q: Why not GPG signing?
A: Because it requires:
1. Generating a GPG key (5 min)
2. Uploading public key to keyserver (5 min)
3. Securely backing up private key (1Password, paper, etc.)
4. Re-signing on every key rotation
5. Other parties having to verify signatures (most won't)

OpenTimestamps gives 90% of the legal value with 0% of the setup overhead. Adding GPG support is on the roadmap as opt-in.

### Q: Will watermarks affect my LP's SEO or page speed?
A: Negligibly:
- 5 meta tags add ~200 bytes to HTML head
- JS injection adds ~100 bytes per .js file
- CSS comments add ~70 bytes per .css file
- Total: <500 bytes per page (sub-millisecond impact)

Search engines ignore custom meta tags they don't understand.

---

## Privacy & Security

### Q: Does this kit phone home / send data anywhere?
A: **No.** Everything runs locally:
- gitleaks runs locally with `--redact` (secrets never leave your machine)
- pii-scan is regex-based, no API calls
- OpenTimestamps sends only the SHA-256 hash (never the original content) to a public calendar server, then the Bitcoin network

No telemetry. No accounts. No tracking.

### Q: What happens to scan results / reports?
A: Stored locally in `reports/` and `reports/details/`. The `.gitignore` covers them — they never get committed.

### Q: Can someone read my `.security-applied` marker and learn things about me?
A: The marker contains:
- Date applied
- Author handle (from template)
- Templates used
- Schema version

No secrets. It's metadata, designed to be safe to commit publicly.

---

## Troubleshooting

### Q: Hook is too aggressive — false positives
A: Two options:
1. **Adjust the hook** — edit `~/.claude/scripts/<hook>.sh` and customize regex/allowlists
2. **Bypass for the moment** — `SKIP_HOOKS=1 git commit ...` and open an issue with the false positive

### Q: `protect-build.mjs` says "OpenTimestamps stamp falhou"
A: Common causes:
- No internet
- `calendar.opentimestamps.org` temporarily down (rare, retry in 5 min)
- Old `opentimestamps` package: `npm install -g opentimestamps@latest`
- Blocked by corporate firewall (try a different network)

The build still completes with watermarks + manifest — you just don't get the blockchain anchor for now. Run `npx opentimestamps stamp <manifest.json>` later to add it.

### Q: I rebuilt my project and watermarks were stripped
A: This happens if the build step **regenerates** HTML/JS from sources. The fix:
- Run `protect-build` AFTER your build (not before)
- Or use the Vite plugin which runs in `closeBundle` (after Vite finishes)

### Q: My CI/CD pipeline keeps failing because of the gitleaks workflow
A: The workflow scans the entire history. If you have legitimate strings that look like secrets, add them to `.gitleaksignore`. See [HOOKS.md](HOOKS.md) for fingerprint format.

---

## Project & community

### Q: Who maintains this?
A: Initially built by [@thidebrito](https://github.com/thidebrito) for personal use, then open-sourced. PRs reviewed regularly.

### Q: How do I sponsor / support?
A: Star the repo. Tell others. PR improvements. Currently no monetary sponsorship setup (see `.github/FUNDING.yml` if interested in setting one up).

### Q: Where do I report security issues?
A: See [SECURITY.md](../SECURITY.md). **Don't** open public issues for vulnerabilities.

### Q: Where do I ask questions?
A: [GitHub Discussions](../../discussions) (preferred) or `[QUESTION]` issue.

### Q: Is there a Discord / Slack?
A: Not yet. If you want to start one, open a discussion!

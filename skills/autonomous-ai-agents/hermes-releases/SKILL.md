---
name: hermes-releases
description: "Identify, verify, and summarize Hermes Agent releases when users mention vague marketing names like 'Hermes 2.0' or 'Hermes Bot'."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, releases, versions, upgrade, changelog]
    related_skills: [hermes-agent]
---

# Hermes Releases

Users often ask about Hermes using informal or marketing names ('Hermes 2.0', 'Hermes Bot', 'the new Hermes', 'last week's release') rather than official version numbers. This skill governs how to map those names to actual tags/versions, verify the local install state, and produce an accurate summary with a safe upgrade path.

## When to use

- User asks about a Hermes release by approximate date or nickname.
- User asks 'what do I need to know about X?', 'what does that mean for you?', or 'how do I upgrade?' for a Hermes version.
- User references a YouTube/video/blog post about a recent Hermes release.
- Before recommending `hermes update`, you need to know the current local version.

## Verification steps

1. **Check the local install version and update availability.**
   ```bash
   hermes --version
   hermes update --check   # or hermes update if supported
   ```
   This returns the running version, install directory, install method, and whether an update is available.

2. **List actual release tags.**
   In the Hermes source directory (usually `~/.hermes/hermes-agent`):
   ```bash
   git tag --sort=-creatordate | head -20
   ```
   Date-stamped tags like `v2026.8.3` are the canonical release identifiers. The version number is separate (e.g., `v0.20.0`).

3. **Find the release commit and notes on GitHub.**
   Navigate to:
   ```
   https://github.com/NousResearch/hermes-agent/releases/tag/<tag>
   ```
   e.g., `https://github.com/NousResearch/hermes-agent/releases/tag/v2026.8.3`
   The release page contains the authoritative highlight summary, PR links, and breaking-change notes.

4. **Inspect the delta if the user wants technical depth.**
   ```bash
   git log --oneline <old-tag>..<new-tag> | wc -l
   git diff --stat <old-tag>..<new-tag>
   git log --oneline <old-tag>..<new-tag> --grep="<keyword>"
   ```
   Useful for confirming which subsystems changed (voice, gateway, desktop, tools, compression, etc.).

5. **Cross-check the docs site.**
   The live docs at `https://hermes-agent.nousresearch.com/docs/` may lag the release notes. Prefer the GitHub release page for the newest release; use docs for stable setup/config commands.

## Pitfalls

- **Don't assume a nickname maps to a specific version.** 'Hermes 2.0' and 'Hermes Bot' are not official version strings — verify against the latest tag.
- **Don't recommend `hermes update` blindly.** It restarts the gateway and kills running agents. State this explicitly and suggest a maintenance window.
- **Don't claim capabilities for the running instance before checking `hermes --version`.** The local install may be one or more releases behind.
- **Don't rely solely on the docs site for brand-new features.** GitHub releases are fresher.
- **Don't treat PyPI install vs git install identically.** `hermes update` behavior depends on install method (git pull vs pip install).

## Response template

When the user asks about a recent Hermes release, structure the answer as:

1. **What it actually is** — map nickname to official version + tag + release date.
2. **What changed** — 3-5 headline capability areas (voice, A2A, webhooks, desktop, tools, compression, etc.).
3. **What it means for this instance** — state the running version and whether it already has those capabilities.
4. **Upgrade/replacement pathway** — `hermes update`, backup advice, restart warning, optional profile-based test.

## Upgrade pathway

### Standard in-place upgrade

```bash
# 1. Verify current state
hermes --version
hermes doctor

# 2. Back up critical state (config, sessions, memory, skills)
# ~/.hermes/config.yaml, ~/.hermes/.env, ~/.hermes/state.db, ~/.hermes/skills/, ~/.hermes/sessions/

# 3. Update
hermes update

# 4. Restart gateway if it did not auto-restart
hermes gateway restart
```

### Safer test-first upgrade

Create an isolated profile, update only that profile, and validate:

```bash
hermes profile create v20-test
hermes profile use v20-test
hermes update
hermes --version
```

This keeps the default profile untouched while you verify new capabilities.

## References

- `references/hermes-v0.20.0-herald-release.md` — verified summary of the v0.20.0 / v2026.8.3 "Herald Release".

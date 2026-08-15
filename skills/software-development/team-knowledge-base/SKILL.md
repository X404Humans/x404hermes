---
name: team-knowledge-base
description: "Set up and operate a VPS-local, GitHub-synced knowledge base for a team and its agents."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [knowledge-base, wiki, team-sync, github, cron, local-first, meetings]
    category: software-development
    related_skills: [llm-wiki, obsidian, github-auth, github-repo-management]
---

# Team Knowledge Base on a Shared VPS

A local-first, Git-backed knowledge store that lives on a shared VPS (e.g., `/data/knowledge`) and is bidirectionally synced with a GitHub repo so human team members and agents can all read and write it.

This pattern is distinct from Karpathy's LLM Wiki (`llm-wiki` skill) and from Obsidian vaults. It is optimized for:
- A small team sharing a single VPS user account (`computer`)
- Files as the source of truth (`.md`, `.txt`, `.csv`, `.pdf`)
- GitHub as the sync/transport layer, not the primary editor
- Agents ingesting meeting notes, requirements, and generated outputs

## When This Skill Activates

Use this skill when the user:
- Wants a shared place on the VPS for documents Hermes should read
- Asks how to sync files from their laptop/Google Drive to the VPS
- Wants meeting notes, requirements, or governance docs to land where agents can see them
- Is confused about `/data/files` vs `/data/knowledge/sources/uploads`
- Wants a cron job to pull/push a knowledge repo with GitHub
- Asks about backing up the Hermes runtime vs. backing up team knowledge

## Canonical Layout

```
/data/knowledge/                 # team knowledge root (git repo)
  KNOWLEDGE.md                  # rules for the knowledge base
  about-me.md                   # group/orientation doc
  sources/                      # raw, immutable inputs
    meeting notes/              # exported meeting transcripts
    requirements/               # requirements docs
    governance/               # principles, roles, agreements
    alignment/                # goals/objectives/mission drafts
    uploads/                  # one-off files dropped for context
  wiki/                         # synthesized, agent-maintained pages
    index.md
    log.md
    contradictions.md
  outputs/                      # artifacts generated from the wiki
```

**Rule:** Treat `sources/` as read-only evidence after ingest. Synthesis and updates belong in `wiki/` or `outputs/`.

### `/data/files` vs `/data/knowledge/sources/uploads`

| Path | Use it for |
|---|---|
| `/data/files` | Transient attachments, screenshots, raw dumps from the Computer file system. |
| `/data/knowledge/sources/uploads/` | Documents that should become long-term, citable context for the team and agents. |

Move or copy from `/data/files` into the appropriate `sources/` subfolder once the file is approved as team knowledge.

## Setting Up GitHub Sync

### 1. Use a machine-user GitHub account

Do **not** use a team member's personal account for automation. Create a dedicated machine user (e.g., `x404-hermes`) with a team-controlled email. Generate a fine-grained PAT scoped to:
- Repository permissions → Contents: Read and write
- Repository permissions → Metadata: Read

See `github-auth` skill for machine-user setup details.

Store the token in the active Hermes runtime `.env`:

```bash
# /data/runtime/hermes-rw/.env
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

### 2. Connect the local repo to GitHub

```bash
cd /data/knowledge

git remote add origin https://github.com/<org>/<repo>.git

# Configure the machine-user identity
git config user.name "x404-hermes"
git config user.email "x404@agentmail.to"

# Test auth
git ls-remote origin
```

If the repo already exists on GitHub with content, pull it first:

```bash
git pull origin main --rebase
```

If the local directory has files that are not on GitHub, add and push them:

```bash
git add -A
git commit -m "initial: seed knowledge base"
git push -u origin main
```

### 3. Add the cron sync job

Use `templates/knowledge-sync.sh` from this skill as the starting point. Copy it, customize the remote/branch, and schedule it via Hermes `cronjob` or system cron.

Recommended schedule:
- `*/5 * * * *` for pull (fast, idempotent)
- Separate push job or push inside the same script when local changes are detected

### 4. Keep runtime backup separate

| What | Where to back it up |
|---|---|
| Team knowledge (`/data/knowledge`) | Synced GitHub repo (shared, non-secret). |
| Hermes runtime (`/data/runtime/hermes-rw`) | Private, encrypted backup. Contains `auth.json`, `.env`, sessions, memories, skills, cron jobs. |

**Never** commit runtime secrets to the knowledge repo.

## Meeting Notes Ingestion Funnel

Goal: multiple notetakers → one canonical folder → agent can read it.

```
Fathom / Granola / other notetaker
        ↓
   export to GitHub knowledge repo
   (or webhook → email → parser on VPS)
        ↓
  /data/knowledge/sources/meeting notes/YYYY-MM-DD-title.md
        ↓
  cron pulls to VPS
        ↓
  agent reads, extracts action items/decisions
```

**Redundancy:** configure at least two notetakers to land in the same folder. For example:
- Primary: Fathom → GitHub upload via integration
- Backup: Granola → email to `x404@agentmail.to` → VPS mail parser writes the file

## Pitfalls

- **Don't put the Hermes runtime and the knowledge repo in the same GitHub repo.** Secrets and session data must stay separate.
- **Don't use a personal GitHub token for automation.** It breaks when the person rotates their token or leaves.
- **Don't edit files in `sources/` after ingest.** Correct or synthesize in `wiki/`.
- **Don't forget `git config user.name` and `user.email`** inside `/data/knowledge`. Commits need an identity.
- **Don't let two writers push conflicting changes without a rebase strategy.** Use `git pull --rebase` before pushing.
- **Don't sync native `.gdoc`, `.gslides`, or `.gsheet` files.** Export them to Markdown, plain text, CSV, or PDF first.
- **Check which Hermes profile is active.** If `HERMES_HOME` points to the wrong runtime directory, cron jobs and subagents will read/write the wrong state.

## Quick Diagnostic

```bash
echo "Knowledge remote:"; cd /data/knowledge && git remote -v
echo "Knowledge status:"; git status --short
echo "Active Hermes runtime:"; echo "${HERMES_HOME:-not set}"
echo "Gateway HERMES_HOME:"; tr '\0' '\n' < /proc/$(pgrep -f 'hermes_cli.main gateway run')/environ 2>/dev/null | grep HERMES_HOME
```

## Templates

- `templates/knowledge-sync.sh` — bidirectional pull/commit/push script for a cron job.

## Related Skills

- `llm-wiki` — Karpathy-style schema with `raw/`, `entities/`, `concepts/` layers.
- `obsidian` — read/write an Obsidian vault (can point at the same directory).
- `github-auth` — authenticate `gh`/`git` with a machine-user token.
- `github-repo-management` — create repos, manage remotes, set secrets.

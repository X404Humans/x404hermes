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
  KB-SCHEMA.md                  # schema and conventions for this KB
  x404-agent-identity.md        # agent identity and operating context
  ops-guides/                   # operational drafts awaiting human sign-off
    *.md                        # PRDs, runbooks, migration plans
    archive/                    # superseded guides and legacy root files
  sources/                      # raw, immutable inputs
    meeting notes/              # exported meeting transcripts and summaries
    exercises/                  # Miro / Google Docs alignment exports
    uploads/                    # one-off files dropped for context
  wiki/                         # synthesized, agent-maintained pages
    index.md
    log.md
    contradictions.md
    members.md                  # people, roles, current responsibilities
    projects.md                 # group and member projects
    action-items.md             # owned tasks, due dates, blockers
    decisions.md                # ratified decisions
    mission-objectives-commitments.md  # canonical group alignment
```

**Rule:** Treat `sources/` as read-only evidence after ingest. Synthesis and updates belong in `wiki/` or `ops-guides/` (drafts awaiting ratification).

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
# /data/runtime/hermes/.env
GITHUB_TOKEN=***
```

Use a team-controlled email and a dedicated GitHub machine user. Example from x404 Humans Found:

```bash
git config user.name "x404hermes"
git config user.email "hermes@x404humansfound.com"
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
| Hermes runtime (`/data/runtime/hermes`) | Private, encrypted backup. Contains `auth.json`, `.env`, sessions, memories, skills, cron jobs. |

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

## Chief-of-staff / Orchestration Agent Workflows

When the team has a chief-of-staff agent, the knowledge base is both the agent's memory and the group's shared source of truth.

### 1. Meeting note → digest → action registry

1. Detect a new file in `sources/meeting notes/` (usually via the git-sync cron).
2. Read the summary/transcript and extract: decisions, action items, open questions, owners, deadlines.
3. Update `wiki/action-items.md` and `wiki/decisions.md`.
4. Post a concise digest to a dedicated Slack channel (e.g., `#agent-readouts`) with:
   - Key decisions
   - Action items with owners
   - Open questions that need human answers
   - Link back to the source note
5. Append the ingest to `wiki/log.md`.

### 2. Group alignment artifacts

Maintain canonical alignment text as a wiki page:

- `wiki/mission-objectives-commitments.md` — mission statement, objectives, commitments, operating principles.
- Propose changes in `ops-guides/` first, then ratify via Slack or live sync, then move to `wiki/`.
- Reference the alignment artifacts in every agenda and readout until the group internalizes them.

### 3. Plans and runbooks live in `ops-guides/` first

Draft PRDs, runbooks, and cleanup proposals under `ops-guides/` so humans can review and edit before anything becomes canonical. Once ratified:
- Move summary artifacts to `wiki/`.
- Archive the draft under `ops-guides/archive/` rather than deleting it.

### 4. Clean up `sources/uploads/`

Periodically review `sources/uploads/` for unreferenced images, manifests, or tool artifacts. Move unused files to `ops-guides/archive/` or delete them with human approval.

## Pitfalls

- **Don't put the Hermes runtime and the knowledge repo in the same GitHub repo.** Secrets and session data must stay separate.
- **Don't use a personal GitHub token for automation.** It breaks when the person rotates their token or leaves.
- **Don't edit files in `sources/` after ingest.** Correct or synthesize in `wiki/`.
- **Don't forget `git config user.name` and `user.email`** inside `/data/knowledge`. Commits need an identity.
- **Don't let two writers push conflicting changes without a rebase strategy.** Use `git pull --rebase` before pushing.
- **Don't sync native `.gdoc`, `.gslides`, or `.gsheet` files.** Export them to Markdown, plain text, CSV, or PDF first.
- **Check which Hermes profile is active.** If `HERMES_HOME` points to the wrong runtime directory, cron jobs and subagents will read/write the wrong state.
- **Don't let stale root files become permanent.** `about-me.md` and `KNOWLEDGE.md` are often auto-created or generic. Replace them with current, named files (`x404-agent-identity.md`, `KB-SCHEMA.md`) rather than leaving stale content in the KB root.
- **Use agent-owned GitHub accounts and emails, not personal PATs.** The orchestration agent should commit as its own machine user so actions are attributable to the agent.
- **Don't run heavy production work inside the orchestration profile.** Use dedicated sub-agents or cron jobs with isolated context for research, coding, content generation, and other heavy tasks.

## Quick Diagnostic

```bash
echo "Knowledge remote:"; cd /data/knowledge && git remote -v
echo "Knowledge status:"; git status --short
echo "Active Hermes runtime:"; echo "${HERMES_HOME:-not set}"
echo "Gateway HERMES_HOME:"; tr '\0' '\n' < /proc/$(pgrep -f 'hermes_cli.main gateway run')/environ 2>/dev/null | grep HERMES_HOME
```

## Slack Knowledge Hub

A dedicated Slack channel can act as both a notification surface and an upload intake for the knowledge base. This is distinct from the general chat channel: it is a focused place where the team sees what changed in the repo and intentionally drops files for long-term retention.

### What to automate

1. **Repo change notifications**
   - A no-agent cron job runs every 5 minutes, compares the last known `HEAD` to the current one, and posts a compact Slack message when files are added, modified, or deleted.
   - Message includes commit subject, author, and direct GitHub links to each changed file.

2. **Slack file upload ingestion**
   - A no-agent cron job polls the same Slack channel for messages with file attachments.
   - Downloads the file into `/data/knowledge/sources/uploads/`, commits, and pushes to GitHub.
   - Replies in the Slack thread with a confirmation and the GitHub link.

### Implementation pattern

- Create the Slack channel manually and invite the Hermes bot.
- Add the channel to `/data/runtime/hermes/channel_directory.json` so `hermes send` and cron delivery targets can resolve it.
- Place the scripts under `/data/knowledge/.sync/` and put thin wrappers in `/data/runtime/hermes/scripts/` (Hermes cron requires scripts under the runtime scripts directory).
- Make the wrappers export the same git auth environment used by the systemd sync service:
  ```bash
  export XDG_CONFIG_HOME=/data/runtime/config
  export GH_CONFIG_DIR=/data/runtime/config/gh
  export HOME=/data
  ```
- **Ensure git actually uses that `GH_CONFIG_DIR`.** The systemd service may export `GH_CONFIG_DIR`, but if git's `credential.helper` is configured globally as `!/usr/bin/gh auth git-credential`, the helper subprocess may read the default `~/.config/gh/hosts.yml` instead. Set the helper in `/data/.gitconfig` or the repo's local config with the env var inline:
  ```ini
  [credential "https://github.com"]
      helper = !GH_CONFIG_DIR=/data/runtime/config/gh /usr/bin/gh auth git-credential
  ```
  Verify with `cd /data/knowledge && git credential fill <<EOF` and `git fetch origin main`.
- Create two `no_agent` cron jobs with `cronjob`:
  - `kb-notify.sh` → `*/5 * * * *`, deliver to `slack:<channel_id>`
  - `kb-ingest.sh` → `*/5 * * * *`, deliver `local` (it replies in Slack itself)
- Keep the scripts state files under `/data/knowledge/.sync/` and gitignore them so they are not committed to the knowledge repo.

### Monitoring the sync

The systemd timer can fail silently for hours because the sync script exits 0 when `git fetch` returns an auth error before reaching the commit/push step. Monitor:
- `journalctl --user -u hermes-knowledge-git-sync.service -n 20`
- `/data/knowledge/.sync/git-sync-knowledge.log`
- `cd /data/knowledge && git log --oneline -5` compared to the timer trigger time.

### Workdir serialization gotcha

Hermes cron jobs that declare a `workdir` run sequentially. A long-running sub-agent (e.g., a weekly curator with a `workdir` of `/data/knowledge`) will block every other cron job that touches the same directory, including the 5-minute upload/notify jobs. Keep heavy jobs short or run them without a shared workdir.

### Repository hygiene

- Add these to `/data/knowledge/.gitignore`:
  ```
  /.sync/*.log
  /.sync/*.json
  /.cache/
  ```
- This prevents the Hermes runtime catalog caches and per-script state JSON from being committed to the shared knowledge repo.

See `references/slack-knowledge-hub.md` for the exact scripts and cron setup used in the x404 Humans Found KB.

## Templates

- `templates/knowledge-sync.sh` — bidirectional pull/commit/push script for a cron job.

## References

- `references/x404-context.md` — concrete operating context for the x404 Humans Found team KB: repos, sync cadence, agent identity, members/roles, current projects, and alignment direction.
- `references/slack-knowledge-hub.md` — full scripts and cron job configuration for a Slack-connected knowledge base channel.

## Related Skills

- `llm-wiki` — Karpathy-style schema with `raw/`, `entities/`, `concepts/` layers.
- `obsidian` — read/write an Obsidian vault (can point at the same directory).
- `github-auth` — authenticate `gh`/`git` with a machine-user token.
- `github-repo-management` — create repos, manage remotes, set secrets.

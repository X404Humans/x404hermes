# Slack Knowledge Hub — x404 Humans Found Implementation

Real configuration used for the `#knowledgebase` Slack channel connected to `github.com/X404Humans/x404knowledge`.

## Channel

- **Slack channel ID:** `C0BQKTB2GTZ`
- **Slack channel name:** `#knowledgebase`
- **Bot:** `@x404 Hermes` (`U0BFXG8AFK5`)
- **Registered in:** `/data/runtime/hermes/channel_directory.json`

## Scripts

Scripts live in `/data/knowledge/.sync/`. Hermes cron requires wrapper scripts under `/data/runtime/hermes/scripts/` because it only accepts script names from that directory.

### `/data/knowledge/.sync/kb-notify.py`

No-agent Python script. Compares the last recorded `HEAD` in `/data/knowledge/.sync/kb-notify-state.json` with the current repo `HEAD`. On change, posts to `#knowledgebase` with added/modified/deleted file counts and GitHub links.

**Important:** this script only notices commits that already reached the local repo. If the git sync is failing auth, no commits appear and the notifier stays silent even though files are being created. Always check `git-sync-knowledge.log` when commits stop appearing on GitHub.

### `/data/knowledge/.sync/kb-ingest.py`

No-agent Python script. Polls `conversations.history` for the channel, downloads any unprocessed file attachments to `/data/knowledge/sources/uploads/`, commits, pushes, and replies in the Slack thread.

### Wrappers

`/data/runtime/hermes/scripts/kb-notify.sh`:
```bash
#!/bin/bash
set -euo pipefail
export XDG_CONFIG_HOME=/data/runtime/config
export GH_CONFIG_DIR=/data/runtime/config/gh
export HOME=/data
exec /data/knowledge/.sync/kb-notify.py
```

`/data/runtime/hermes/scripts/kb-ingest.sh`:
```bash
#!/bin/bash
set -euo pipefail
export XDG_CONFIG_HOME=/data/runtime/config
export GH_CONFIG_DIR=/data/runtime/config/gh
export HOME=/data
exec /data/knowledge/.sync/kb-ingest.py
```

The `XDG_CONFIG_HOME` / `GH_CONFIG_DIR` / `HOME` values are required for git to find the same credentials used by the existing systemd sync service (`hermes-knowledge-git-sync.service`).

**Credential-helper fix:** exporting `GH_CONFIG_DIR` in the wrapper or service is not enough if git's `credential.helper` is configured globally as `!/usr/bin/gh auth git-credential`; the helper subprocess may still read the default `~/.config/gh/hosts.yml`. Either set the helper in the repo's local config or globally with the env var inline:

```ini
[credential "https://github.com"]
    helper = !GH_CONFIG_DIR=/data/runtime/config/gh /usr/bin/gh auth git-credential
```

Verify with:

```bash
cd /data/knowledge
git credential fill <<EOF
protocol=https
host=github.com
path=X404Humans/x404knowledge.git
EOF
git fetch origin main
```

## Cron jobs

Created via `cronjob` with `no_agent: true`.

| Job | Schedule | Script | Deliver |
|---|---|---|---|
| `x404-kb-change-notify` | `*/5 * * * *` | `kb-notify.sh` | `slack:C0BQKTB2GTZ` |
| `x404-kb-upload-ingest` | `*/5 * * * *` | `kb-ingest.sh` | `local` |

## Gitignore additions

These entries prevent Hermes runtime caches and per-script state files from being committed to the shared knowledge repo:

```gitignore
/.sync/*.log
/.sync/*.json
/.cache/
```

## Lessons / pitfalls

- Hermes cron refuses absolute script paths; use wrapper scripts in `/data/runtime/hermes/scripts/`.
- A wrapper must export the git credential environment used by the systemd sync service, otherwise `git push` fails with auth errors.
- **`GH_CONFIG_DIR` may not propagate into `gh` when invoked by git's `credential.helper`.** Prefix the helper in git config with `GH_CONFIG_DIR=...` to force the right `gh` config directory.
- `git add -A` in the sync/ingest scripts will commit anything not gitignored; add runtime-generated directories to `.gitignore` early.
- The ingest script uses `processed_ts` and `processed_ids` to avoid reprocessing; keep state files under `.sync/` and gitignored.
- The Slack bot must be invited to the channel before delivery works; verify with a manual `hermes send --to slack:<id>` test.
- **Silent auth failures look like "no commits."** The systemd timer may run every 5 minutes and exit 0 after `git fetch` fails, so check the log and journal, not just GitHub history.
- **Hermes cron `workdir` serialization can stall the whole KB pipeline.** A long-running sub-agent with `workdir=/data/knowledge` blocks the 5-minute upload/notify jobs. Keep sub-agents short or run them without a shared workdir.
- **Link to `blob/main/...`, not `blob/<sha>/...`, in Slack notifications.** Private repos return 404 on commit-SHA file links for users who are not signed into GitHub with repo access (and for Slack unfurls). Use branch-relative links for all file links posted to Slack. Commit links can still use the exact SHA.

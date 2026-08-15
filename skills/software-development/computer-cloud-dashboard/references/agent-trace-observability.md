# Agent Trace Observability on the Cloud Computer

Condensed from a session where the user corrected the integration approach for
making the `/computer` dashboard aware of agent activity across the machine.

## Revised core principle: Computer reads provider traces from disk

The user's position: Computer is an AI-native single point of contact for
everything happening on the machine. Every agent runtime already leaves traces
on disk. Computer should read those traces, normalize them, and surface them
in the dashboard/digest/review queue — not require each provider to emit a
custom activity stream.

This mirrors how the daily digest agent already reads Computer tasks and the
knowledge librarian reads files: agents inspect filesystem state and synthesize.

## Provider trace locations

| Runtime | Trace locations | Notes |
|---|---|---|
| Computer tasks | `/data/runtime/tasks/tasks.json` | Already the canonical source |
| Hermes | `/data/runtime/hermes-rw/state.db`, `sessions/`, `memories/` | SQLite + JSON session files |
| Claude Code | `/data/.claude/history.jsonl`, `sessions/` | `sessions/` may be `700` |
| Codex | `/data/.codex/sessions/`, `/data/runtime/codex/` | `sessions/` may be group-readable already |

## Permission fix for Hermes

`/data/runtime/hermes-rw` is currently `drwx------` and not in the
`computer-web.service` `ReadWritePaths`. To make it readable while keeping
credentials locked:

```bash
# Make top-level directories traversable/readable by the computer group
sudo chmod 0750 /data/runtime/hermes /data/runtime/hermes-rw

# Open activity-bearing subdirectories
sudo find /data/runtime/hermes /data/runtime/hermes-rw -maxdepth 2 -type d \( \
  -name 'sessions' -o -name 'memories' -o -name 'logs' -o \
  -name 'state' -o -name 'skills' -o -name 'cron' -o -name 'shared' \
\) -exec chmod 0750 {} \;

# Keep credential files owner-only
sudo find /data/runtime/hermes /data/runtime/hermes-rw -maxdepth 2 -type f \
  \( -name '.env' -o -name '.env.*' -o -name 'auth.json' -o -name '*.key' -o -name '*.pem' \) \
  -exec chmod 0600 {} \;

# Make state databases group-readable
sudo find /data/runtime/hermes /data/runtime/hermes-rw -maxdepth 2 -type f \
  \( -name 'state.db' -o -name 'kanban.db' -o -name 'channel_directory.json' \) \
  -exec chmod 0640 {} \;
```

Update the canonical installer configs so this survives reinstalls:

```bash
# Add hermes-rw to dirs.conf as a private internal dir (750 0)
sudo bash -c 'grep -q "/data/runtime/hermes-rw" /computer/install/dirs.conf || \
  sed -i "/^\\/data\\/runtime\\/hermes[[:space:]]/a\\/data/runtime/hermes-rw       750 0" /computer/install/dirs.conf'

# Make service write paths explicit
sudo sed -i \
  's|ReadWritePaths=/computer /data/runtime /data/.ollama|ReadWritePaths=/computer /data/runtime /data/runtime/hermes /data/runtime/hermes-rw /data/.ollama|' \
  /computer/install/service-write-paths.conf

# Apply to live service unit
sudo sed -i \
  's|ReadWritePaths=/computer /data/runtime /data/.ollama|ReadWritePaths=/computer /data/runtime /data/runtime/hermes /data/runtime/hermes-rw /data/.ollama|' \
  /etc/systemd/system/computer-web.service

sudo systemctl daemon-reload
sudo systemctl restart computer-web
```

## Security: redact before use

Trace files can contain secrets the user typed:

- `export OPENAI_API_KEY=...`
- `curl ... | bash` with tokens in URLs
- `cat ~/.ssh/id_rsa` or `.env` file contents
- Terminal session logs

Rules:

- Keep `/data/secrets/`, `*/.env`, `*/auth.json`, `~/.claude.json`, `*.key`, `*.pem` off-limits to agents.
- Run all trace data through a secret-redaction pass before agents or UI consume it.
- Agents should only read sanitized summaries, not raw trace dumps.

## Implementation options

### Option A — Agent-level trace reading (fastest)

Add default instructions to the Computer `general` agent:

> When asked "what's happening" or producing a chief-of-staff update, inspect:
> - `/data/runtime/tasks/tasks.json`
> - `/data/runtime/hermes-rw/state.db` (SQLite)
> - `/data/.claude/history.jsonl`
> - `/data/.codex/sessions/`
> Do not read credential files. Redact any secrets you encounter.

Uses existing `Read`/`Bash`/`Grep` tools. No new parsers or stores required at
first.

### Option B — Structured trace registry (better UX)

Add a declarative registry in Computer:

```ts
const PROVIDER_TRACES = [
  { id: "hermes", paths: ["/data/runtime/hermes-rw/state.db"], type: "sqlite", query: "..." },
  { id: "claude", paths: ["/data/.claude/history.jsonl"], type: "jsonl" },
  { id: "codex", paths: ["/data/.codex/sessions"], type: "jsonl-per-session" },
  { id: "computer", paths: ["/data/runtime/tasks/tasks.json"], type: "json" },
];
```

Normalize into a stable `ActivityEvent` schema, redact, and feed dashboard /
digest / review queue.

### Option C — Hermes as Computer work engine

Long-term convergence. Implement `runHermesAdapter` in `lib/agents/runner.ts`.
Only viable once Hermes exposes a scoped, streamable CLI mode or local API per
task.

## What not to do

- Don't require custom emissions from each provider.
- Don't treat Hermes as a special one-off case.
- Don't read credential-bearing files.
- Don't let agents consume raw traces without redaction.

## Key files

- `/computer/install/dirs.conf` — canonical directory permissions
- `/computer/install/service-write-paths.conf` — systemd writable-path contract
- `/computer/SECURITY.md` — trust boundaries and credential rules
- `/computer/lib/desktop/digest.ts` — existing digest synthesis pattern
- `/computer/lib/tasks/store.ts` — existing task-reading pattern
- `/data/runtime/hermes-rw/state.db` — Hermes session/message store

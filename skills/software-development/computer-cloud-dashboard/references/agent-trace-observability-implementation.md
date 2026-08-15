# Agent Trace Observability — Implementation Notes

Session-specific record of the trace-based observability implementation on
`/computer` so agents can observe Hermes, Claude Code, and Codex activity.

**Important:** Only Phase 1 (filesystem permissions) was kept. Phases 2–4
(agent instructions, structured trace reader, dashboard integration) were
reverted per the user's direction. The design is now: agents read traces
on-demand using existing tools, like the librarian and daily digest do.

## What was implemented and kept

### Filesystem permissions

Opened non-credential runtime traces to the `computer` user:

- `/data/runtime/hermes` → `0750`
- `/data/runtime/hermes-rw` → `0750`
- Activity subdirectories (`sessions`, `memories`, `logs`, `state`, `skills`,
  `cron`, `shared`, `platforms`, `cache`, `hermes-agent`) → `0750`
- State/activity files (`state.db`, `kanban.db`, `channel_directory.json`,
  `gateway_state.json`, `processes.json`, `sessions.json`, `request_dump_*.json`,
  `.hermes_history`, log files) → `0640`
- `/data/.claude/sessions` → `0750`
- `/data/.claude/history.jsonl` → `0640`
- `/data/.codex/sessions`, `/data/runtime/codex` → `0750`

Credential files remain locked:

- `*/.env`, `*/.env.*`
- `*/auth.json`, `*/auth.lock`
- `*.key`, `*.pem`, `*.token`, `*.secret`
- `/data/.claude.json`
- `/data/secrets/*`

### Source code changes kept

- `install/dirs.conf`
  - Added `/data/runtime/hermes-rw 750 0` to the canonical directory manifest.

### No code changes needed

No new modules, API routes, or UI components were kept. The `computer` user can
now read the trace files directly with existing tools (`Read`, `Bash`, `Grep`,
`Glob`).

## What was reverted

- `agents/general/AGENT.md` trace-reading instructions
- `agents/daily-digest/AGENT.md` trace location instructions
- `lib/activity/types.ts`
- `lib/activity/providers.ts`
- `lib/activity/reader.ts`
- `app/api/activity/route.ts`
- `components/modules/SystemOverview.tsx` Live Activity panel

## Verification commands

Check permissions:

```bash
ls -ld /data/runtime/hermes /data/runtime/hermes-rw /data/.claude/sessions /data/.codex/sessions
file /data/runtime/hermes-rw/state.db
head -3 /data/.claude/history.jsonl
ls -l /data/runtime/hermes-rw/sessions/sessions.json
ls -l /data/runtime/hermes-rw/logs/agent.log
```

Read Hermes state directly:

```bash
cd /computer && COMPUTER_DATA_DIR=/data npx tsx -e "
import Database from 'better-sqlite3';
const db = new Database('/data/runtime/hermes-rw/state.db', { readonly: true });
const sessions = db.prepare('SELECT id, source, started_at, title FROM sessions ORDER BY started_at DESC LIMIT 5').all();
console.log(sessions);
db.close();
"
```

## Lessons from this session

1. **Default `umask` is `077`.** Shared files created by `write_file` end up as
   `600`. Set `0640` explicitly for docs/code that other agents need to read.
2. **Owner can `chmod` without `sudo`.** The `/data/runtime/hermes*` directories
   are owned by `computer:computer`, so the `computer` user can change their
   permissions directly. No root access is required for this class of change.
3. **Computer should read on-disk traces, not require custom emissions.** The
   user pushed back against one-off activity streams, synthetic task sync, and
   centralized reader modules as the default. The default approach is: open
   permissions, let agents read traces with existing tools, normalize and
   redact on-demand.
4. **Credentials are the only real boundary.** Session DBs, transcripts, and
   memories are user data the computer can read. The concern about "coupling to
   Hermes storage format" was overblown; reading a SQLite DB is not different
   from reading any other trace file.

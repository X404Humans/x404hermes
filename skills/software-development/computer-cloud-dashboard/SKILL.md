---
name: computer-cloud-dashboard
description: |
  Work with the `/computer` self-hosted cloud-computer dashboard — architecture,
  task/activity model, agent runners, goal loop, and integration points for
  external agents such as Hermes. Use when asked to inspect, extend, or wire
  visibility/observability into the Computer dashboard.
version: 1.1.0
platforms: [linux]
metadata:
  hermes:
    tags: [computer, cloud-computer, self-hosted, dashboard, nextjs, agents, observability]
    category: software-development
    related_skills: [self-hosted-app-deployment, hermes-agent]
---

# `/computer` Cloud Computer Dashboard

The Computer is a self-hosted Next.js dashboard for a private VPS. It provides
terminal access, file browser, app launcher, auth, automations, scheduled agents,
and a goal loop. Source lives at `/computer`; mutable runtime state lives under
`/data`. The app runs in production mode behind hardened systemd units
(`computer-web.service`, `computer-terminal.service`) and Caddy when public.

Load this skill when the task touches the Computer codebase, its task/activity
model, agent runners, or wiring external agents (e.g., Hermes) into the dashboard.

## Architecture at a glance

```
/computer                Next.js source (also the deployed runtime)
  app/                   Pages + API routes
  app/api/tasks/         Task CRUD, polling endpoint
  components/modules/    Dashboard widgets (SystemOverview, TerminalView, ...)
  components/streaming/  ToolCallCard and streaming markdown UI
  lib/agents/            Agent definitions, capabilities, runner
  lib/goals/             Goal store, planner, loop, engine
  lib/scheduler/         Cron/interval/event scheduler
  lib/tasks/             Task store, engine, runner, types
  agents/                Workspace agent definitions (general, self-improver, ...)
  docker/Caddyfile       Public-mode reverse proxy
/data
  runtime/tasks/         Task JSON store (tasks.json)
  runtime/goals/         Goal workspaces and artifacts
  runtime/settings/      User settings including assistant runtime
```

Key services:

- Next.js dashboard on `127.0.0.1:3000`.
- Terminal WebSocket on `127.0.0.1:3001`.
- Caddy terminates TLS on public installs (ports 80/443).

## Production rule

`/computer` is **always production**. Any React/Next.js change is invisible until:

1. Code is committed.
2. `npm run build` runs inside `/computer` as the `computer` user.
3. Services are restarted via the privileged helper:
   ```bash
   printf '{"operation":"restart","service":"all"}' | sudo -n /usr/local/libexec/computer-service-helper
   ```

Do not tell the user to run `npm run dev` or expect hot reload. The systemd units
serve the pre-built `.next/` output.

## Task/activity model: the integration surface

Tasks are the canonical unit of work. The task store is a JSON file under
`/data/runtime/tasks/tasks.json` (managed by `lib/tasks/store.ts`).

Useful task fields for visibility/observability:

| Field | Meaning |
|-------|---------|
| `id` | `task-${timestamp}-${rand}` |
| `name` | Human label |
| `agent` | Agent slug, e.g. `general`, `self-improver` |
| `status` | `queued`, `running`, `awaiting_input`, `for_review`, `completed`, `failed`, `archived` |
| `prompt` | The user request / trigger text |
| `steps` | `StepEntry[]` parsed from `__STEP_*__` markers |
| `activities` | `TaskActivity[]` — live tool calls |
| `messages` | Conversation turns |
| `pid` | Running process id |

`TaskActivity` shape:

```ts
interface TaskActivity {
  tool: string;
  input: Record<string, unknown>;
  ts: number;
  status?: "running" | "done" | "error";
  output?: string;
}
```

`lib/tasks/runner.ts` already parses `tool_use` blocks from Claude/Codex
`stream-json` output and appends them to `activities` in real time.
`components/streaming/ToolCallCard.tsx` renders a single activity.

## How external agents (e.g., Hermes) get visibility

Hermes runs as an independent gateway process (`/data/runtime/hermes-rw/`). It
will **not** appear in the dashboard automatically. The user's position is that
Computer is the AI-native single point of contact for everything happening on
the machine. Every agent runtime already leaves traces on disk; Computer should
read those traces, just like the knowledge librarian reads files and the daily
digest reads tasks.

The key boundary is **credentials**, not all private state:

- Off-limits: `/data/secrets/`, `*/.env`, `*/auth.json`, `~/.claude.json`,
  `*.key`, `*.pem`.
- Readable for observability: session databases, history files, session
  directories, and tool output logs.

Because trace files can contain secrets the user typed (e.g., `export
OPENAI_API_KEY=...`, `cat ~/.ssh/id_rsa`), all trace data must pass through a
secret-redaction layer before agents consume it.

See `references/agent-trace-observability.md` for canonical trace locations,
permission commands, and redaction rules. See
`references/agent-trace-observability-implementation.md` for the actual
permission changes made in this session and the commands to verify them.

### Implemented: filesystem permissions (Phase 1)

The only code change kept is the permission fix:

1. Open non-credential runtime directories to the `computer` user.
2. Keep credential files (`*/.env`, `*/auth.json`, `~/.claude.json`, `*.key`,
   `*.pem`, `/data/secrets/*`) at `0600` or stricter.
3. Add `/data/runtime/hermes-rw 750 0` to `install/dirs.conf` so the change
   survives reinstalls.

These commands were run as the `computer` user (the owner of the directories),
so no `sudo` or `root` access was required:

```bash
chmod 0750 /data/runtime/hermes /data/runtime/hermes-rw
chmod 0750 /data/.claude/sessions
find /data/runtime/hermes /data/runtime/hermes-rw -maxdepth 2 -type d \
  \( -name 'sessions' -o -name 'memories' -o -name 'logs' -o -name 'state' \
     -o -name 'skills' -o -name 'cron' -o -name 'shared' -o -name 'platforms' \
     -o -name 'cache' -o -name 'hermes-agent' \) \
  -exec chmod 0750 {} \;
find /data/runtime/hermes /data/runtime/hermes-rw -maxdepth 2 -type f \
  \( -name 'state.db' -o -name 'state.db-shm' -o -name 'state.db-wal' \
     -o -name 'kanban.db' -o -name 'channel_directory.json' \
     -o -name 'gateway_state.json' -o -name 'processes.json' \
     -o -name 'sessions.json' -o -name 'request_dump_*.json' \
     -o -name '.hermes_history' \) \
  -exec chmod 0640 {} \;
find /data/runtime/hermes /data/runtime/hermes-rw -maxdepth 2 -type f \
  \( -name '.env' -o -name '.env.*' -o -name 'auth.json' -o -name '*.key' \
     -o -name '*.pem' -o -name '*.token' -o -name '*.secret' \) \
  -exec chmod 0600 {} \;
find /data/runtime/hermes-rw/logs -type f -exec chmod 0640 {} \;
chmod 0640 /data/.claude/history.jsonl
chmod 0600 /data/.claude.json
find /data/.codex /data/runtime/codex -maxdepth 2 -type d -exec chmod 0750 {} \;
find /data/.codex /data/runtime/codex -maxdepth 2 -type f -exec chmod 0640 {} \;
```

### Optional later phases

The user declined the following in this session. They are still valid if product
needs change, but they are not the default:

- **Agent instructions** (Phase 2): adding trace locations to
  `agents/general/AGENT.md` and `agents/daily-digest/AGENT.md`.
- **Structured trace reader** (Phase 3): a `lib/activity/reader.ts` module,
  stable `ActivityEvent` schema, and `/api/activity` endpoint.
- **Dashboard/digest/review integration** (Phase 4): a "Live Activity" panel in
  `SystemOverview.tsx`, digest integration, and automatic review items.

These options are documented in `references/agent-trace-observability.md`.

### Older options (still valid in different contexts)

- **Synthetic task sync**: write `Task` records with `agent: "hermes"`. Useful
  when you want Hermes work to appear in the existing task/review queue model.
- **MCP bridge**: add a `report_activity` MCP server inside Computer. Good for
  bidirectional integration, but requires the provider to call it.
- **Hermes as Computer work engine**: implement a `hermes` adapter in
  `lib/agents/runner.ts`. Long-term convergence; only viable once Hermes exposes
  a scoped, streamable CLI mode or local API per task.

## What Computer actually sees from other adapters

Computer sees the **output stream** of Computer-managed adapter tasks (Claude
Code `stream-json`, Codex JSON lines). For agents that run independently
outside Computer tasks, Computer reads their **on-disk traces** with the same
tools it uses for any other filesystem inspection.

## Slack integration reality

Computer has a Slack **connection**, not a Slack **gateway**:

- `helpers/computer-connection-helper.ts` exposes `messages.send` and
  `messages.list` via Slack Web API.
- It is **outbound polling/send**, not a live inbound gateway.
- It cannot receive DMs, reply in-thread automatically, or maintain
  multi-turn Slack context.

Hermes has a full Slack gateway. If the user is Slack-first, the architecture
should keep Hermes as the gateway and feed a visibility stream to Computer,
rather than rebuild Slack gateway logic inside Computer.

## Current runtime example (Ollama Cloud + Kimi)

`/data/runtime/settings/assistant.json` holds the default runtime. Example:

```json
{
  "provider": "ollama",
  "adapter": "claude",
  "agent": "general",
  "model": "kimi-k2.7-code:cloud"
}
```

Flow: user request → `lib/tasks/engine.ts` → `getDefaultAssistantRuntime()` →
`lib/agents/runner.ts` `runClaudeAdapter()` → `claude -p ... --model
kimi-k2.7-code:cloud` with `ANTHROPIC_BASE_URL` pointed at Ollama Cloud.
Computer is using Claude Code as the tool-calling runtime and Ollama as the
model backend.

## Hermes capabilities vs Computer

Hermes and Computer overlap more than Claude/Codex and Computer do:

| Capability | Computer | Hermes |
|---|---|---|
| Web dashboard | ✅ Native | ❌ CLI/TUI/gateway only |
| Slack gateway | ⚠️ Outbound connection | ✅ Full gateway |
| Task/goal scheduler | ✅ Goal loop + scheduler | ✅ Cron + kanban |
| Cross-session memory | ⚠️ Task-scoped messages | ✅ Persistent memory |
| Skills system | ⚠️ Agent prompts | ✅ Dynamic skill loading |
| Subagent delegation | ❌ Not native | ✅ `delegate_task` |
| Provider/model pooling | ⚠️ Single runtime setting | ✅ Per-message routing |

So Hermes should not be treated as a thin pass-through adapter — that wastes its
strengths. The sensible design is Computer as the dashboard/policy layer and
Hermes as the execution/gateway layer, with a normalized activity feed between
them.

## Recommended starting point

When the user asks "what would it take for the Computer dashboard to see what
Hermes is doing?", start with the trace-reading approach:

1. Open filesystem permissions on non-credential runtime directories so the
   Computer web service can read them.
2. Let Computer agents inspect Hermes/Claude/Codex traces using existing tools
   (`Read`, `Bash`, `Grep`, `Glob`) when asked "what's happening" or producing
   a digest.
3. Only add a structured trace reader, API, or dashboard feed if the user
   explicitly asks for live UI or automated digest/review integration.
4. Use synthetic task sync or an MCP bridge only when the user explicitly needs
   Computer's existing task/review lifecycle to own the external work.

## File permissions pitfall

When writing shared documentation or code files for a team of agents, set the
file mode to `0640` explicitly. The default `umask` in this environment is
`077`, so `write_file` creates owner-only (`600`) files by default. Other
agents running as the same user can read them only if the group bit is set.

Good:
```bash
chmod 0640 /computer/docs/some-shared-doc.md
```

Bad: leaving it at `600` and discovering another agent cannot read it.

## Key files to know

- `lib/tasks/types.ts` — task and activity types.
- `lib/tasks/store.ts` — JSON task store.
- `lib/tasks/engine.ts` — create/start/cancel/get task.
- `lib/tasks/runner.ts` — parses stream-json and populates `activities`.
- `app/api/tasks/route.ts` — task list/creation API.
- `app/api/tasks/[id]/route.ts` — single task API.
- `components/streaming/ToolCallCard.tsx` — activity renderer.
- `components/modules/SystemOverview.tsx` — main dashboard landing widget.
- `components/layout/MemoDesk.tsx` — main dashboard page.
- `lib/assistant-defaults.ts` — adapter/provider defaults.
- `lib/connections/runtime-mcp.ts` — how MCP servers are wired to Claude/Codex.

See `references/computer-dashboard-files.md` for session-specific excerpts and
path notes from the initial survey. See `references/agent-trace-observability.md`
for the design principles, and `references/agent-trace-observability-implementation.md`
for the actual files and verification commands from the implementation session.

## Pitfalls

- **Do not assume hot reload.** `/computer` is production systemd; every UI
  change needs `npm run build` + service restart.
- **Do not confuse `/computer` with the Hermes agent runtime.** Hermes lives in
  `/data/runtime/hermes-rw/` and has its own sessions, skills, and memory.
- **Do not edit `/data/runtime/tasks/tasks.json` by hand** while the app is
  running; use the store API or the REST endpoints to avoid races.
- **Agent capabilities are gated** in `lib/agents/capabilities.ts`. Any new
  `hermes` agent or bridge needs a matching policy if it runs under the Computer
  task engine.
- **Auth is required** for all `/api/*` endpoints; the bridge must run with a
  valid Better Auth session or be an internal service route.
- **Owner can `chmod` without `sudo`.** The `/data/runtime/hermes*` directories
  are owned by `computer:computer`. Permission changes for observability can be
  done directly as the `computer` user; root is only needed for `chown` or systemd
  unit edits.

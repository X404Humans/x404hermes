# `/computer` Dashboard — Session-Specific File Map

Captured during an architecture survey for Hermes → Computer visibility.

## Repo

- Origin: `https://github.com/Pommon-Labs/computer.git`
- Source/runtime: `/computer`
- Mutable state: `/data`
- Production services: `computer-web.service`, `computer-terminal.service`
- Privileged restart helper: `/usr/local/libexec/computer-service-helper`

## Core task/activity plumbing

- `/computer/lib/tasks/types.ts`
  - `TaskTrigger`, `TaskStatus`, `TaskRole`, `StepEntry`, `TaskActivity`,
    `TaskMessage`, `Task`, `CreateTaskInput`.
  - Marker protocol: `__STEP_START__`, `__STEP_DONE__`, `__STEP_ERROR__`,
    `__INPUT_REQUIRED__`.

- `/computer/lib/tasks/store.ts`
  - JSON file store at `/data/runtime/tasks/tasks.json`.
  - `create`, `get`, `update`, `remove`, `list`, `listActive`.
  - Includes default scheduled tasks:
    - `sys-daily-briefing` → `agents/daily-digest`
    - `sys-nightly-reflection` → `agents/self-improver`

- `/computer/lib/tasks/engine.ts`
  - `createTask`, `startTask`, `cancelTask`, `getTask`, `listTasks`,
    `listActiveTasks`, `recoverOrphanedTasks`.
  - `getTask` re-parses the latest log and returns the last 120 lines.

- `/computer/lib/tasks/runner.ts`
  - Spawns Claude/Codex or uses `lib/agents/runner.ts`.
  - Parses `stream-json` lines and appends `tool_use` blocks to `activities`.
  - Writes logs to `/tmp/computer-tasks/{taskId}.log` and
    `/tmp/computer-tasks-streams/{taskId}.stream`.

## API routes

- `/computer/app/api/tasks/route.ts`
  - `GET /api/tasks` — list; supports `?status=`, `?trigger=`, `?view=list`
    (list view strips `activities`, `log`, `steps`, `history`).
  - `POST /api/tasks` — create + optional start.
  - `PATCH /api/tasks` — archive/cancel/enable/disable/generic update.

- `/computer/app/api/tasks/[id]/route.ts`
  - `GET /api/tasks/:id` — single task + parsed state.
  - `PATCH /api/tasks/:id` — submit input, cancel, generic update.

## UI pieces

- `/computer/components/streaming/ToolCallCard.tsx`
  - Renders one `TaskActivity` with icon, label, status dot, and collapsible
    input/output JSON.
  - Supports `Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `WebSearch`,
    `WebFetch`, and a default gear icon.

- `/computer/components/modules/SystemOverview.tsx`
  - Main dashboard landing card showing CPU/memory/disk/uptime and quick links.
  - Polls `/api/system` every 5s. A natural place to add a "Live Activity" row.

- `/computer/components/layout/MemoDesk.tsx`
  - The default `/computer` page component.

- `/computer/app/computer/tasks/page.tsx`
  - Full task list page; polls `/api/tasks?view=list` every 10s.

## Agent/runtime plumbing

- `/computer/lib/agents/runner.ts`
  - `runAgent()` spawns Claude or Codex with `--output-format stream-json`.
  - `buildAgentEnv()` defines the restricted env passed to child agents.

- `/computer/lib/agents/capabilities.ts`
  - `AgentCapabilityProfile`, `AgentCapabilityPolicy`.
  - Maps agent slugs (e.g., `general`, `self-improver`) to allowed tools and
    roots. Any new `hermes` agent needs an entry here if it runs under the
    Computer task engine.

- `/computer/lib/assistant-defaults.ts`
  - `AssistantAdapter` includes `hermes` but it is `selectable: false` and tagged
    as a future work engine option.

- `/computer/lib/goals/loop.ts`
  - Goal loop controller; drives planner → doer → checker cycle on a 5s tick.

- `/computer/lib/goals/interpreter.ts`
  - `briefPrompt()`, `startBriefDraft()`, `readBriefDraft()`, `briefToGoalPatch()`.

- `/computer/instrumentation.ts`
  - Bootstraps storage, scheduler, goal loop, etc. when Next.js starts in
    Node.js runtime.

## MCP/connection pattern

- `/computer/lib/connections/runtime-mcp.ts`
  - Wires `computer_connections` MCP server into Claude/Codex args.
  - A Hermes visibility MCP server would follow the same shape.

- `/computer/lib/connections/catalog.ts`
  - Connection catalog (`claude`, `openai`, `ollama`, `github`, `agentmail`,
    `granola`, `fathom`, `slack`, `telegram`). Hermes is not a connection yet.

## Path constants

- `/computer/lib/paths.ts`
  - `sourceDir` → `/computer`
  - `dataDir` → `/data`
  - `runtimeDir` → `/data/runtime`
  - `agentsDir` → `/data/agents`
  - `appsDir` → `/data/apps`
  - `secretsDir` → `/data/secrets`

## Agent prompt workspaces

- `/computer/agents/general/AGENT.md`
- `/computer/agents/self-improver/AGENT.md`
- `/computer/agents/feature-builder/AGENT.md`
- `/computer/agents/review-curator/AGENT.md`
- `/computer/agents/security-auditor/AGENT.md`
- and others...

These are the canonical prompts for Computer's built-in agents.

## Hermes runtime (separate from Computer)

- Config/runtime: `/data/runtime/hermes-rw/`
- Default profile: `/data/runtime/hermes-rw/profiles/default/`
- Session store: `state.db`
- Gateway state: `gateway_state.json`
- Skills: `/data/runtime/hermes-rw/skills/`

Hermes has its own gateway, sessions, skills, and memory. It does not write to
Computer's task store unless a bridge is added.

## Relevant production commands

```bash
# Build (as computer user, from /computer)
npm run build

# Restart all Computer services
printf '{"operation":"restart","service":"all"}' | sudo -n /usr/local/libexec/computer-service-helper

# Check design-token compliance before build
npm run check:repository
```

---
name: group-orchestration-agent
description: "Onboard and operate a chief-of-staff / orchestration agent for a small collective or guild: ingest shared knowledge, draft PRD and alignment artifacts, set up sub-agents and Slack coordination, and manage execution plans."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [orchestration, chief-of-staff, collective, guild, multi-agent, slack, knowledge-base]
    related_skills: [hermes-agent, llm-wiki, plan]
---

# Group Orchestration Agent

Set up and operate a **chief-of-staff / orchestration agent** for a small collective, guild, or team. The agent keeps the group aligned, synthesizes context, tracks actions and decisions, and delegates production work to specialized sub-agents.

## When to use

- A group wants a shared orchestration agent to coordinate humans + sub-agents.
- There is a central knowledgebase (Karpathy-style wiki) and a messaging platform (usually Slack).
- The agent needs to read meeting notes, track action items, build agendas, and surface decisions.
- The group is considering dedicated sub-agents for research, coding, content, etc.

## Preconditions

- A synced knowledgebase folder (e.g., `/data/knowledge`) with:
  - `sources/` for immutable raw material (meeting notes, exercises, uploads)
  - `wiki/` for agent-created synthesis
  - `ops-guides/` for plans and runbooks
- A messaging workspace where the agent is already present (e.g., Slack).
- An agent-owned account (GitHub, email) rather than personal PATs.

---

## 1. Onboarding Workflow

### Step 1: Ingest context
1. Read the knowledgebase structure.
2. Read key source files: exercises, meeting notes, alignment drafts.
3. Read relevant Slack history (alignment threads, project channels).
4. Identify members, projects, and current frictions.

### Step 2: Draft foundational artifacts
1. **Agent identity doc** in KB root: name, role, what I do/don’t do, canonical paths, communication style.
2. **KB schema doc**: layout, rules, frontmatter, tag taxonomy, archive policy.
3. **Group alignment proposal**: mission, objectives, commitments, operating principles, and a separate R&R concept proposal.
4. **PRD**: identity, design principles, MVP scope, sub-agent map, Slack channel structure, architecture, execution plan.

### Step 3: Human review
- Post alignment and PRD to the main coordination channel.
- Ask for async feedback and ratify live at the next sync.
- Do not write durable files beyond drafts until sign-off.

### Step 4: Build MVP
Typical 24-hour MVP:
1. Meeting-note digest pipeline (cron + sub-agent + Slack post).
2. Action-item registry in the wiki.
3. Slack 2-way Q&A about group context.
4. Weekly agenda + meeting-notes reminder crons.
5. Stale-action detection.

### Step 5: Spin off sub-agents
- Research radar: dedicated cron to its own Slack channel.
- Knowledge curator: weekly KB lint.
- Build dispatcher: future-only; create per-project channels when real builds start.

---

## 2. Design Principles

| # | Principle |
|---|---|
| 1 | **Lean orchestrator, fat sub-agents** — the main agent coordinates; heavy work runs in isolated sub-agents. |
| 2 | **KB-first, memory-second** — group knowledge lives in the synced wiki; agent memory is only for personal operating context. |
| 3 | **Slack is the console** — notifications and 2-way chat from day one. |
| 4 | **Agent-owned actions** — use agent accounts, not personal PATs. |
| 5 | **Canonical paths** — no ad-hoc profile or folder suffixes. |
| 6 | **Local-first over MCP** — prefer synced files over live third-party MCPs. |
| 7 | **Security by default** — no credentials or sensitive data in the KB. |

---

## 3. Sub-Agent Map Template

| Sub-agent | Responsibility | Channel | Model | Notes |
|---|---|---|---|---|
| Main orchestrator | Coordination, alignment, 2-way chat | Main channels | Strongest available coding/reasoning model | Keep small |
| Meeting Digest | Summarize notes, extract actions | `#meetings` | Cheaper long-context model | Offloads heavy reading |
| Meeting Prep | Draft next-sync agenda from KB + Slack | `#meetings` | Cheaper reasoning model | Runs before each sync |
| Research Radar | Recurring research briefs | `#research-radar` or the channel ID the group assigns | Cheaper reasoning model | Isolates paid/scheduled work |
| Knowledge Curator | Weekly KB lint | Route by content | Cheapest adequate model | Structural checks only |
| Build Dispatcher | Coordinate group builds | Per-project channel | Strongest coding model | Future-only until a build exists |

### Model selection guidance
- Use the strongest available model for the main orchestrator.
- Use cheaper models for text-only, structured, or batch tasks.
- Constrain recommendations to the provider the runtime actually has access to (e.g., ollama-cloud only if that is what is configured).

### Implementing sub-agents with isolated Hermes profiles
When the runtime is a single Hermes instance, create sub-agents as **isolated profiles** rather than running everything in the default profile. This keeps the main orchestrator lean and lets each sub-agent have its own model, context, and failure domain.

Recipe:
1. Create a profile: `hermes profile create <sub-agent-name> --description "..."`.
2. Write a minimal `config.yaml` in the profile directory that overrides only `model.default` (and optionally `agent.max_turns`); inherit everything else from the base runtime.
3. Write a shell script under `/data/runtime/hermes/scripts/<sub-agent-name>.sh` that calls the profile wrapper (`/data/.local/bin/<sub-agent-name>`) with a single self-contained prompt.
4. Symlink the script into `~/.hermes/scripts/<sub-agent-name>.sh` so Hermes cron can reference it by filename.
5. Create or update a cron job to run the script on the desired schedule, delivering to the right Slack channel.
6. Document the sub-agent in a skill file under `/data/runtime/hermes/skills/<sub-agent-name>/SKILL.md`.

See `references/hermes-isolated-sub-agent-recipe.md` for a copy-pasteable example.

---

## 4. Slack Channel Structure Guidance

### Start minimal
- `#general` — human coordination, announcements, async votes.
- `#meetings` — agendas, meeting digests, action items, decisions, status.
- `#research-radar` or the **actual channel ID the user gives you** (e.g., `<#C0BQURPSA8M>`) — dedicated research sub-agent output. **Use the ID, not an invented display name.**
- `#orchestration` or `#x404-hermes` — building the orchestration agent itself.

### Add channels only after dialogue
- Do not create `#build-track` for multiple projects; use a dedicated channel per project when a build starts.
- Do not create a generic `#knowledge-wiki` channel; route wiki updates to the channel matching the content.
- Project-specific channels (e.g., `#enter-the-claw`, `#buzz`) should already exist for member projects.

### Routing rules
- Meeting/action/decision/status updates → `#meetings`
- Agent architecture/ops-guides about the agent → `#orchestration`
- Group alignment/decisions → `#meetings` or `#general`
- Project-specific synthesis → the project’s channel

---

## 5. Execution-Plan Hygiene

When a plan spans sessions or the user reads the workspace remotely:

1. Maintain the canonical plan in the KB / workspace.
2. **Replicate state in chat** whenever a material change occurs: completed, pending, blocked.
3. Use this exact shape:

```text
[Plan Name] — State

COMPLETED
[x] Task A
[x] Task B

PENDING
[ ] Task C
[ ] Task D

BLOCKED
[ ] Task E — waiting on [who/what]
```

See `references/remote-stakeholder-execution-plan.md`.

---

## 6. KB Cleanup in Shared / Cloud-Computer Environments

When cleaning a knowledgebase that may be read by other tools:

1. Do not move or rename files whose consumers are unclear.
2. Leave suspected-legacy files in place.
3. Create a tracking note in `ops-guides/` asking the infrastructure owner to confirm dependencies.
4. Move files to an `archive/` subfolder **without renaming** only after explicit confirmation.
5. See `references/kb-cleanup-cloud-computer.md`.

---

## 7. Common Pitfalls

- **Moving too fast without closing loops** — always surface open questions and wait for input before locking in channel/model decisions.
- **Over-explaining in chat** — keep status updates brief; link to KB for details.
- **Assuming third-party model access** — confirm the runtime’s actual provider and model list.
- **Using invented Slack channel display names** — always use the channel ID the user provides (e.g., `<#C0BQURPSA8M>`), not a name you make up. Display names can be renamed; IDs are canonical.
- **Creating channels without dialogue** — adding channels changes group behavior; propose first.
- **Keeping heavy recurring work in the orchestration profile** — move paid/scheduled/long-context work to sub-agents.

---

## 8. References

- `references/remote-stakeholder-execution-plan.md`
- `references/kb-cleanup-cloud-computer.md`
- `references/model-selection-ollama-cloud.md`
- `references/slack-channel-proposal-template.md`

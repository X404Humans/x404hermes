---
name: guild-orchestration-agent
description: "Build and operate a chief-of-staff / orchestration agent for a small builder guild or collective. Combines Karpathy-style knowledgebase, Slack console, sub-agent delegation, and fast MVP execution."
version: 1.0.0
author: Hermes Agent + x404 Humans Found
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [orchestration, chief-of-staff, guild, multi-agent, slack, knowledgebase, karpathy-wiki]
    related_skills: [llm-wiki, hermes-agent]
---

# Guild Orchestration Agent

Use this skill when a user wants to turn an agent into a **chief of staff / orchestration agent** for a small group, collective, studio, or guild.

The pattern combines:
- A **Karpathy-style markdown knowledgebase** as the shared source of truth.
- **Slack** as the notification console and 2-way chat surface.
- **Specialized sub-agents** for production work, so the orchestrator stays lean.
- **Fast MVP execution** (24-hour MVP, 48-hour follow-ons) rather than multi-week roadmaps.

## When This Skill Activates

Use when the user asks to:
- Build an orchestration / chief-of-staff agent for a group.
- Coordinate a small team via Slack with an agent.
- Set up meeting-note digestion, action tracking, agendas, or research radar.
- Design sub-agents and channel routing for group workflows.

## Core Design Principles

1. **Lean orchestrator, fat sub-agents.** The chief-of-staff agent does coordination and synthesis. Heavy work (research, coding, content) goes to dedicated sub-agents.
2. **KB-first, memory-second.** The Karpathy-style KB is the **group source of truth**. Hermes memory is the agent’s **personal operating context**. Put group-facing facts in the KB; put behavioral/preferences in memory.
3. **Slack is the console from day one.** Notifications and 2-way chat both happen in Slack. Do not treat 2-way chat as a future phase.
4. **Agent-owned accounts.** Use agent accounts (GitHub, email) for agent actions, not personal PATs.
5. **Canonical paths.** Keep runtime and knowledge at stable paths; avoid ad-hoc suffixes.
6. **Local-first knowledge.** Prefer ingesting into a VPS KB over live MCP connections to external tools.
7. **Security by default.** No secrets or personal sensitive data in the KB.

## KB vs. Hermes Memory

| | Karpathy KB (`/data/knowledge`) | Hermes memory (`~/.hermes/memories/`) |
|---|---|---|
| Audience | Group + future sub-agents | Agent’s own operating context |
| Content | Meeting notes, decisions, members, projects, action items | User preferences, Slack ID mappings, recurring corrections, workflow lessons |
| Persistence | Git-synced markdown | Auto-injected every session |
| Rule | If another member or sub-agent would benefit from reading it, put it here. | If only the agent needs to remember it, put it here. |

## Fast Execution Cadence

This skill assumes modern agent tooling: MVPs should be live in hours, not weeks.

- **MVP:** operational within 24 hours of approval.
- **Follow-ons:** operational within 48 hours of MVP.
- **Parking lot:** anything not committed goes here, not into the roadmap.

When drafting plans, frame tasks in hours, not weeks, unless the user explicitly asks for a slower cadence.

## Starter Architecture

```text
/data/knowledge/               # Karpathy KB
  x404-agent-identity.md       # Agent identity + canonical paths
  KB-SCHEMA.md                 # Schema and conventions
  sources/                     # Immutable raw material
    meeting notes/
    exercises/
    uploads/
  wiki/                        # Synthesis
    index.md
    log.md
    members.md
    projects.md
    action-items.md
    decisions.md
    open-questions.md
    mission-objectives-commitments.md
  ops-guides/                  # Plans, runbooks
    archive/                   # Legacy files (filenames preserved)

/data/runtime/hermes/          # Hermes runtime
  scripts/
  cron/
  skills/
```

## Slack Channel Conventions

Prefer fewer channels. Suggested mapping:

| Channel | Purpose |
|---|---|
| `#general` | Human coordination, async feedback, announcements |
| `#meetings` (or existing equivalent like `#C0B5T66ESGY`) | Agendas, meeting digests, action items, decisions |
| `#research-radar` | Dedicated sub-agent market/intelligence briefs |
| `#orchestration` | Building the orchestration agent itself |
| Per-project channels | Member projects and experiments |

When the user already has channels, reuse existing ones rather than creating new ones unless a dedicated sub-agent channel is clearly needed.

## Sub-Agent Map

| Sub-agent | Responsibility | Recommended model |
|---|---|---|
| **Orchestrator** (you) | Alignment, agendas, decisions, 2-way chat | Current default or kimi-k2.7-code |
| **Meeting Digest** | Extract decisions/actions/open questions from notes | kimi-k2.7-code / qwen3-235b-a22b |
| **Research Radar** | Market/intelligence briefs | qwen3-235b-a22b (cheap, good at synthesis) |
| **Knowledge Curator** | Wiki lint, cross-links, staleness | qwen3-235b-a22b |
| **Build Dispatcher** | Spawn coding/build agents | kimi-k2.7-code / claude-sonnet-4 |

Model selection heuristics:
- **qwen3-235b-a22b / qwen3.7**: good value for text-only synthesis and web research.
- **kimi-k2.7-code**: strong tool use, coding, and long context.
- **deepseek-v3 / deepseek-flash**: excellent cheap reasoning, not multimodal.
- **claude-sonnet-4**: best for complex coding and nuanced judgment; reserve for high-leverage tasks.

## Meeting-Note Digest Pipeline

A minimum viable orchestration agent should digest meeting notes automatically:

1. Watch `/data/knowledge/sources/meeting notes/` for new `.md` files.
2. Extract: decisions, action items, open questions, owners.
3. Auto-assign owners based on who spoke about a topic; allow humans to override.
4. Post digest to the meetings channel.
5. Append action items to `wiki/action-items.md`.
6. Schedule a cron to scan for new notes daily.

Example digest format:
```markdown
:x404: *Meeting Digest — [title / date]*

*Key Decisions*
- bullet

*Action Items*
- [owner] task

*Open Questions*
- question

*Source:* [relative path]
```

## Weekly Agenda Builder

Before each sync, the orchestrator should post a proposed agenda to the meetings channel. Treat the agenda as a **time-boxed meeting plan**, not a dump of all open work.

### Recommended agenda structure
1. **Orchestration / KB / agent recap** — human walkthrough of what changed since last sync. Provide a concise `ops-guides/` recap doc for the human to reference.
2. **Cross-stack or parallel experiment updates** — e.g., Buzz, other sub-agent experiments, member project demos.
3. **Heads-up on pressing action items only** — flag items that need attention, but do not schedule deep discussion for work that should happen async.
4. **Live discussion items** — only topics that genuinely need synchronous time.
5. **Pending decisions needing ratification** — split compound proposals into separate, clearly named decisions (e.g., D1 mission/objectives/commitments, D2 roles & responsibilities concept).
6. **Blockers** — anything that is actually stuck.

### Agenda rules
- Mark async-only action items explicitly as "async / heads-up only"; keep them out of live discussion unless they become blockers.
- When a group proposal combines mission, objectives, commitments, and roles, split it into at least two decisions so the group can ratify each part independently.
- Include direct links to the relevant KB pages and any recap doc.
- Read the last 7 days of relevant Slack history before drafting.

### Sync recap doc pattern
Before the sync, write a one-page `ops-guides/YYYY-MM-DD-<topic>-recap.md` that the human facilitator can read from or link to. Include:
- What changed since the last sync.
- What is now live / automated.
- Open decisions that need ratification (with IDs like D1, D2).
- Async-only action items (with IDs like A3, A4).
- Real blockers and who can unblock them.

## Handling Sync Auth / Delivery Blockers

If a content commit succeeds locally but push/delivery fails due to missing credentials, channel membership, or environment state:
1. Do not fabricate a successful delivery.
2. Report the blocker honestly in the same thread, noting what is committed locally and what needs fixing.
3. Surface the fix owner (e.g., Zain for VPS/Caddy auth, channel admin for Slack invites).
4. Retry only when the fix is applied.

## Action Items and Decisions

Maintain two lightweight wiki pages:
- `wiki/action-items.md` — owner, task, due, source, status, blockers.
- `wiki/decisions.md` — date, decision, context, who ratified.

Auto-assign owners by default; humans can override. Surface stale items (>7 days unchanged) in the weekly agenda.

## Alignment Artifacts

Help the group maintain and ratify:
- Mission statement
- Objectives
- Commitments
- Operating principles
- Roles & responsibilities (R&R) as a concept to be proposed, not imposed.

Post drafts to `#general` for async feedback, then ratify live at the next sync or via Slack vote.

## Knowledgebase Cleanup Rules

When cleaning up a shared KB:
1. Create new canonical files before replacing legacy ones.
2. Move legacy files to `ops-guides/archive/` or `sources/uploads/archive/` **without renaming** them.
3. Leave files untouched if any system (cloud computer, agent, cron) might depend on them until the owner confirms.
4. Never modify files under `sources/` (immutable).
5. Always log moves and creations in `wiki/log.md`.

## Parking Lot

Capture deferred ideas in a `wiki/projects.md` or `ops-guides/parking-lot.md` section, including:
- Live integrations that require personal PATs or fragile MCPs.
- Email send capability (depends on agent identity / mailgent setup).
- Webhook upgrades that touch production Caddy config.

## References

- `references/x404-prd-and-alignment.md` — session-specific PRD, alignment proposal, channel mappings, and model recommendations from the x404 build.
- `references/x404-agenda-format-and-recap-pattern.md` — corrected weekly agenda structure, sync recap doc pattern, and the async-vs-live discussion rule.

## Pitfalls

- **Do not** plan MVPs in weeks unless the user explicitly asks for it.
- **Do not** create a new Slack channel for every workflow; reuse existing channels where possible.
- **Do not** treat 2-way Slack chat as a future phase.
- **Do not** store secrets or personal data in the KB.
- **Do not** auto-delete legacy files; archive with filenames preserved.
- **Do not** conflate Hermes memory with the Karpathy KB.

## Related Skills

- `llm-wiki` — Karpathy-style knowledgebase pattern.
- `hermes-agent` — Hermes CLI, config, sub-agents, cron, memory.
- `plan` — if a full implementation plan is needed before execution.

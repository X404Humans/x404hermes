# x404 Weekly Agenda Format & Sync Recap Pattern

> Source session: 2026-08-18 with Tony (x404 Humans Found).
> Captures the corrected agenda structure and the one-page recap doc pattern the user asked for.

## Trigger

Use this reference when building or revising a weekly-sync agenda cron or prompt for a guild/collective orchestration agent.

## What Changed This Session

- User corrected the agenda builder: it was treating async action items (A3, A4) as live discussion items and was missing the major Hermes/KB/orchestration updates plus Buzz updates.
- User asked for a **concise one-page recap doc** in `ops-guides/` that the human facilitator can share and reference during the sync.

## Corrected Agenda Structure

1. **Orchestration / KB / agent recap** — human walkthrough, supported by an `ops-guides/` recap doc.
2. **Cross-stack / parallel experiment updates** — e.g., Buzz, other experiments, project demos.
3. **Heads-up on pressing action items only** — flag, do not deep-dive async items.
4. **Live discussion items** — only topics that need synchronous time.
5. **Pending decisions needing ratification** — split compound proposals into separate decisions.
6. **Blockers** — actual stuck items with owners.

## Agenda Rules

- Async-only action items (e.g., Zain confirmations, webhook reviews) must be explicitly marked "async / heads-up only."
- Split compound alignment decisions into at least:
  - **D1:** mission / objectives / commitments
  - **D2:** roles & responsibilities concept
- Include direct links to `wiki/action-items.md`, `wiki/open-questions.md`, and the `ops-guides/` recap doc.
- Read recent Slack history and the recap doc before drafting the agenda.

## Sync Recap Doc Pattern

File name: `ops-guides/YYYY-MM-DD-<topic>-recap.md`

Sections to include:
- **What Changed This Week** — KB restructure, new automations, model/cron changes.
- **What Is Live** — crons, pipelines, 2-way Slack.
- **Current Experiments / Parallel Stacks** — Hermes+Slack vs Buzz, etc.
- **Open Decisions for the Sync** — D1, D2, D3 with proposed answers.
- **Action Items (heads-up only)** — A3, A4, etc.
- **Blockers** — auth, channel membership, dependencies.
- **What to Decide in the Sync** — short checklist.

## Session-Specific Artifacts

- Recap doc created: `/data/knowledge/ops-guides/2026-08-18-hermes-kb-orchestration-recap.md`
- Weekly agenda cron prompt updated: `/data/runtime/hermes/cron/jobs.json` → job `35abcf4d3f5d`
- `wiki/open-questions.md` updated to mark Q3/Q4 as async-only.
- `wiki/action-items.md` action log updated.

## Pitfall: Don't Treat All Open Items as Live Discussion

The orchestrator's default tendency is to list every open action item and question under "Live Discussion." The user corrected this: async items should only get a heads-up, and live time should be reserved for things that actually need the group together.

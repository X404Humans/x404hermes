---
name: x404-meeting-prep
description: Sub-agent that reads the x404 KB and recent Slack, then drafts the next sync agenda and posts it to #meetings.
category: software-development
tags: [x404, sub-agent, meeting-prep, agenda]
---

# x404 Meeting Prep Sub-Agent

## Trigger
- Cron: `x404-weekly-agenda` runs Mondays at 02:00 UTC (two days before the Thursday SGT sync).
- Manual: run `/data/runtime/hermes/scripts/x404-meeting-prep.sh`.

## What it does
1. Determines the next sync date (Wednesday 8pm ET / Thursday 8am SGT; 9am SGT during EST).
2. Creates the next-meeting folder under `sources/meeting notes/` if needed.
3. Reads `wiki/action-items.md`, `wiki/open-questions.md`, `wiki/decisions.md`, and recent Slack history.
4. Writes a proposed-agenda `.md` file.
5. Posts a concise summary + GitHub link to `<#C0B5T66ESGY>`.

## Model
- Uses isolated Hermes profile `x404-meeting-prep`.
- Default model: `qwen3.5` on ollama-cloud.

## Outputs
- `sources/meeting notes/YYYY-MM-DD x404 Humans Found Sync/YYYY-MM-DD x404 Humans Found Sync Proposed Agenda.md`
- Slack message in `<#C0B5T66ESGY>`.

## Failure handling
If the script fails, the cron will post a brief error to `<#C0B5T66ESGY>`.

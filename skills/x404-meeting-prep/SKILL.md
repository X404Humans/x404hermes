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
1. Determines the next sync date:
   - Wednesday 8pm ET / Thursday 8am SGT (Thursday 9am SGT during EST).
   - Folder/filename uses the **Thursday SGT date**.
2. Creates the next-meeting folder under `sources/meeting notes/` if needed.
3. Reads `wiki/action-items.md`, `wiki/open-questions.md`, `wiki/decisions.md`, and recent Slack history.
4. Writes/updates a proposed-agenda `.md` file.
5. Posts a concise summary + correctly formatted GitHub link to `<#C0B5T66ESGY>`.

## Model / profile
- Both the writer sub-agent and the Slack send now run in the **default** Hermes profile.
  - `slack_history` needs the active gateway Slack session (only present in the default profile).
  - `hermes send` needs the gateway's `channel_directory.json` (also only present in the default profile).
- The isolated `x404-meeting-prep` profile is no longer used for this job. Its credentials were already symlinked, but it lacked the live Slack session/channel directory.

## Outputs
- `sources/meeting notes/YYYY-MM-DD x404 Humans Found Sync/YYYY-MM-DD x404 Humans Found Sync Proposed Agenda.md` (YYYY-MM-DD is the Thursday SGT date)
- Slack message in `<#C0B5T66ESGY>`.

## Slack channels read
- `C0AV70KSN8P` (#general)
- `C0B5T66ESGY` (#meetings)
- `C0BPT5G8D45` (#orchestration)
- `C0BQURPSA8M` (#market-research)

There is no `#research-radar` Slack channel. The cron job is named `x404-research-radar` but it delivers to `#market-research`.

## Hyperlink format
- Use Slack `mrkdwn`: `<URL|display>` — URL first, then pipe, then the relative KB folder/file path.
- Correct: `<https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/2026-08-18-hermes-kb-orchestration-recap.md|ops-guides/2026-08-18-hermes-kb-orchestration-recap.md>`
- Do not reverse the URL and display text.
- Do not use bare GitHub URLs as display text.

## Failure handling
If the script fails, the cron will post a brief error to `<#C0B5T66ESGY>`.

---
name: x404-sync-agendas
description: Draft and maintain x404 weekly sync agendas in the KB and Slack for Tony and the group.
category: software-development
tags: [x404, meeting, agenda, slack, kb]
---

# x404 Weekly Sync Agendas

## Scope
Draft, update, and re-share the proposed agenda for each x404 Humans Found weekly sync. Output lives in the KB and a matching Slack post in `#meetings` (`C0B5T66ESGY`).

## Schedule rule
- Target post day is **Monday** of the sync week (3 days before a Thursday SGT sync, 2 days before a Wednesday ET sync).
- Sync is **Wednesday 8pm ET / Thursday 8am SGT** (Thursday 9am SGT during EST).
- Hard guard: **never create or share a proposed agenda for a future sync before the current week’s sync has occurred.**
  - If today is before the scheduled sync day of the current week, do not draft a new agenda — instead, wait until at least Monday of the target week.
  - Example: if today is Wednesday 2026-08-26 and the 2026-08-27 sync has not happened yet, do not create a 2026-09-03 agenda; wait until Monday 2026-08-31 or later.

## File location and date convention
- Markdown: `sources/meeting notes/YYYY-MM-DD x404 Humans Found Sync/YYYY-MM-DD x404 Humans Found Sync Proposed Agenda.md`
- `YYYY-MM-DD` in the **filename** is the **Thursday SGT date**.
- The YAML frontmatter should include two short time fields (`time_et`, `time_sgt`) instead of a single ambiguous `date`. Values end in the exact zone abbreviation including DST where applicable:
  ```yaml
  time_et: Wed 2026-08-26 20:00 EDT
  time_sgt: Thu 2026-08-27 08:00 SGT
  ```
- Do not include a separate `date` field in the frontmatter; the date is implicit in `time_et` and `time_sgt`.
- The file body must also include a visible Date line listing both timezones, e.g.:
  `Thursday 2026-08-27, 08:00 SGT (Wed 2026-08-26 20:00 ET)`
- Never create two agenda files for the same sync (one ET date, one SGT date). If a stale duplicate exists, remove it and update Slack links to the SGT-dated canonical file.
- See `references/date-time-convention.md` for the full convention and rationale.

## Required agenda sections (exact order)
1. **Hermes / KB / Orchestration Recap**
   - Tony walkthrough slot.
   - Link to latest recap ops-guide if one exists.
2. **Buzz Experiment Updates**
3. **Action Items Needing Updates**
4. **Async Action Items (no live discussion needed)**
5. **Open Questions for Live Discussion**
6. **Pending Decisions**
7. **Blockers**

## Hyperlinking rule
- Link every action item, open question, and pending decision that has context in the KB.
- Markdown links: use the relative KB path as display text, linked to the GitHub URL.
  - Example: `[ops-guides/2026-08-17-group-alignment-proposal.md](https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/2026-08-17-group-alignment-proposal.md)`
- Plain items only when genuinely self-explanatory (e.g., "Q6: Who drops meeting notes into the KB?").

## Slack post format
- Header only: `:calendar: _Proposed Agenda — YYYY-MM-DD x404 Sync_`
- **No `[Proposed Agenda]` subject line.**
- Use real newlines, not literal `\n`.
- Use Slack `mrkdwn`: `*bold*`, `_italic_`, bullets, `\u003cURL|text\u003e`.
- Link format must be `\u003chttps://github.com/X404Humans/.../path.md|folder/path.md\u003e` (URL first, display text second).
- Slack message and GitHub markdown must stay in sync: same sections, same order, same hyperlinks.

## When feedback arrives
1. Update the markdown file in `sources/meeting notes/...`.
2. Commit and push.
3. Re-share the updated agenda in Slack as a new message in the main thread (Tony deletes old incorrect ones).
4. Keep Slack message and markdown identical.

## Pitfalls
- Do not create a new ops-guides recap file instead of updating the agenda.
- Do not assume a referenced agenda file is missing just because it is not in the current working tree; automated KB syncs can delete uncommitted files. Check `git log --all --name-only -- "sources/meeting notes/..."` first.
- Do not use Slack `\u003cURL|text\u003e` format inside the KB markdown file; use Markdown `[text](URL)` links there. Use `\u003cURL|text\u003e` only in the Slack post. If the user says raw URLs are showing, check the markdown source for misplaced Slack-style links and for regressions introduced while editing.
- Do not resurrect a deleted/stale duplicate agenda file (e.g., ET-dated) when a canonical SGT-dated file already exists. Update the canonical file and update Slack links to match. See `references/deleted-stale-agendas.md`.
- Do not trust the source file alone when the user reports a rendering issue; verify how GitHub displays the rendered file.
- Do not put async-only items under the live action-items section; place them under **Async Action Items (no live discussion needed)** and only use that section for topics that should be async/reminder-only, not actively discussed live.
- Do not send `\n` literally; use a file or heredoc when calling `hermes send`.
- Do not reverse Slack hyperlink format: it is always `\u003cURL|display\u003e`, never `\u003cdisplay|URL\u003e`.
- The Slack channel for research/market radar is `#market-research` (`C0BQURPSA8M`); there is no `#research-radar` channel. The cron job `x404-research-radar` is wired to `#market-research`.
- The system uses uutils `date`, not GNU `date`. Date math must be done in small timezone-aware steps; do not pass combined strings like `'next wednesday 20:00 America/New_York'` to `date -d`.

## References
- `references/agenda-format.md` — approved format transcript from 2026-08-19.
- `references/date-time-convention.md` — SGT filename + ET/SGT dual time fields.
- `references/markdown-vs-slack-links.md` — correct link syntax for the KB file vs the Slack post.
- `references/deleted-stale-agendas.md` — how to recover or reconcile deleted/stale agenda files.
- `templates/agenda.md` — starter template for future agendas.

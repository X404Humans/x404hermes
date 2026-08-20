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
- Post the agenda on **Monday**.
- Sync is **Wednesday 8pm ET / Thursday 8am SGT** (Thursday 9am SGT during EST).
- Never post next week’s agenda before the current week’s sync has happened.

## File location
- Markdown: `sources/meeting notes/YYYY-MM-DD x404 Humans Found Sync/YYYY-MM-DD x404 Humans Found Sync Proposed Agenda.md`
- Date in filename is the **Thursday SGT date**.

## Required agenda sections (exact order)
1. **Hermes / KB / Orchestration Recap**
   - Tony walkthrough slot.
   - Link to latest recap ops-guide if one exists.
2. **Buzz Experiment Updates**
3. **Action Items Needing Updates**
4. **Async Action Items** (no live discussion needed)
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
- Do not use full GitHub URLs as link display text.
- Do not put async-only items under the live action-items section.
- Do not send `
` literally; use a file or heredoc when calling `hermes send`.

## References
- `references/agenda-format.md` — approved format transcript from 2026-08-19.
- `templates/agenda.md` — starter template for future agendas.

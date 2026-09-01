---
name: x404-alignment-facilitation
description: Facilitate x404 alignment exercises on mission and roles.
tags: [x404, alignment, mission, objectives, commitments, roles, facilitation]
category: software-development
---

# x404 Alignment Facilitation

Use when the x404 Humans Found guild needs to align on mission, objectives, commitments, operating principles, architecture guidelines, or roles & responsibilities.

## Trigger
- User asks Hermes to draft or revise a group alignment proposal.
- A sync agenda flags final ratification of mission/objectives/commitments/R&R as a live discussion item.
- New meeting artifacts (transcripts, Miro exports, screenshots, notes) arrive in `sources/` and the group needs them synthesized into the next draft.

## Prerequisites
1. Read the current canonical alignment doc in `ops-guides/group-alignment-v3.md` (or `wiki/mission-objectives-commitments.md` if already ratified).
2. Read relevant historical alignment exercises under `sources/exercises/`.
3. Read the most recent sync transcripts and notes in `sources/meeting notes/<latest-date>/`.
4. Inspect any Miro screenshots, spreadsheets, or other alignment artifacts in the same folder.
5. Read `wiki/members.md`, `wiki/open-questions.md`, and `wiki/decisions.md` for context.
6. Check for existing agenda files that link to the alignment doc; note stale links.

## Chat-first iteration protocol
1. **Draft internally first**, but do **not** write to the KB until the user approves the approach in chat.
2. Present the proposed structure in-thread, calling out:
   - Mission statement options
   - Real objectives vs. actions vs. key results (KRs are out of scope unless the user says otherwise)
   - Commitments
   - Operating principles vs. architecture guidelines
   - Roles & responsibilities, including humans/agents split where relevant
3. Iterate in chat based on feedback. Only commit/push once the user explicitly says to update the doc.
4. After ratification, move final text to `wiki/mission-objectives-commitments.md` and update `wiki/members.md`, `wiki/decisions.md`, and `wiki/open-questions.md`.

## File hygiene
- The canonical alignment doc should **not** carry a date in its filename once it becomes the working draft (`ops-guides/group-alignment-v3.md`).
- Prior dated drafts go to `ops-guides/archive/` with descriptive names (e.g., `group-alignment-proposal-v1.md`, `group-alignment-v2.md`).
- When moving/renaming, update all internal backlinks, especially in upcoming proposed-agenda files under `sources/meeting notes/`.

## Pitfalls
- Do **not** conflate actions with objectives. Objectives are outcomes; actions are how we achieve them.
- Do **not** add key results unless the user explicitly asks. If KRs are discussed, explicitly mark them as out of scope in the doc when deferring.
- Do **not** assume a Miro screenshot or transcript has been uploaded. If missing, tell the user and ask them to push from their local branch / upload the artifact.
- Do **not** schedule a live working exercise inside the alignment doc unless the user asks. Alignment on mission/objectives/commitments/R&R comes first.
- Do **not** keep stale per-person responsibility bullets under Commitments when there is a full R&R section later.
- Do **not** use dated filenames for the canonical doc. Rename and archive older versions instead.

## References
- `references/alignment-v3-example.md` — example of a complete v3 structure (objectives, actions, commitments, operating principles, architecture guidelines, R&R, open questions).

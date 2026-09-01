# x404 Alignment Exercise — 2026-08-27 Learnings

Session: 2026-08-27 x404 Humans Found Sync  
Sources ingested:
- `sources/meeting notes/2026-08-27 x404 Humans Found Sync/2026 08 27 X404 Humans Found Sync Transcript Granola.md`
- `sources/meeting notes/2026-08-27 x404 Humans Found Sync/2026 08 27 X404 Humans Found Sync Transcript YouTube.md`
- `sources/meeting notes/2026-08-27 x404 Humans Found Sync/2026-08-27 x404 Humans Found Sync Notes Granola.md`
- `sources/meeting notes/2026-08-27 x404 Humans Found Sync/2026-08-27 x404 Humans Found Sync Notes Notion.md`
- `sources/meeting notes/2026-08-27 x404 Humans Found Sync/2026-08-27 x404 Humans Found Sync Miro Screenshot.png`

## Key design decisions for future alignment drafts

### 1. Structure: Objectives, Actions, Key Results

The group wants OKR-style separation but does not want to track key results yet.

- **Objectives** = outcomes, not activities.
  - Improve outcomes for our personal AI projects.
  - Learn new and sharpen existing applied AI skills.
- **Actions** = how we pursue objectives. Can be many-to-many.
  - Weekly working session: share + give hands-on feedback.
  - Ad-hoc breakout slots in 2s or 3s to co-build/unblock.
  - Promote each other’s work through the guild’s collective channels and individual networks.
  - Build lightweight shared experiments that reduce guild friction.
- **Key Results** = acknowledged as a category, explicitly deferred until the group decides to track metrics.

### 2. Mission statement direction

Tony’s preferred wordsmithing:

> x404 Humans Found is a guild of AI builders who support each other’s personal projects and build experiments together in order to become better AI practitioners.

This captures the “so that” Rodolfo requested without drifting into business-building or loose community language.

### 3. Wu-Tang Clan / syndicate model

Tony raised the Wu-Tang Clan as an analogy for x404:
- Members had individual record-label deals and projects.
- The collective (Wu-Tang Clan) collaborated and cross-promoted.
- Collective work amplified individual work; individual success fed back into the collective.
- Applied to x404: a shared publication/syndicate (Medium, Substack) where members publish personal work and the group repromotes it.

This is why “promote each other’s work” appears as a distinct action under Objective 1.

### 4. Operating principles

Keep the list short. Add one new principle:
- Break out into pairs or small groups for co-building; the full group is too large for deep work.

Move “Local-first knowledge” out of operating principles and into `wiki/decisions.md` as a design choice.

### 5. Roles & responsibilities table

Split ownership into Humans and Agents columns:
- Guild Ops / Orchestration: Tony sponsoring; Hermes main orchestrator + meeting sub-agent.
- Research & Intelligence: Karen; research radar sub-agent.
- Build / Execution: Alan; build dispatcher.

### 6. Scope discipline

Do not embed a next alignment exercise (e.g., “Friction → Experiment”) in the same document. The group wants to ratify mission/objectives/commitments/R&R first. A follow-on exercise can be listed as a future action item only.

## Anti-patterns to avoid

- Do not list per-person role bullets under Commitment 3 — the R&R section already covers that.
- Do not make “experiment together” a standalone objective; it is an action that serves learning.
- Do not add long operating-principle lists; keep it tight.
- Do not block on key results; acknowledge and defer.
- Do not assume the latest meeting artifacts are already in the local KB. The 5-minute GitHub poll lags; pull immediately when the user references newly uploaded notes, transcripts, or screenshots.
- Do not fall back to an older meeting’s notes as a substitute for missing recent artifacts. Always pull first.

## Naming and archiving conventions

- Canonical alignment docs live in `ops-guides/` without a date prefix (e.g., `group-alignment-v3.md`).
- Prior drafts are moved to `ops-guides/archive/` with a version suffix (e.g., `archive/group-alignment-proposal-v1.md`, `archive/group-alignment-v2.md`).
- When archiving, update any internal references in the canonical draft to point to the archived versions.
- When the user asks to “move prior drafts to archive,” this means: rename the current file to a versioned name under `ops-guides/archive/`, and create an undated canonical copy in `ops-guides/` for the active draft.

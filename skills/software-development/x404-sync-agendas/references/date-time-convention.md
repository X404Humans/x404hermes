# x404 Agenda Date/Time Convention

Established after the 2026-08-26 confusion where two date labels (New York Wednesday vs Singapore Thursday) were used for the same sync.

## Rule
- **Filename and folder name:** use the **Singapore (SGT) Thursday date**.
  - Example: `sources/meeting notes/2026-08-27 x404 Humans Found Sync/2026-08-27 x404 Humans Found Sync Proposed Agenda.md`
- **File body:** always include **both** the New York (Wednesday) and Singapore (Thursday) date and time.
- **Title/header:** use the SGT Thursday date: `Proposed Agenda — 2026-08-27 x404 Humans Found Sync`.

## Frontmatter format
Use two short, separate YAML fields. Values must end with the exact zone abbreviation, including DST for ET.

```yaml
---
title: "Proposed Agenda — 2026-08-27 x404 Humans Found Sync"
date: 2026-08-27
time_et: Wed 2026-08-26 20:00 EDT
time_sgt: Thu 2026-08-27 08:00 SGT
type: agenda
tags: [agenda, x404, sync]
---
```

- `time_et`: Wednesday date, 20:00, ending in `EDT` (summer) or `EST` (winter).
- `time_sgt`: Thursday date, 08:00, ending in `SGT` (Singapore does not observe DST).

## Prose format
Include a visible date line in the body as well, e.g.:

```markdown
> **Date/Time:** Wednesday 2026-08-26, 20:00 EDT (ET) / Thursday 2026-08-27, 08:00 SGT
```

## Why
The sync is the same event viewed from two timezones. Using the SGT date for the filename avoids duplicate files (e.g., 2026-08-26 vs 2026-08-27) and keeps the KB folder names consistent with the Thursday SGT slot. Including both times in the body prevents confusion when team members reference the agenda from different timezones.

## Pitfalls
- Do not create two agenda files for the same sync (one ET date, one SGT date). If a stale duplicate exists, remove it and update Slack links to the SGT-dated canonical file.
- Do not use a single `time: "... / ..."` value if the user asked for two lines; use the two separate fields above.
- Do not use a multi-line YAML block scalar (`time: |` or `time: |+`) for this; it did not render cleanly in GitHub preview and was rejected.
- Do not trust the source file alone when the user reports a rendering issue; verify how GitHub displays the rendered file.

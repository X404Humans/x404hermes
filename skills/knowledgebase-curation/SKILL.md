---
name: knowledgebase-curation
description: Run deterministic weekly health checks on a markdown knowledgebase, detect orphans, stale pages, broken links, empty pages, unreferenced uploads, and stale action items, and deliver a concise report.
category: software-development
tags: [knowledge-base, curation, lint, markdown, wiki, ops-guides, cron]
---

# Knowledgebase Curation

Run deterministic weekly health checks on a Git-backed markdown knowledgebase (e.g. `/data/knowledge`) so agents and humans can spot drift before it compounds.

## When to use this skill

- A cron job or user asks for a "weekly KB health check".
- You need to verify `wiki/` pages are linked from `wiki/index.md`.
- You need to verify `ops-guides/` are referenced somewhere in the KB.
- You need to detect broken relative markdown links, stale frontmatter, empty pages, or unreferenced uploads.
- The primary isolated sub-agent (`x404-knowledge-curator`) fails or hangs, and you need a reliable fallback.

## Canonical knowledgebase layout

```
/data/knowledge/
  wiki/
    index.md              # root catalog; links to every wiki page via [[name]]
    *.md                  # synthesized pages
  ops-guides/
    *.md                  # operational drafts and runbooks
  sources/uploads/
    *                     # one-off context files (archive/ for old files)
```

## Health-check rules

1. **Orphan wiki pages** — any `.md` in `wiki/` other than `index.md` whose basename is not matched by a `[[name]]` wikilink in `wiki/index.md`.
2. **Empty wiki pages** — any wiki page whose non-empty body lines are fewer than 5.
3. **Stale frontmatter** — any page whose `updated:` frontmatter value is older than 14 days.
4. **Broken relative markdown links** — any `[label](path.md)` where the resolved relative target does not exist. Resolves from the source file's directory (`wiki/` or `ops-guides/`).
5. **Unreferenced ops-guides** — any `ops-guides/*.md` whose filename slug is not found anywhere in the text of wiki or ops-guides files.
6. **Unreferenced uploads** — any regular file in `sources/uploads/` (excluding `archive/`) whose `uploads/<file>` path or filename is not found anywhere in wiki or ops-guides text.
7. **Stale action items** — `wiki/action-items.md` exists and its `updated:` frontmatter is older than 7 days.

## Deterministic script

Use the included `scripts/kb-health-check.py` to run all checks at once. It prints machine-readable JSON to stdout and exits non-zero when actionable issues exist.

```bash
KB_ROOT=/data/knowledge python3 scripts/kb-health-check.py
```

The script is safe to run from any profile because it only reads files.

## Reporting

A curator report should:
- Open with `:x404: *Weekly KB Curator Report*` (or equivalent team header).
- Include one bullet per category that has findings.
- List "Checks passed" categories only when no issues exist, or omit them for brevity.
- Post to the configured Slack channel (e.g. C0B5T66ESGY) and append an entry to `wiki/log.md`.

Do not modify source files during a curation run. Only append to `wiki/log.md` and post the summary.

## Pitfalls

- **Isolated sub-agents can hang or drop mid-stream.** The deterministic script is a reliable fallback; prefer it when a report is overdue or the sub-agent stalls.
- **Slack credentials live in the runtime `.env`, not in the knowledgebase.** A curation script must source `/data/runtime/hermes/.env` before calling `chat.postMessage`.
- **Relative markdown links resolve from the source file's directory.** A link in `ops-guides/foo.md` to `bar.md` resolves to `ops-guides/bar.md`, not `wiki/bar.md`.
- **Wikilinks in `index.md` use `[[slug]]` syntax, not file extensions.** Map them to `slug.md` when checking orphans.
- **Uploads in `archive/` are intentionally excluded** from unreferenced checks.
- **Frontmatter dates use `YYYY-MM-DD`.** Compare against UTC now; do not assume the server's local timezone.
- **Do not treat `log.md` itself as an orphan.** It is typically the append-only log and may not be linked from `index.md` by convention.

## References

- `scripts/kb-health-check.py` — deterministic health check, JSON output, safe read-only fallback.
- `references/x404-runbook.md` — session-specific notes from the x404 Humans Found KB curation run.

## Related skills

- `team-knowledge-base` — set up and operate the underlying Git-backed KB.
- `x404-knowledge-curator` — the original isolated sub-agent skill for x404 (delegate to it when healthy).

## To-consider for future skill curator

The `x404-knowledge-curator` sub-agent skill and the broader class-level `knowledgebase-curation` skill both cover KB health checks. They are intentionally complementary today (one is an isolated agent workflow, one is a deterministic script + reporting pattern). If the x404-specific sub-agent is replaced by the generic pattern, the curator may want to merge them; if it remains a distinct team convention, keep both and cross-link.

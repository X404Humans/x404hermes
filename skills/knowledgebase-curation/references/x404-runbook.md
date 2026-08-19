# x404 Knowledgebase Curation Runbook

Session: 2026-08-19 — x404 weekly KB health check.

## Context

- Knowledgebase root: `/data/knowledge`
- Isolated curator sub-agent: `x404-knowledge-curator` profile (`qwen3.5` on ollama-cloud)
- Slack channel for reports: `C0B5T66ESGY` (#meetings)
- Report header convention: `:x404: *Weekly KB Curator Report*`

## What happened

The script `/data/runtime/hermes/scripts/x404-knowledge-curator.sh` invokes an isolated Hermes profile to perform the weekly health check. On this run the sub-agent loaded files, analyzed the KB, and successfully appended a log entry to `wiki/log.md`, but failed before posting to Slack (the wrapper process was killed mid-stream before completion).

The findings it produced were correct:

| Check | Result |
|-------|--------|
| Orphan wiki pages | `wiki/contradictions.md` not linked from `index.md` |
| Empty wiki pages | `wiki/contradictions.md` has only 2 non-empty body lines (< 5 threshold) |
| Unreferenced ops-guides | `ops-guides/hermes-runtime-migration.md` not referenced anywhere in the KB |
| Broken relative markdown links | none |
| Stale frontmatter (>14 days) | none |
| Unreferenced uploads | none (`manifest.json` is referenced) |
| `action-items.md` updated within 7 days | yes (`updated: 2026-08-18`) |

## Manual verification performed

Because the sub-agent stalled, a deterministic verification pass was run via inline Python over the same KB. The pass confirmed all findings and produced the exact counts above.

## Slack delivery fix

The first `curl` call to `chat.postMessage` returned `not_authed` because the current shell did not source the Hermes runtime `.env`. After running:

```bash
source /data/runtime/hermes/.env
```

the same `curl` succeeded and posted to `C0B5T66ESGY`.

Key detail: `curl` needs `Authorization: Bearer $SLACK_BOT_TOKEN` where `SLACK_BOT_TOKEN` is exported from the runtime `.env`. The `Content-Type` header should include `charset=utf-8` to suppress the `missing_charset` warning.

## Artifacts

- Curator log entry already present in `/data/knowledge/wiki/log.md` (dated 2026-08-19).
- Slack report posted at timestamp `1787107565.810709` in `C0B5T66ESGY`.

## Recommendations captured in the umbrella skill

1. Use `knowledgebase-curation` as the fallback class-level skill.
2. Keep `scripts/kb-health-check.py` under that skill for deterministic read-only checks.
3. When Slack posting from a shell, always `source /data/runtime/hermes/.env` first.
4. Consider making the curator wrapper script run the deterministic Python check as a gate before spawning the heavy sub-agent, so reports are never silently lost on model stalls.

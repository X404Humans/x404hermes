---
name: x404-knowledge-curator
description: Sub-agent that runs weekly lint, cross-link, and staleness checks on the x404 knowledgebase.
category: software-development
tags: [x404, sub-agent, knowledgebase, curator]
---

# x404 Knowledge Curator Sub-Agent

## Trigger
- Cron: `x404-knowledge-curator` runs Sundays at 02:00 UTC.
- Manual: run `/data/runtime/hermes/scripts/x404-knowledge-curator.sh`.

## What it does
1. Reads `wiki/index.md` and lists all `.md` files under `wiki/` and `ops-guides/`.
2. Identifies orphan pages, stale pages (>14 days since update), broken links, and empty pages.
3. Checks `sources/uploads/` for unreferenced files that should be archived.
4. Verifies `wiki/action-items.md` has been updated within the last 7 days.
5. Appends a log entry to `wiki/log.md`.
6. Posts a concise curator report to `<#C0BQKTB2GTZ>`.

## Model
- Uses isolated Hermes profile `x404-knowledge-curator`.
- Default model: `qwen3.5` on ollama-cloud.

## Outputs
- Appended entry in `wiki/log.md`.
- Slack message in `<#C0BQKTB2GTZ>`.

## Constraints
- Does not modify source files.
- Only appends to `wiki/log.md` and posts to Slack.

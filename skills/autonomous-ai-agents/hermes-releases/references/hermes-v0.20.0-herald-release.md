# Hermes Agent v0.20.0 / v2026.8.3 — "Herald Release" Verified Notes

Source: GitHub release page `https://github.com/NousResearch/hermes-agent/releases/tag/v2026.8.3` plus local repo inspection. Release date: **August 3, 2026**. Version string: **v0.20.0**.

## Scale of the release

- ~3,650 commits
- ~1,400 merged PRs
- ~5,200 files changed
- ~559,000 insertions / ~405,000 deletions
- ~1,200 issues closed
- 650+ contributors since v0.19.0

## Headline capabilities

| Area | Detail |
|------|--------|
| **Conversational voice** | Streaming TTS (clause-by-clause), full-duplex barge-in while the agent is speaking/playing, busy-aware silence detection, on-device wake words. Works in CLI voice mode, desktop app, and audio-capable gateway platforms. |
| **A2A v1.0** | Agent-to-Agent protocol: Hermes instances expose versioned agent cards, discover peers, delegate tasks, and avoid loops. |
| **Outbound webhooks** | Signed lifecycle events pushed to external HTTP endpoints for app/workflow integration. |
| **Grounded citations** | New `grounded-citations` skill: research claims matched to actual page text, exact-link citations, fact-checking mode. |
| **Desktop as platform** | Artifacts with sandboxed live preview in a right-rail viewer; plugin SDK; quick-entry; multiple windows. |
| **CLI power commands** | New slash commands including shell mode, `/steer`, `/goal`, `/sessions optimize-storage`. |
| **Context compression overhaul** | Proactive tool-result pruning, per-turn micro-compaction, guaranteed N-user-message tail, progress-aware timeouts, ghost-skill defense, per-model / absolute-token thresholds. |
| **Tool self-recovery** | Truncated terminal output spills to a spill file the agent can read; tools recover from their own failures instead of returning opaque errors. |
| **Performance & health** | Prompt-caching hot-path improvements, cold-start GIL-stall mitigation, dashboard/insights perf, gateway activity watchdog, stall notify, compression timeout, health telemetry. |

## What changed in source subsystems (v2026.7.20 → v2026.8.3)

From `git diff --stat v2026.7.20..v2026.8.3`:

- `agent/` — massive context-compression rewrite (`context_compressor.py`, `conversation_compression.py`), new `relay_llm.py`/`relay_runtime.py`, monitoring package (`agent/monitoring/`), `outbound_webhooks.py`, `message_sanitization.py`, credential-pool and model-metadata work.
- `gateway/` — activity watchdog, stall notifications, restart-after-active-turn deferral, Discord auto-thread / relay fixes, SimpleX channel enumeration.
- `tui_gateway/` — branch-seed batching, live-turn finalization, delegate preservation across reaping.
- `desktop/` — live-tail vocabulary, right-pane / pet perf, adaptive stream flush, wake indicator, tab reload, multi-window groundwork.
- `agent/auxiliary_client.py` — large refactor (2,065 line diff) for auxiliary model routing.
- `cli.py` / `hermes_cli/` — new slash commands, personality/SOUL handling, config/doctor additions.

## Local install check

In the environment where this was verified (Tony's x404 runtime), the running version before update was:

```
Hermes Agent v0.19.0 (2026.7.20) · upstream f0c0c986 · local 3ef6bbd2 (+16509 carried commits)
Install directory: /data/.hermes/hermes-agent
Install method: git
```

`hermes update` was available and would move it to v0.20.0 / v2026.8.3.

## Upgrade commands

```bash
# Verify
hermes --version
hermes doctor

# Backup state
# cp -r ~/.hermes ~/.hermes.backup.$(date +%Y%m%d)

# Update (restarts gateway, kills active agents)
hermes update

# Restart gateway if needed
hermes gateway restart
```

Test in an isolated profile first:

```bash
hermes profile create v20-test
hermes profile use v20-test
hermes update
```

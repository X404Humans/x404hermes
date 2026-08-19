# x404 Orchestration Agent — Session Reference

> Source session: 2026-08-17 with Tony (x404 Humans Found).
> This reference captures the specific decisions, channel mappings, and model recommendations from that build.

## Group Context

- **Collective:** x404 Humans Found
- **Agent identity:** x404hermes / hermes@x404humansfound.com
- **KB:** `/data/knowledge` synced to `X404Humans/x404knowledge` (private) every 5 minutes via polling
- **Runtime:** `/data/runtime/hermes` synced to `X404Humans/x404hermes` (public) daily

## Slack Channel Mapping

| Channel | ID | Purpose |
|---|---|---|
| `#general` | C0AV70KSN8P | Human coordination, async feedback |
| `#orchestration` | C0BPT5G8D45 | Building the orchestration agent itself |
| `#meetings` | C0B5T66ESGY | Agendas, meeting digests, action items, decisions |
| `#research-radar` | C0BQURPSA8M | Market/intelligence sub-agent briefs |
| `#buzz` | C0BQ6JV48AW | Buzz-by-Block experiments (Jai) |
| `#cloud-computer` | C0BKAQRT7HA | Zain / Pommon cloud computer |
| `#selat` | C0BKDSQRYES | Karen / SELAT |
| `#enter-the-claw` | C0BK0F9CTE3 | Tony / Enter the Claw |

## Member Slack IDs

| ID | Name |
|---|---|
| U0B022WUU4T | Tony |
| U0B052FQE8M | Zain |
| U0BHK7SNYMB | Karen |
| U0B12NGU97A | Jai |
| U0B06CLVDML | Kishore |
| U0AV70ZAH55 | Rodolfo |
| U0B12NHFGKS | Alan |
| U0B0238HAMR | James (inactive/ghosted) |
| U0BFXG8AFK5 | Hermes |

## Decisions from Session

- MVP meeting-note digest: 24-hour target.
- Research radar moved to dedicated sub-agent in `#research-radar` immediately after MVP.
- Slack channel mapping: reuse `#C0B5T66ESGY` for meetings content; create/use `#C0BQURPSA8M` for research radar.
- Auto-assign action-item owners by default.
- James effectively inactive; no R&R assigned.
- Keep `about-me.md`, `KNOWLEDGE.md`, and `sources/uploads/manifest.json` untouched until Zain confirms cloud-computer dependencies.
- Google Docs / Miro live integrations moved to parking lot.
- Email send capability moved to long-term / parking lot.

## Model Recommendations

| Sub-agent | Recommended model | Rationale |
|---|---|---|
| Orchestrator | kimi-k2.7-code | Tool use, coding, long context |
| Meeting Digest | kimi-k2.7-code / qwen3-235b-a22b | Long-context summarization |
| Research Radar | qwen3-235b-a22b | Cheap, strong synthesis |
| Knowledge Curator | qwen3-235b-a22b | Structural checks |
| Build Dispatcher | kimi-k2.7-code / claude-sonnet-4 | Complex coding and delegation |

## Cron Jobs Created

- `x404-meeting-digest` (ID `ebb14332592f`) — weekdays 09:00 UTC
- `x404-research-radar` (ID `11dca57177fc`) — weekdays 13:00 UTC → `#C0BQURPSA8M`

## Files Created

- `/data/knowledge/x404-agent-identity.md`
- `/data/knowledge/KB-SCHEMA.md`
- `/data/knowledge/wiki/{index,log,members,projects,action-items,decisions,open-questions,mission-objectives-commitments}.md`
- `/data/knowledge/ops-guides/{2026-08-17-orchestration-agent-prd,2026-08-17-group-alignment-proposal,2026-08-17-knowledgebase-cleanup-proposal,cloud-computer-file-dependencies}.md`
- `/data/runtime/hermes/scripts/meeting-digest.sh`

## Open Items

- Zain to confirm cloud-computer file dependencies.
- Zain/Tony to review KB sync webhook upgrade (`ops-guides/vps-admin-webhook-request.md`).
- Group async feedback on proposed mission/objectives/commitments/R&R.

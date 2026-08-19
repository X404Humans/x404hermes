# Slack channel routing for x404

## Core channels

| Channel | ID | Use for |
|---|---|---|
| `<#C0AV70KSN8P>` | C0AV70KSN8P | Human coordination, announcements, async votes |
| `<#C0B5T66ESGY>` | C0B5T66ESGY | Agendas, meeting digests, action items, decisions, status |
| `<#C0BQURPSA8M>` | C0BQURPSA8M | Daily AI infra/model-release brief |
| `<#C0BPT5G8D45>` (#orchestration / x404-hermes) | C0BPT5G8D45 | Building the agent: architecture, runtime, ops-guides about Hermes |
| `<#C0B06C8MHJS>` | C0B06C8MHJS | Off-topic / noise |

## Existing project channels

| Channel | ID | Project |
|---|---|---|
| `<#C0BQ6JV48AW>` | C0BQ6JV48AW | Buzz (by Block) experiments — Jai |
| `<#C0BKAQRT7HA>` | C0BKAQRT7HA | Zain’s Pommon cloud computer |
| `<#C0BKDSQRYES>` | C0BKDSQRYES | Karen’s SELAT venture |
| `<#C0BK0F9CTE3>` | C0BK0F9CTE3 | Tony’s Enter the Claw |

## Routing rules

- Meeting/action/decision/status updates → `<#C0B5T66ESGY>`
- Agent architecture/ops-guides about Hermes → `<#C0BPT5G8D45>`
- Group alignment/decisions → `<#C0B5T66ESGY>` or `<#C0AV70KSN8P>`
- Project-specific synthesis → the project’s channel
- Research radar briefs → `<#C0BQURPSA8M>`

## Channel membership check

Before wiring a sub-agent or cron to deliver to a channel, confirm `@Hermes` is a member. A `not_in_channel` Slack delivery error means the human needs to invite the bot. Ask them, do not guess at workarounds.

## Do not create by default

- `#agent-readouts` — covered by `<#C0B5T66ESGY>`
- `#build-track` — use project-specific channels when builds start
- `#knowledge-wiki` — route by content instead

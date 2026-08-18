# x404 Humans Found — Team Knowledge Base Context

> Condensed operating context for the x404 Humans Found knowledge base. Reference this when the team asks about KB structure, sync, member roles, or agent identity.

## Repos and sync

| Path | GitHub repo | Sync |
|---|---|---|
| `/data/knowledge` | `github.com/X404Humans/x404knowledge` (private) | Every 5 minutes via `x404hermes` GitHub account |
| `/data/runtime/hermes` | `github.com/X404Humans/x404hermes` (public) | Daily via `x404hermes` GitHub account |

## Agent identity

- **GitHub:** `x404hermes`
- **Email:** `hermes@x404humansfound.com`
- **Slack:** `@x404 Hermes` (`U0BFXG8AFK5`)

## Communication channels

- **Slack workspace:** primary human + agent coordination surface.
- Proposed agent channels:
  - `#agent-readouts` — meeting digests, status, decisions
  - `#research-radar` — market/AI infra intelligence
  - `#build-track` — coding/build sub-agent coordination

## Members and roles (living)

| Member | Role |
|---|---|
| Zain | Infrastructure / Agent Platform Owner |
| Tony | Growth / IT Ops / Orchestration Sponsor |
| Karen | Market Intelligence / SELAT Liaison |
| Jai | Architect / Shared Infrastructure / Buzz experiments |
| Kishore | Venture Builder / Snapster / Enter the Claw |
| Rodolfo | Venture Builder / Snapster / Enter the Claw |
| Alan | Studio/Agency Execution |
| James | Tooling / Workflows |

## Current projects

- **Hermes / x404-agent** — chief-of-staff orchestration agent in Slack
- **Buzz** — open-source agent-native comms platform (parallel experiment track)
- **Snapster** — peer-to-peer resale agent
- **Enter the Claw** — live agent-improv entertainment platform

## Knowledge base structure

```
/data/knowledge/
  KB-SCHEMA.md
  x404-agent-identity.md
  ops-guides/           # drafts awaiting human sign-off
  sources/
    meeting notes/      # immutable transcripts/summaries
    exercises/          # Miro / Google Docs exports
    uploads/            # misc one-off files
  wiki/                 # agent-synthesized pages
```

## Group alignment direction

- Primary purpose: **guild of AI builders supporting each other’s personal projects**.
- Secondary purpose: **build experiments together** that serve the guild.
- Knowledge approach: **Carpathian / Karpathy-style local-first KB** on the VPS, not MCP-connected distributed tools.
- Agent approach: **lean orchestrator + specialized sub-agents**.

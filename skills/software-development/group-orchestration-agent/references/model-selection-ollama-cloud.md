# Model Selection on ollama-cloud

## Context

When the orchestration runtime is constrained to ollama-cloud models, recommend only from the list at https://ollama.com/search?c=cloud.

## Recommended defaults

| Agent type | Model | Why |
|---|---|---|
| Main orchestrator | `kimi-k2.7-code` | Strong coding, tool use, long context for multi-turn Slack coordination. |
| Research / digest / curator | `qwen3.5` | Cheaper, good long-context summarization and structured extraction. |
| Build dispatcher | `kimi-k2.7-code` | Reserved for future coding/delegation work; use the strongest available. |

## What to avoid

- Recommending OpenRouter-only models (e.g., `qwen3.7-flash`, `qwen3-235b-a22b`) unless the runtime has OpenRouter configured.
- Recommending Anthropic Claude unless the runtime has Anthropic access.

## Process

1. Ask or check what provider/model the runtime currently uses.
2. List candidate models from that provider only.
3. Match model to task: cheapest adequate model for batch/structural tasks; strongest model for coding/judgment.
4. Get user confirmation before changing the main orchestrator model.

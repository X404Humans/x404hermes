# Model constraints for x404 agents

All x404 agents run on **ollama-cloud** models today. Available models are listed at https://ollama.com/search?c=cloud.

## Current recommendations

| Agent | Model | Why |
|---|---|---|
| Main orchestrator | kimi-k2.7-code | Proven in this runtime; strong coding, tool use, long context |
| Research Radar | qwen3.5 | Text-only research/synthesis; cheaper than kimi for daily cron |
| Meeting Digest | qwen3.5 | Long-context summarization and structured extraction |
| Knowledge Curator | qwen3.5 | Low-cost structural lint work |
| Build Dispatcher | kimi-k2.7-code | Future-only; coding and complex tool use |

## If OpenRouter or other providers become available

- qwen3.7-flash is Tony’s NanoClaw default; strong value for text-only tasks.
- claude-sonnet-4 is best for complex coding and nuanced judgment.
- deepseek-v3 / deepseek-flash are excellent for text-only reasoning and cheap, but not multimodal.

Always confirm provider/model availability with the user before switching.

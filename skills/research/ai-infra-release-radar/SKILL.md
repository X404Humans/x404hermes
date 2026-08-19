---
name: ai-infra-release-radar
description: "Daily AI infrastructure and model-release radar. Pulls recent high-signal tweets via SELAT's native Twitter advanced search, dedupes and ranks by engagement, extracts model/company/release signals, and cross-checks with web search. Designed for VC/AI-infra scouts and the x402 Humans community."
version: 1.1.0
metadata:
  hermes:
    tags: [ai-infra, model-releases, vc, scouting, selat, twitter, x402-humans]
    related_skills: [selat-agent-payments, vc-ai-infra-scout]
---

# AI Infra & Model Release Radar

Use this skill to run a daily scan of high-signal AI infrastructure and model-release chatter on X/Twitter, then synthesize it into a brief.

## When to use

- Daily morning radar for AI infra, model releases, GPU/data-center, and agentic infrastructure signals.
- Building a deal or research brief for the x402 Humans group.
- Cross-checking a hot claim with web search before sharing.

## Required tools

- SELAT CLI installed and wallet funded (`selat doctor` green).
- Circle agent wallet authenticated.
- Web search toolset enabled.

## Data source

Use SELAT's native X/Twitter advanced search endpoint, **not** Apify:

- Endpoint: `GET https://catalog.selat.ai/twitter/tweet/advanced_search`
- Required query param: `query` (use Twitter/X advanced search syntax)
- Optional query params: `queryType`, `cursor`
- Price: **$0.001/call** on Base (`eip155:8453`)
- Rail: `GatewayWalletBatched`
- Returns 20 tweets per call in `response.tweets`.

## Run the radar

```bash
export PATH="$HOME/.local/share/selat/node_modules/.bin:$PATH"

selat run "https://catalog.selat.ai/twitter/tweet/advanced_search" \
  --param query="new AI model min_retweets:10 lang:en" --json

selat run "https://catalog.selat.ai/twitter/tweet/advanced_search" \
  --param query="model release AI min_retweets:10 lang:en" --json

selat run "https://catalog.selat.ai/twitter/tweet/advanced_search" \
  --param query="AI infrastructure min_retweets:5 lang:en" --json

selat run "https://catalog.selat.ai/twitter/tweet/advanced_search" \
  --param query="GPU data center AI min_retweets:5 lang:en" --json

selat run "https://catalog.selat.ai/twitter/tweet/advanced_search" \
  --param query="(Kimi OR Gemini OR Claude OR GPT OR Llama) release min_retweets:20 lang:en" --json

selat run "https://catalog.selat.ai/twitter/tweet/advanced_search" \
  --param query="agentic payments OR x402 OR MPP min_retweets:5 lang:en" --json
```

## Synthesis rules

1. Parse `response.tweets` from each JSON result. Each tweet has `id`, `url`, `text`, `createdAt`, `likeCount`, `retweetCount`, `replyCount`, `quoteCount`, `viewCount`, and `author.userName`/`author.name`.
2. Filter to roughly the last 24 hours, then deduplicate by tweet id or >80% text overlap.
3. Rank by: `likeCount + 2*retweetCount + 0.5*replyCount`, recency-weighted.
4. Extract per item:
   - **Signal type**: model release, infra deal, funding, product launch, research paper.
   - **Entity**: company/lab name and handle.
   - **Model/product name** if applicable.
   - **Key claim** in one sentence.
   - **Engagement**: likes/retweets/replies.
   - **Link** to tweet and any expanded URL.
5. Cross-check top 3–5 claims with web search. Mark as `verified`, `partial`, or `unverified`.
6. Output a markdown brief titled `AI Infra & Model Release Radar — YYYY-MM-DD`.

## Output format

```markdown
# AI Infra & Model Release Radar — 2026-07-25

## Top signals
1. **IREN signs $2.8B AI Cloud contracts** — @IREN_Ltd
   - Signal: infra deal | Engagement: 3.7k likes / 524 RTs
   - Claim: $2.8B multi-year AI Cloud contracts; 2026 ARR target raised to >$4.0B.
   - Source: https://x.com/IREN_Ltd/status/...
   - Verification: [verified via press release]

2. **Moonshot Kimi K3 released** — @GlobalMktObserv + @BrianRoemmele
   - Signal: model release | Engagement: 365 likes / 114 RTs
   - Claim: 2.8T-parameter MoE, 1M-token context, rivals top US systems.
   - Verification: [partial — web sources confirm K3 announcement]

...

## Themes today
- AI data-center/cloud contract momentum
- Chinese model competition (Kimi K3)
- Frontier model release delays (Gemini 3.5 Pro)

## Follow-ups
- [ ] Verify IREN contract terms and customer names.
- [ ] Check if Kimi K3 weights are actually open.
- [ ] Map other AI Cloud infra cos with similar contract scale.
```

## Cost

- SELAT native Twitter search: **$0.001/call** (20 tweets/call on Base, no prepaid token needed).
- Web search: per-call charges from Exa/Tavily/Brave if used for verification.

## After the run

Append the current spend report to the brief so the reader sees cost and wallet state:

```bash
export PATH="$HOME/.local/share/selat/node_modules/.bin:$PATH"
selat spend
```

Include the output verbatim under a `## Spend report` section at the end of the brief.

## Troubleshooting

- If a search returns no tweets, try broadening the query or lowering `min_retweets`.
- If all native searches fail, fall back to web-search-only mode and still append `selat spend`.
- If `selat doctor` reports `not authenticated`, the native endpoint will fail at the signing step; the cron job cannot ask for OTPs, so it should fall back to web search and report the auth state.

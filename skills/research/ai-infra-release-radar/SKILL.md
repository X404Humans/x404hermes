---
name: ai-infra-release-radar
description: "Daily AI infrastructure and model-release radar. Pulls recent high-signal tweets via SELAT/Apify, dedupes and ranks by engagement, extracts model/company/release signals, and cross-checks with web search. Designed for VC/AI-infra scouts and the x402 Humans community."
version: 1.0.0
metadata:
  hermes:
    tags: [ai-infra, model-releases, vc, scouting, selat, twitter, apify, x402-humans]
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
- Apify prepaid token available (first call buys ~$1.05 on Base; reuses until expiry).
- Web search toolset enabled.

## Run the radar

```bash
export PATH="$HOME/.local/share/selat/node_modules/.bin:$PATH"

selat run "use apidojo twitter scraper lite" \
  --input '{
    "searchTerms":[
      "new AI model min_retweets:10 lang:en",
      "model release AI min_retweets:10 lang:en",
      "AI infrastructure min_retweets:5 lang:en",
      "GPU data center AI min_retweets:5 lang:en",
      "(Kimi OR Gemini OR Claude OR GPT OR Llama) release min_retweets:20 lang:en"
    ],
    "maxItems":100,
    "sort":"Latest",
    "tweetLanguage":"en"
  }'
```

## Synthesis rules

1. Deduplicate by tweet text similarity (same URL, same model name, or >80% text overlap).
2. Rank by: `likeCount + 2*retweetCount + 0.5*replyCount`, recency-weighted.
3. Extract per item:
   - **Signal type**: model release, infra deal, funding, product launch, research paper.
   - **Entity**: company/lab name and handle.
   - **Model/product name** if applicable.
   - **Key claim** in one sentence.
   - **Engagement**: likes/retweets/replies.
   - **Link** to tweet and any expanded URL.
4. Cross-check top 3–5 claims with web search. Mark as `verified`, `partial`, or `unverified`.
5. Output a markdown brief titled `AI Infra & Model Release Radar — YYYY-MM-DD`.

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

- Apify: ~$0.01–$0.03 per run (consumes prepaid token).
- Web search: per-call charges from Exa/Tavily/Brave if used for verification.

## After the run

Append the current spend report to the brief so the reader sees cost and wallet state:

```bash
export PATH="$HOME/.local/share/selat/node_modules/.bin:$PATH"
selat spend
```

Include the output verbatim under a `## Spend report` section at the end of the brief.

## Troubleshooting

- If `[]` is returned, check the Apify token balance: `selat spend`.
- If the actor returns irrelevant results, narrow `searchTerms` further or add `min_retweets`.
- For downtime of the Apify actor, fall back to AIsa/Twitter or web search-only mode.

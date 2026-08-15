# SELAT provider reliability notes — July 2026

Condensed findings from real paid runs of `vc-ai-infra-scout` on 2026-07-24.

## Working endpoints / rails

| Provider | Endpoint pattern | Rail | Result | Notes |
|---|---|---|---|---|
| Tavily | `x402.tavily.com/search` | routed-x402 | ✅ 200 | Both Hacker News and LinkedIn scoped searches worked. |
| Parallel | `parallelmpp.dev/api/search` | routed-mpp | ✅ 200 | Product Hunt discovery worked on both runs. |
| Exa | `api.exa.ai/search` | routed-mpp | ✅ 200 | Web launch/funding context worked. |
| Apollo (people/org) | `apollo.mpp.paywithlocus.com/apollo/*` | routed-mpp | ✅ 200 | People-search and org-enrichment both returned data. |

## Broken / unreliable endpoints

| Provider | Endpoint | Rail | Result | Notes |
|---|---|---|---|---|
| AIsa (Twitter/X advanced search) | `api.aisa.one/apis/v2/twitter/tweet/advanced_search` | routed-x402 | ❌ 502 `{"error":"terminated"}` | Failed on all 3 paid calls in run 1. Failed again on the agentic-payments fundraising query in run 2. Appears systematically unreliable for machine payments right now, even though verification probes succeed. |

When the AIsa/Twitter lens fails, synthesize from the remaining sources (HN, Product Hunt, Exa web, LinkedIn, Apollo). Do not retry blindly — the failure is provider-side and persists across runs.

## Payment behavior on failure

- The x402 quote was accepted and the payment was signed for each failed AIsa call.
- Each failed call was quoted at $0.0022.
- The gateway-history file records `outcome: "failed"` and `httpStatus: 502`.
- Total failed-attempt value across both runs: $0.0132 (6 failed calls).

## Useful post-run commands

```bash
# payment transcript
~/.local/state/selat-pay/gateway-history.jsonl

# verify receipt (pre-run dry-run)
~/.config/selat/skills/<skill-name>/.selat/verify-receipt.json

# summary spend
selat history
selat spend
selat budget
```

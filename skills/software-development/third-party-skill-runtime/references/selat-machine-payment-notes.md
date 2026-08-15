# SELAT machine-payment runtime notes

Session-specific quirks and workarounds observed while running SELAT skills in headless/agent environments.

## Headless Circle CLI login

The Circle CLI requires OTP via email and its session state is tied to how you run it. In a non-TTY shell, the two-step flow works but you must capture the request ID between commands.

```bash
export CIRCLE_ACCEPT_TERMS=1
export PATH="$HOME/.local/share/selat/node_modules/.bin:$PATH"

circle wallet login <email> --type agent --init
# -> prints request ID and emails a code
circle wallet login --request <request-id> --otp <code>
circle wallet status --output json
```

Gotcha: the `--chain` flag is required for `circle wallet list` and `circle wallet balance` in newer CLI builds.

## `selat init` wallet selection without a TTY

`selat init` prompts "Wallet to use [1-5/new]" and refuses to read stdin when not connected to a TTY. Use `script` to create a pseudo-terminal and pipe the numeric choice:

```bash
printf '1\n' | script -q -c 'selat init' /dev/null
```

Pick the number matching the wallet with a Gateway balance (shown earlier by `circle wallet list --chain BASE`).

## Endpoint reliability for machine payments

Paid SELAT skills route each step to a different provider and payment rail. Not all endpoints are equally reliable, even after the quote is accepted and the payment is signed.

### AIsa (Twitter/X advanced_search) — HTTP 502 "terminated"

Observed 2026-07-24 while running `vc-ai-infra-scout`:

- Steps 4, 5, and 7 (all AIsa `api.aisa.one` calls paid via direct x402) returned `status=502` with body `{"error":"terminated"}`.
- The payment was quoted and signed successfully; the failure happened after the paid request was submitted.
- Parallel/Tavily/Apollo steps using routed-mpp or routed-x402 completed with HTTP 200.

What this means:

- The AIsa x402 endpoint is currently unstable or misconfigured for machine-payment traffic, even though verification probes succeed.
- This is a provider-side issue, not a wallet/auth/funding issue.

What to do when you see it:

1. Confirm the failure is isolated to one provider by checking the per-step summary at the end of `selat skill run`.
2. Re-run only the failed step(s) once to rule out a transient blip.
3. If the 502 persists, treat the AIsa/Twitter lens as unavailable and synthesize results from the other successful lenses.
4. Check the skill's homepage/SELAT registry for an updated version before future runs.

Receipt/transcript location: `~/.local/state/selat-pay/gateway-history.jsonl`.

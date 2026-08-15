# SELAT local install recipe

A concrete worked example from a live session installing the ClawHub skill `selat-dev/skills/vc-ai-infra-scout`.

## Environment

- Host: Linux, Node installed system-wide at `/usr/bin/node`, npm prefix `/usr`.
- Symptom: `npm install -g @selat-ai/selat-cli` fails with `ENOENT: no such file or directory, mkdir '/usr/lib/node_modules/@selat-ai'` because the current user lacks write permission.

## Fix

Install into a user-owned directory and prepend that to PATH:

```bash
mkdir -p ~/.local/share/selat
cd ~/.local/share/selat
npm install @selat-ai/selat-cli
export PATH="$HOME/.local/share/selat/node_modules/.bin:$PATH"
selat --version   # 0.14.1
```

## Verification command

```bash
selat skill install vc-ai-infra-scout
SELAT_ROUTER_URL=https://router.selat.ai selat skill verify ~/.config/selat/skills/vc-ai-infra-scout
```

## Actual dry-run output (2026-07-24)

All steps quoted within cap:

| step | provider | rail | quoted | cap |
|------|----------|------|--------|-----|
| 1 | Tavily HN | routed-x402 | $0.0105 | $0.02 |
| 2 | Parallel | routed-mpp | $0.0105 | $0.05 |
| 3 | Exa | routed-mpp | $0.00735 | $0.05 |
| 4 | AIsa Twitter | routed-x402 | $0.0022 | $0.05 |
| 5 | AIsa Twitter raises | routed-x402 | $0.0022 | $0.05 |
| 6 | Tavily LinkedIn | routed-x402 | $0.0105 | $0.02 |
| 7 | AIsa investor thesis | routed-x402 | $0.0022 | $0.05 |
| 8 | Apollo people | routed-mpp | $0.00525 | $0.05 |
| 9 | Apollo org enrichment | routed-mpp | $0.0084 | $0.05 |

Total quoted: ~$0.049 (hard cap $0.40).

## Next step for paid run

Only after user opt-in:

```bash
selat init
selat fund
selat doctor
selat skill run vc-ai-infra-scout --thesis "..."
```

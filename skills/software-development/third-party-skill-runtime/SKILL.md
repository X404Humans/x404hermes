---
name: third-party-skill-runtime
description: "Run Hermes hub skills that depend on external CLIs, npm packages, or paid agent-to-agent runtimes. Use when installing or executing a third-party skill from ClawHub/OpenClaw that lists binary requirements (e.g. selat, npm) or per-call payment rails, especially after global install fails due to permissions."
version: 1.0.1
author: Hermes Agent
metadata:
  hermes:
    tags: [skills, hub, openclaw, selat, npm, cli, runtime, troubleshooting]
    related_skills: [hermes-agent]
---

# third-party-skill-runtime

Hermes hub skills are markdown manifests, but many of them delegate the actual work to an external CLI (often published on npm) or to a paid agent-to-agent runtime like SELAT. This skill covers the whole lifecycle: inspect → install the skill → satisfy its binary dependencies → run a free dry-run/verify → execute a paid or authenticated run.

## When to use

- A skill's `SKILL.md` mentions `npm install -g ...` or a binary like `selat`.
- `hermes skills install <id>` succeeded, but running the skill requires a CLI that isn't on PATH.
- Global npm install fails with `EACCES` / `ENOENT` because `/usr/lib/node_modules` is not writable.
- The skill makes real paid API calls and requires a dry-run + user opt-in before spending.

## Workflow

### 1. Inspect before installing

```bash
hermes skills inspect <id>
```

Read the preview for:
- required binaries (`selat`, `npm`, etc.)
- npm package names
- required env vars
- payment rails / cost caps
- the dry-run command, if any

### 2. Install the skill

```bash
hermes skills install <id> --yes
hermes skills list | grep <id>
```

### 3. Install the external CLI without root access

Many skills tell you to `npm install -g <pkg>`. If the current user cannot write to the global npm prefix (`/usr/lib/node_modules` on Linux systems with system Node), do **not** use `sudo npm`. Instead install into a user-local directory and add it to PATH for the session:

```bash
mkdir -p ~/.local/share/<tool>
cd ~/.local/share/<tool>
npm install <pkg>
export PATH="$HOME/.local/share/<tool>/node_modules/.bin:$PATH"
<binary> --version
```

Example for SELAT:

```bash
mkdir -p ~/.local/share/selat
cd ~/.local/share/selat
npm install @selat-ai/selat-cli
export PATH="$HOME/.local/share/selat/node_modules/.bin:$PATH"
selat --version
```

For persistence across sessions, add the `export PATH` line to `~/.bashrc`, `~/.zshrc`, or the shell profile used by Hermes.

### 4. Dry-run / verify before any paid or stateful action

Most payment-rail skills expose a verification or probe command. Run it first and show the user the quoted prices.

For SELAT skills:

```bash
selat skill install <skill-name>
selat skill verify ~/.config/selat/skills/<skill-name>
```

If the skill docs mention `SELAT_ROUTER_URL`, prefix the verify command:

```bash
SELAT_ROUTER_URL=https://router.selat.ai selat skill verify ~/.config/selat/skills/<skill-name>
```

The output lists each step's provider, rail, quoted price, and cap. Show this to the user and wait for explicit OK before wallet setup or paid execution.

### 5. Wallet setup (only after user opt-in)

If the skill uses SELAT or another self-custody wallet flow:

- Never ask for, paste, or handle a private key.
- Let the CLI handle wallet creation/auth.

```bash
selat init     # creates Circle Agent Wallet
selat fund     # user deposits USDC
selat doctor   # verify wallet + balance
```

**Non-interactive / TTY-less environments:**

The Circle CLI login and `selat init` wallet selection both prompt for input. In a headless agent shell you can still complete them, but you need two workarounds:

1. **Circle OTP login in two steps.** The CLI emails a code. First get a request ID, then complete it:

   ```bash
   export CIRCLE_ACCEPT_TERMS=1
   circle wallet login <email> --type agent --init
   # CLI prints: circle wallet login --request <request-id> --otp <code>
   # Ask the user for the emailed 6-digit code, then:
   circle wallet login --request <request-id> --otp <code>
   circle wallet status --output json
   ```

2. **Circle session must be established in a persistent interactive shell.** The two-step OTP flow writes session state. If you run the OTP completion and `selat init` as separate non-PTY commands, `selat init` may report "not logged in" even though the OTP step returned success. Use a PTY-capable invocation for the login/status commands, and verify with `circle wallet status --output json` before moving on. Once the status command confirms a valid session, proceed to `selat init`.

3. **`selat init` wallet selection.** When `selat init` prompts "Wallet to use [1-5/new]" but stdin is not a TTY, use `script` to provide a fake TTY and pipe the choice:

   ```bash
   printf '1\n' | script -q -c 'selat init' /dev/null
   ```

   Pick the wallet number shown by `circle wallet list --chain BASE` (SELAT defaults to paying on the funded chain; `--chain` is required for most `circle wallet` subcommands).

### 6. Execute the paid run

Use the exact command form from the skill's `SKILL.md`, filling required parameters first.

```bash
selat skill run <skill-name> --thesis "..." --twitterQuery "..."
```

After the run, review the per-step summary. If one provider returns 502/terminated while others succeed, treat that provider as temporarily unavailable and synthesize from the working lenses. See `references/selat-machine-payment-notes.md` for a concrete example.

## Pitfalls

- **Global npm install fails silently or with ENOENT.** Default to user-local install; do not escalate to `sudo npm`.
- **PATH not updated in the same shell.** `export PATH` must happen in the same terminal session that runs the CLI. Hermes tool calls share environment within a session, but a fresh session needs the export again or a profile entry.
- **Skipping the dry run.** Always run verify/probe before paid execution. If the skill has no explicit dry-run command, run the cheapest invocation and confirm output before full parameters.
- **Forgetting the skill has real cost.** Quote the per-step caps and total cap to the user before `selat init`/`selat fund`.
- **Confusing skill install locations.** Hermes installs skills under `$HERMES_HOME/skills/`. SELAT installs its own copy under `~/.config/selat/skills/`. The two are independent; use the SELAT path for `selat skill verify`.
- **Circle CLI `--chain` flag.** Most `circle wallet` subcommands require `--chain BASE` (or the chain the wallet was created on) in current builds.
- **TTY prompts in headless shells.** `selat init` and `circle wallet login` both prompt; use the two-step OTP and `script` workarounds documented above.
- **Mixed endpoint reliability in paid runs.** A successful quote does not guarantee the upstream API will return 200. Capture the pattern and work around it rather than retrying blindly.

## Where to look

- Hermes skill docs / install state: `hermes skills list`, `hermes skills inspect <id>`
- Skill files: `$HERMES_HOME/skills/<name>/SKILL.md`
- SELAT skill files: `~/.config/selat/skills/<name>/`
- SELAT verification receipt: `~/.config/selat/skills/<name>/.selat/verify-receipt.json`
- Payment history / failure transcript: `~/.local/state/selat-pay/gateway-history.jsonl`

## References

- Local npm install recipe and dry-run output: `references/selat-local-install-recipe.md`
- Headless Circle login, TTY workarounds, and endpoint reliability notes: `references/selat-machine-payment-notes.md`
- Real-run provider reliability matrix (working vs. broken endpoints): `references/selat-provider-reliability-2026-07.md`

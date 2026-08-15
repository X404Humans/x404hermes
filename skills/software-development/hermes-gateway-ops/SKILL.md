---
name: hermes-gateway-ops
description: "Operate, migrate, and harden the Hermes messaging gateway (systemd service, venv selection, platform plugins, auto-recovery)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, gateway, slack, systemd, migration, ops, devops, messaging]
    related_skills: [hermes-agent, hermes-slack-gateway-model-scope]
---

# Hermes Gateway Operations

This skill governs real-world operation of the Hermes messaging gateway: which venv it runs from, how to migrate it safely, how platform plugins are loaded, and how to keep it alive after maintenance.

## Scope

Use this skill when:
- The gateway needs to be moved from a custom venv to the main Hermes venv.
- A platform adapter (Slack, Discord, Telegram, etc.) needs to be installed or reinstalled.
- The gateway fails to come back up after a stop/restart.
- You need to add external health monitoring because systemd `Restart=always` is not enough.

## Core facts

- The gateway is a long-lived Python process usually run under a systemd user service (`hermes-gateway.service`).
- It reads credentials from `HERMES_HOME/.env` and platform config from `HERMES_HOME/config.yaml`.
- Platform plugins are opt-in via `plugins.enabled` in config (since a Hermes migration made plugins opt-in).
- The gateway can be installed in a **dedicated venv** (e.g. `/data/runtime/hermes-slack-venv/`) if the main Hermes venv lacked the platform dependencies or the correct Hermes version. This is valid but non-standard.

## Gateway lifecycle: what can go wrong

### Systemd does not auto-restart after a manager-initiated stop

`Restart=always` only retries when the main process exits on its own. When you run:

```bash
systemctl --user stop hermes-gateway.service
systemctl --user start hermes-gateway.service
```

and the process is mid-API-call, it may exit with status `1/FAILURE`. If systemd sees this as part of a manager-initiated stop sequence, it can leave the service in `failed`/`inactive` and **will not** auto-restart. This is why a migration script that stops the gateway from inside the gateway process can strand the service offline.

### Hermes blocks gateway lifecycle commands from inside itself

The Hermes runtime detects commands that look like gateway start/stop/restart and blocks them to prevent self-termination. Workarounds:

1. Run the command from a shell that is **not** a child of the gateway service (e.g. SSH session, another tmux window, or a systemd-run scope).
2. Schedule the action via `at` or a systemd timer that lives outside the gateway cgroup.
3. Use a wrapper script executed by a separate systemd user service.

## Safe migration recipe (example: Slack venv → main venv)

1. **Inspect current state**
   ```bash
   systemctl --user cat hermes-gateway.service
   hermes gateway status
   cat ~/.hermes/gateway_state.json
   ```

2. **Ensure main venv has the platform dependencies**
   - Check `hermes --version` in the main venv vs. the gateway venv.
   - If the main install is older, update it to match the working gateway version before switching.
   - Install the platform extra, e.g.:
     ```bash
     cd /data/.hermes/hermes-agent
     /path/to/uv pip install -e ".[slack]" --python ./venv/bin/python
     ```

3. **Preserve credentials and config**
   - Credentials are in `HERMES_HOME/.env` and are usually already correct.
   - Enable the platform plugin: `hermes plugins enable slack-platform`.

4. **Update the systemd service file**
   - Point `ExecStart`, `ExecStopPost`, `PATH`, and `VIRTUAL_ENV` to the main venv.
   - Keep `RestartForceExitStatus=75` and `RestartPreventExitStatus=78`. Do **not** add exit code 1 to `RestartForceExitStatus`; that would turn future fatal config errors into silent restart-crash loops.
   - Keep `StartLimitIntervalSec=0` to prevent start-limit failures.

5. **Reload systemd and start the gateway from outside the gateway process**
   - Do **not** run `systemctl --user restart hermes-gateway` from inside the gateway shell.
   - Use a separate shell or a wrapper script run by a systemd timer.

6. **Verify**
   ```bash
   systemctl --user status hermes-gateway.service
   cat ~/.hermes/gateway_state.json
   ```

7. **Add an external healthwatch timer**
   - Because systemd won't recover from a manager-initiated stop, add a separate systemd user timer that checks `systemctl --user is-active hermes-gateway.service` every minute and runs `reset-failed` + `start` if needed.
   - Do **not** work around the Hermes lifecycle guard by renaming units to dodge a keyword match. Hermes intentionally blocks gateway-lifecycle commands from inside itself; if the guard is overly broad, flag it to a human rather than bypassing it.

## Reference files

- `references/session-2026-08-13-slack-migration.md` — worked example: migrating Slack from `/data/runtime/hermes-slack-venv/` to the main venv, the systemd restart failure, and the healthwatch timer fix.
- `references/systemd-healthwatch-example.md` — copy-paste timer + service + script for auto-recovery.
- `references/lifecycle-guard-note.md` — why the guard exists, when it can false-positive, and the correct response.

## Pitfalls

- `RestartForceExitStatus=1 75` was tried and reverted: it only affects organic process exits, not manager-initiated stops, and it would mask fatal config errors by forcing endless restart loops.
- Do not assume `Restart=always` will recover the gateway after you stop it administratively.
- Do not run gateway restart commands from inside the gateway process; Hermes blocks them and SIGTERM propagation can kill the command.
- Do not switch the systemd service to a new venv without verifying that venv has the same (or newer) Hermes version and the platform dependencies.
- Do not delete the old venv until the new gateway has been confirmed connected for several minutes.
- Do **not** work around the Hermes lifecycle guard by renaming units or otherwise dodging the keyword match. Stop and flag the block to a human.

## Related

- `hermes-agent` — bundled skill for Hermes setup/configuration.
- `hermes-slack-gateway-model-scope` — narrower skill about Slack permissions vs. model tool scope; merge into this umbrella over time.

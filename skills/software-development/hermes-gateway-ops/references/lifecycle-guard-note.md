# Hermes gateway lifecycle guard

Hermes intentionally blocks terminal/cron commands that look like they would restart, stop, or kill the gateway process from inside itself. This prevents an agent from accidentally terminating its own runtime.

## What gets blocked

Commands matching patterns such as:
- `hermes gateway restart|stop|start`
- `systemctl ... hermes-gateway.service ... restart|stop|start`
- `launchctl ... hermes-gateway ...`
- `pkill ... hermes-gateway ...`

## Correct response when blocked

1. Stop. Do **not** rename the unit, rephrase the command, or otherwise route around the guard.
2. Tell the human clearly what is blocked and why.
3. Ask them to run the command from a separate shell, or wait for them to handle it.

## If the guard is overly broad

In this session the guard had a regex bug: it matched `hermes-gateway` as a bare substring, so a sibling unit named `hermes-gateway-healthcheck.timer` was falsely blocked. Claude Code patched `cron/lifecycle_guard.py` to anchor with `(?![\w-])` so it still blocks real gateway lifecycle commands but no longer false-positives on sibling names. The fix belongs in the guard, not in dodging it.

## Recovery options that are acceptable

- Run the lifecycle command from an SSH session or another shell outside the gateway cgroup.
- Use a systemd user timer/service that is entirely outside Hermes's execution path.
- Ask the human to run `systemctl --user start hermes-gateway.service` from another session.

Do not hide the lifecycle command inside a renamed script or unit to evade detection.

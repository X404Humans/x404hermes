# Isolated Hermes Sub-Agent Environment Recipe

When running isolated Hermes profiles for x404 sub-agents (meeting-prep, knowledge-curator, etc.), the profile must resolve credentials the same way the main runtime does.

## Common symptom

```
No usable credentials found for provider 'ollama-cloud'. Set OLLAMA_API_KEY.
```

The main gateway works, but the cron-spawned sub-agent fails with this error.

## Why it happens

- The main gateway systemd service explicitly sets `HERMES_HOME=/data/runtime/hermes`, so it reads `/data/runtime/hermes/.env`.
- The sub-agent wrapper `/data/.local/bin/hermes -p <profile>` resolves the profile's own `.env` path. If `/data/runtime/hermes/profiles/<profile>/.env` does not exist, the key is missing.
- The default `.hermes/config.yaml` also points to a different paid model (`anthropic/claude-opus-4.6` / `auto`), so without the runtime `.env` the sub-agent hits auth or credit errors there too.

## Required setup

For each isolated profile:

```bash
export HERMES_HOME=/data/runtime/hermes
ln -sf /data/runtime/hermes/.env /data/runtime/hermes/profiles/$PROFILE/.env
```

In the launcher script used by cron:

```bash
#!/usr/bin/env bash
set -euo pipefail
export HERMES_HOME=/data/runtime/hermes

KB="/data/knowledge"
HERMES_WRAPPER="/data/.local/bin/$PROFILE"

# Use CLI toolset 'slack' for history read; 'hermes-slack' is the plugin toolset name, not the CLI toolset.
$HERMES_WRAPPER chat -q "$PROMPT" --quiet --toolsets slack,file,web,terminal

# Post with hermes send; the slack toolset does not send messages.
$HERMES_WRAPPER send --to "slack:C0B5T66ESGY" --subject "[Topic]" "message"
```

## Verification

```bash
export HERMES_HOME=/data/runtime/hermes
/data/.hermes/hermes-agent/venv/bin/hermes -p x404-meeting-prep config env-path
# should print /data/runtime/hermes/profiles/x404-meeting-prep/.env
/data/.hermes/hermes-agent/venv/bin/hermes -p x404-meeting-prep chat -q "echo hi" --quiet
# should succeed and print "hi"
```

## Cron script placement

The `cronjob` tool expects scripts relative to `~/.hermes/scripts/`. Symlink runtime scripts there:

```bash
ln -sf /data/runtime/hermes/scripts/x404-meeting-prep.sh /data/.hermes/scripts/x404-meeting-prep.sh
ln -sf /data/runtime/hermes/scripts/x404-knowledge-curator.sh /data/.hermes/scripts/x404-knowledge-curator.sh
```

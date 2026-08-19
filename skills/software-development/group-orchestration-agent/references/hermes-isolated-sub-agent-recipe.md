# Hermes Isolated Sub-Agent Recipe

Use this when you need to move heavy, recurring work out of the main orchestration profile into a dedicated sub-agent, while keeping everything on the same VPS/runtime.

## When to apply

- Recurring cron jobs that eat context window or cost tokens (research radar, meeting digest, curator).
- Batch tasks that are single-shot and don’t need conversational memory (digest, prep, lint).
- Any work the user explicitly wants isolated from the main orchestrator.

## Recipe

### 1. Create the profile

```bash
hermes profile create x404-example-agent \
  --description "One-line description of what this sub-agent does"
```

This creates:
- `/data/runtime/hermes/profiles/x404-example-agent/`
- wrapper script `/data/.local/bin/x404-example-agent`

### 2. Override only what you need

Create `/data/runtime/hermes/profiles/x404-example-agent/config.yaml`:

```yaml
model:
  default: qwen3.5
  provider: ollama-cloud
  base_url: ''
agent:
  max_turns: 50
  verbose: false
  reasoning_effort: medium
memory:
  memory_enabled: true
  user_profile_enabled: true
```

Keep the file minimal. Inherit everything else (Slack plugin, toolsets, etc.) from the base runtime.

### 3. Write the script

Create `/data/runtime/hermes/scripts/x404-example-agent.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

KB="/data/knowledge"
LOG_FILE="$KB/.x404-example-agent-log.txt"
HERMES_WRAPPER="/data/.local/bin/x404-example-agent"

PROMPT=$(cat <<'EOF'
You are the x404-example-agent sub-agent. Read ... and do ...
Output:
- Write findings to ...
- Post a concise Slack message to channel C0B5T66ESGY with ...
EOF
)

$HERMES_WRAPPER chat -q "$PROMPT" --quiet --toolsets hermes-slack,file,web,terminal

echo "$(date -Iseconds) x404-example-agent ran" >> "$LOG_FILE"
```

Make it executable:

```bash
chmod +x /data/runtime/hermes/scripts/x404-example-agent.sh
```

### 4. Symlink into `~/.hermes/scripts`

Hermes cron requires script paths to be relative to `~/.hermes/scripts/`.

```bash
ln -sf /data/runtime/hermes/scripts/x404-example-agent.sh \
  /data/.hermes/scripts/x404-example-agent.sh
```

### 5. Wire it to a cron job

```bash
hermes cron create \
  --name x404-example-agent \
  --schedule "0 2 * * 1" \
  --script x404-example-agent.sh \
  --deliver slack:C0B5T66ESGY \
  --prompt "Run the x404-example-agent sub-agent. If it fails, post a brief error to #meetings."
```

### 6. Document it

Create `/data/runtime/hermes/skills/x404-example-agent/SKILL.md` with:
- Trigger (cron + manual command)
- What it does
- Model/profile used
- Outputs
- Failure handling

## Pitfalls

- **Do not use absolute paths in cron `--script`**. It must be a filename under `~/.hermes/scripts/`.
- **Do not forget the symlink**. The script must exist in both `/data/runtime/hermes/scripts/` (for backup) and `/data/.hermes/scripts/` (for cron).
- **Do not over-configure the profile**. Minimal overrides reduce divergence from the main runtime.
- **Verify Slack membership first**. If the cron fails with `not_in_channel`, ask a human to invite `@Hermes` before retrying.

## Example: meeting-prep agent

```bash
hermes profile create x404-meeting-prep --description "Drafts next x404 sync agenda"
cat > /data/runtime/hermes/profiles/x404-meeting-prep/config.yaml <<'EOF'
model:
  default: qwen3.5
  provider: ollama-cloud
agent:
  max_turns: 50
EOF
# ...write /data/runtime/hermes/scripts/x404-meeting-prep.sh...
ln -sf /data/runtime/hermes/scripts/x404-meeting-prep.sh /data/.hermes/scripts/x404-meeting-prep.sh
hermes cron create --name x404-weekly-agenda --schedule "0 2 * * 3" \
  --script x404-meeting-prep.sh --deliver slack:C0B5T66ESGY \
  --prompt "Run meeting-prep sub-agent."
```

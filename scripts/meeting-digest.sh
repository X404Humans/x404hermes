#!/usr/bin/env bash
# x404 Meeting Note Digest Pipeline
# Detects new meeting notes in /data/knowledge/sources/meeting notes/
# and posts a digest to Slack #meetings (C0B5T66ESGY).
set -euo pipefail

KB="/data/knowledge"
SRC_DIR="$KB/sources/meeting notes"
STATE_FILE="$KB/.digest-state.json"
SLACK_CHANNEL="slack:C0B5T66ESGY"
HERMES_HOME="/data/runtime/hermes"
DIGEST_LOG="$KB/.digest-log.txt"

# Ensure state file exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo '{}' > "$STATE_FILE"
fi

# Find all .md files sorted by mtime desc
mapfile -t FILES < <(find "$SRC_DIR" -name '*.md' -printf '%T@ %p\n' | sort -rn | head -5 | cut -d' ' -f2-)

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "$(date -Iseconds) No meeting notes found" >> "$DIGEST_LOG"
    exit 0
fi

# Build a digest using Hermes chat (non-interactive)
DIGEST="$(cat <<'EOF'
Read the following meeting note files and produce a concise Slack-ready digest in this exact format:

:x404: *Meeting Digest — [meeting title / date]*

*Key Decisions*
- bullet

*Action Items*
- [owner] task

*Open Questions*
- question

*Source:* [relative path]

Keep it short. Do not include sensitive personal data. Auto-assign owners based on who spoke about a topic. If uncertain, ask the group.
EOF
)"

# Write prompt with file list to temp file
TMP_PROMPT=$(mktemp)
echo "$DIGEST" > "$TMP_PROMPT"
for f in "${FILES[@]}"; do
    echo "" >> "$TMP_PROMPT"
    echo "--- $f ---" >> "$TMP_PROMPT"
    cat "$f" >> "$TMP_PROMPT"
done

OUTPUT=$(HERMES_HOME="$HERMES_HOME" /data/runtime/hermes-slack-venv/bin/python -m hermes_cli.main chat -q "$(cat "$TMP_PROMPT")" --quiet --toolsets hermes-slack,file,web 2>/dev/null || echo "*Digest generation failed*")
rm -f "$TMP_PROMPT"

# Send to Slack
HERMES_HOME="$HERMES_HOME" /data/runtime/hermes-slack-venv/bin/python -m hermes_cli.main send --to "$SLACK_CHANNEL" --subject "[Meeting Digest]" "$OUTPUT" || true

echo "$(date -Iseconds) Digested ${#FILES[@]} files" >> "$DIGEST_LOG"

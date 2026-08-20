#!/usr/bin/env bash
# x404 Knowledge Curator Sub-Agent
# Isolated Hermes profile: x404-knowledge-curator
# Weekly lint, cross-link, and staleness check of /data/knowledge.
set -euo pipefail

export HERMES_HOME=/data/runtime/hermes
KB="/data/knowledge"
LOG_FILE="$KB/.knowledge-curator-log.txt"
HERMES_WRAPPER="/data/.local/bin/x404-knowledge-curator"

# Hard cap on how long the agent loop may run. The "slack" toolset is
# read-only (Slack History only — no send/post tool exists), so the agent
# must never be asked to post to Slack itself: it will burn turns trying
# broken workarounds (wrong CLI subcommands, missing venvs, denied .env
# reads) and can hang well past this. Delivery to Slack is handled
# externally by the Hermes cron job's own "deliver" target, which reuses
# the live gateway connection and does not depend on this script.
CHAT_TIMEOUT=300

PROMPT=$(cat <<EOF
You are the x404 knowledge-curator sub-agent. Run a lightweight weekly health check on the x404 knowledgebase at ${KB}.

Tasks:
1. Read ${KB}/wiki/index.md and list every .md file under ${KB}/wiki/ and ${KB}/ops-guides/.
2. Identify:
   - Wiki pages not linked from index.md (orphans)
   - Ops-guides not referenced anywhere in wiki or other ops-guides
   - Pages with frontmatter `updated` older than 14 days
   - Broken relative markdown links
   - Empty wiki pages (less than 5 lines of body content)
3. Read ${KB}/sources/uploads/ and ${KB}/sources/uploads/archive/. List any files in uploads/ that are not referenced in the wiki or ops-guides and are not in archive/.
4. Check that ${KB}/wiki/action-items.md has been updated in the last 7 days.

Output:
- Append a short curator log entry to ${KB}/wiki/log.md with today's date and the findings.
- End your final response with a concise plain-text summary suitable for posting as-is:
  - Header line: ":x404: *Weekly KB Curator Report*"
  - One bullet per finding category (only include categories with issues)
  - If no issues: say "KB looks healthy this week."

Do not modify any source files. Only append to wiki/log.md.
Do not attempt to post to Slack yourself — you do not have a Slack-send tool available. Delivery is handled outside this session.
EOF
)

log() { echo "$(date -Iseconds) $*" >> "$LOG_FILE"; }

set +e
timeout "$CHAT_TIMEOUT" "$HERMES_WRAPPER" chat -q "$PROMPT" --quiet --toolsets file,terminal
status=$?
set -e

if [[ $status -eq 124 ]]; then
    log "ERROR: curator chat timed out after ${CHAT_TIMEOUT}s"
    echo "x404-knowledge-curator: chat timed out after ${CHAT_TIMEOUT}s" >&2
    exit 1
elif [[ $status -ne 0 ]]; then
    log "ERROR: curator chat exited with status $status"
    echo "x404-knowledge-curator: chat exited with status $status" >&2
    exit "$status"
fi

log "Knowledge curator ran"

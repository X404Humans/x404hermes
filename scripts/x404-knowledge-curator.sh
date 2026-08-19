#!/usr/bin/env bash
# x404 Knowledge Curator Sub-Agent
# Isolated Hermes profile: x404-knowledge-curator
# Weekly lint, cross-link, and staleness check of /data/knowledge.
set -euo pipefail

export HERMES_HOME=/data/runtime/hermes
KB="/data/knowledge"
LOG_FILE="$KB/.knowledge-curator-log.txt"
SLACK_CHANNEL="slack:C0B5T66ESGY"
HERMES_WRAPPER="/data/.local/bin/x404-knowledge-curator"

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
- Post a concise Slack message to channel C0B5T66ESGY with:
  - Header: ":x404: *Weekly KB Curator Report*
  - One bullet per finding category (only include categories with issues)
  - If no issues: say "KB looks healthy this week."

Do not modify any source files. Only append to wiki/log.md and post to Slack.
EOF
)

$HERMES_WRAPPER chat -q "$PROMPT" --quiet --toolsets slack,file,terminal

echo "$(date -Iseconds) Knowledge curator ran" >> "$LOG_FILE"

#!/usr/bin/env bash
# x404 Meeting Prep Sub-Agent
# Isolated Hermes profile: x404-meeting-prep
# Reads KB action items, open questions, and recent Slack,
# then drafts the next sync folder + proposed agenda.
set -euo pipefail

export HERMES_HOME=/data/runtime/hermes
KB="/data/knowledge"
SRC_DIR="$KB/sources/meeting notes"
LOG_FILE="$KB/.meeting-prep-log.txt"
SENT_FILE="$KB/.meeting-prep-sent.txt"
SLACK_CHANNEL="slack:C0B5T66ESGY"
HERMES_WRAPPER="/data/.local/bin/x404-meeting-prep"

mkdir -p "$SRC_DIR"

# Compute next Wednesday date in Singapore time (Wed 08:00 SGT)
NEXT_DATE=$(TZ=Asia/Singapore date -d 'next wednesday' +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
FOLDER_NAME="$SRC_DIR/${NEXT_DATE} x404 Humans Found Sync"
AGENDA_FILE="$FOLDER_NAME/${NEXT_DATE} x404 Humans Found Sync Proposed Agenda.md"

mkdir -p "$FOLDER_NAME"

# Build prompt for the isolated profile
PROMPT=$(cat <<EOF
You are the x404 meeting-prep sub-agent. Read these files and produce a proposed agenda for the next x404 Humans Found sync on ${NEXT_DATE}.

Input files:
- $KB/wiki/action-items.md
- $KB/wiki/open-questions.md
- $KB/wiki/decisions.md
- $KB/wiki/mission-objectives-commitments.md (if it exists)

Also read the last 7 days of Slack messages from channels C0AV70KSN8P (#general), C0BPT5G8D45 (#orchestration), and C0BQURPSA8M (research-radar) using slack_history.

Output: write a markdown file at exactly this path:
${AGENDA_FILE}

Use this structure:
# YYYY-MM-DD x404 Humans Found Sync — Proposed Agenda

## 1. Hermes / KB Recap (5 min)
- Quick status of action items and KB changes since last sync.

## 2. Action Item Burn-down (10 min)
- Review open action items by owner.

## 3. Open Questions / Decisions (10 min)
- List unresolved questions needing group input.

## 4. Research / Market Radar (5 min)
- Highlight top signals from #C0BQURPSA8M since last sync.

## 5. Project Updates (10 min)
- Buzz, SELAT, Enter the Claw, or any other active project.

## 6. Async Items / Heads-ups (5 min)
- Anything that doesn't need live discussion.

## 7. Next Steps / Owned Actions
- Extracted from the agenda.

Keep it concise and scannable. Then post a short message to Slack channel C0B5T66ESGY with:
- A header like ":x404: *Proposed Agenda — ${NEXT_DATE} x404 Sync*"
- A 1-2 sentence summary
- A link to the GitHub raw URL for the agenda file: https://github.com/X404Humans/x404knowledge/blob/main/sources/meeting%20notes/${NEXT_DATE}%20x404%20Humans%20Found%20Sync/${NEXT_DATE}%20x404%20Humans%20Found%20Sync%20Proposed%20Agenda.md

If there is already an agenda file at the target path, read it first and update it rather than overwriting.
EOF
)

$HERMES_WRAPPER chat -q "$PROMPT" --quiet --toolsets slack,file,web,terminal

# Only post once per meeting date. The agenda file may be updated by re-runs, but Slack notify once.
if [[ -f "$AGENDA_FILE" ]] && ! grep -Fxq "${NEXT_DATE}" "$SENT_FILE" 2>/dev/null; then
    AGENDA_URL="https://github.com/X404Humans/x404knowledge/blob/main/sources/meeting%20notes/${NEXT_DATE}%20x404%20Humans%20Found%20Sync/${NEXT_DATE}%20x404%20Humans%20Found%20Sync%20Proposed%20Agenda.md"
    $HERMES_WRAPPER send --to "$SLACK_CHANNEL" --subject "[Proposed Agenda]" ":x404: *Proposed Agenda — ${NEXT_DATE} x404 Sync*\n\nDrafted the proposed agenda for tomorrow's sync. Please edit or add items.\n\n${AGENDA_URL}"
    echo "${NEXT_DATE}" >> "$SENT_FILE"
fi

echo "$(date -Iseconds) Meeting prep ran for ${NEXT_DATE}" >> "$LOG_FILE"

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
DRAFT_FILE="$KB/.meeting-prep-draft.txt"
SLACK_CHANNEL="slack:C0B5T66ESGY"
HERMES_WRAPPER="/data/.local/bin/x404-meeting-prep"

mkdir -p "$SRC_DIR"

# Compute next sync date/time in Singapore time
# Weekly syncs are Wednesdays at 8pm EDT / Thursdays at 8am SGT.
# When EST is in effect (UTC-5), Thu 9am SGT.
NEXT_DATE_SGT=$(TZ=Asia/Singapore date -d 'next wednesday 20:00 America/New_York' +%Y-%m-%d)
TIME_SGT=$(TZ=Asia/Singapore date -d "${NEXT_DATE_SGT} 20:00 America/New_York" +%H:%M)
DAY_SGT=$(TZ=Asia/Singapore date -d "${NEXT_DATE_SGT} 20:00 America/New_York" +%A)
FOLDER_NAME="$SRC_DIR/${NEXT_DATE_SGT} x404 Humans Found Sync"
AGENDA_FILE="$FOLDER_NAME/${NEXT_DATE_SGT} x404 Humans Found Sync Proposed Agenda.md"

mkdir -p "$FOLDER_NAME"

# Build prompt for the isolated profile
PROMPT=$(cat <<EOF
You are the x404 meeting-prep sub-agent. Read these files and produce a proposed agenda for the next x404 Humans Found sync on ${NEXT_DATE_SGT} (${DAY_SGT} ${TIME_SGT} SGT / Wed 8pm ET).

Input files:
- $KB/wiki/action-items.md
- $KB/wiki/open-questions.md
- $KB/wiki/decisions.md
- $KB/wiki/mission-objectives-commitments.md (if it exists)
- $KB/ops-guides/2026-08-18-hermes-kb-orchestration-recap.md (reference only)

Also read the last 7 days of Slack messages from channels C0AV70KSN8P (#general), C0B5T66ESGY (#meetings), C0BPT5G8D45 (#orchestration), and C0BQURPSA8M (#research-radar) using slack_history.

Output: write a markdown file at exactly this path:
${AGENDA_FILE}

Use this structure and exactly this order:
# ${NEXT_DATE_SGT} x404 Humans Found Sync — Proposed Agenda (Initial Draft)

> **Date:** ${DAY_SGT} ${NEXT_DATE_SGT}, ${TIME_SGT} SGT (Wed ${NEXT_DATE_SGT} 20:00 ET)
> **Status:** Proposed — please edit or comment in Slack.

## 1. Hermes / KB / Orchestration Recap
- Tony walkthrough of KB restructure, agent identity, meeting-note pipeline, research radar sub-agent, weekly agenda/stale-action crons, Slack 2-way status.
- Reference: <https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/2026-08-18-hermes-kb-orchestration-recap.md|ops-guides/2026-08-18-hermes-kb-orchestration-recap.md>

## 2. Buzz Experiment Updates
- Jai / Kishore / Rodolfo: what's happening in #buzz, blockers, next steps.

## 3. Action Items Needing Updates
- A5: Group async feedback on alignment/R&R proposal in #general. — <https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/2026-08-17-group-alignment-proposal.md|ops-guides/2026-08-17-group-alignment-proposal.md>

## 4. Async Action Items (no live discussion needed)
- A3: Zain to confirm cloud-computer dependencies for KB cleanup. — <https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/cloud-computer-file-dependencies.md|ops-guides/cloud-computer-file-dependencies.md>
- A4: Zain/Tony to review webhook upgrade for instant KB sync. — <https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/vps-admin-webhook-request.md|ops-guides/vps-admin-webhook-request.md>

## 5. Open Questions for Live Discussion
- Q1: Final mission statement ratification. — <https://github.com/X404Humans/x404knowledge/blob/main/wiki/mission-objectives-commitments.md|wiki/mission-objectives-commitments.md>
- Q2 / Q7: Do we want explicit rotating guild roles? If yes, which roles and who starts where? — <https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/2026-08-17-group-alignment-proposal.md|ops-guides/2026-08-17-group-alignment-proposal.md>
- Q6: Who drops meeting notes into the KB after each sync? (Proposed: Hermes reminder ping.)

## 6. Pending Decisions
- D1: Mission / Objectives / Commitments. — <https://github.com/X404Humans/x404knowledge/blob/main/wiki/mission-objectives-commitments.md|wiki/mission-objectives-commitments.md>
- D2: Roles & Responsibilities concept. — <https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/2026-08-17-group-alignment-proposal.md|ops-guides/2026-08-17-group-alignment-proposal.md>

## 7. Blockers
- Waiting on Zain’s A3 confirmation.

Keep it concise and scannable. Do not include full GitHub URLs in the body; if you link to KB files, use the relative folder/file path as display text linked to the GitHub URL.

Then post a short message to Slack channel C0B5T66ESGY with:
- A header like ":calendar: _Proposed Agenda — ${NEXT_DATE_SGT} x404 Sync — Initial Draft_"
- A 1-2 sentence summary
- A Slack hyperlink using the folder path as display text and the GitHub URL as the link: <https://github.com/X404Humans/x404knowledge/blob/main/sources/meeting%20notes/${NEXT_DATE_SGT}%20x404%20Humans%20Found%20Sync/${NEXT_DATE_SGT}%20x404%20Humans%20Found%20Sync%20Proposed%20Agenda.md|sources/meeting notes/${NEXT_DATE_SGT} x404 Humans Found Sync/${NEXT_DATE_SGT} x404 Humans Found Sync Proposed Agenda.md>

If there is already an agenda file at the target path, read it first and update it rather than overwriting. If you update it, bump the draft label in the title from "Initial Draft" to "Second Draft", "Third Draft", etc. and reflect that in the Slack header.
EOF
)

$HERMES_WRAPPER chat -q "$PROMPT" --quiet --toolsets slack,file,web,terminal

# Only post once per meeting date. The agenda file may be updated by re-runs, but Slack notify once.
if [[ -f "$AGENDA_FILE" ]] && ! grep -Fxq "${NEXT_DATE_SGT}" "$SENT_FILE" 2>/dev/null; then
    AGENDA_URL="https://github.com/X404Humans/x404knowledge/blob/main/sources/meeting%20notes/${NEXT_DATE_SGT}%20x404%20Humans%20Found%20Sync/${NEXT_DATE_SGT}%20x404%20Humans%20Found%20Sync%20Proposed%20Agenda.md"
    AGENDA_PATH="sources/meeting notes/${NEXT_DATE_SGT} x404 Humans Found Sync/${NEXT_DATE_SGT} x404 Humans Found Sync Proposed Agenda.md"
    $HERMES_WRAPPER send --to "$SLACK_CHANNEL" --subject "[Proposed Agenda]" ":calendar: _Proposed Agenda — ${NEXT_DATE_SGT} x404 Sync — Initial Draft_\n\nUpdated the proposed agenda for tomorrow's sync. Please edit or add items in thread.\n\n<${AGENDA_URL}|${AGENDA_PATH}>"
    echo "${NEXT_DATE_SGT}" >> "$SENT_FILE"
fi

echo "$(date -Iseconds) Meeting prep ran for ${NEXT_DATE_SGT}" >> "$LOG_FILE"

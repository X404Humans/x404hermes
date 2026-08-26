#!/usr/bin/env bash
# x404 Meeting Prep Sub-Agent
# Reads KB action items, open questions, and recent Slack,
# then drafts the next sync folder + proposed agenda and posts to Slack.
set -euo pipefail

export HERMES_HOME=/data/runtime/hermes
KB="/data/knowledge"
SRC_DIR="$KB/sources/meeting notes"
LOG_FILE="$KB/.meeting-prep-log.txt"
SENT_FILE="$KB/.meeting-prep-sent.txt"
SLACK_CHANNEL="slack:C0B5T66ESGY"
HERMES_BIN="/data/.local/bin/hermes"
# The writer sub-agent and the Slack send both run in the default profile.
# - slack_history needs the active gateway Slack session, which is in the default profile.
# - hermes send needs the gateway's channel_directory.json, also in the default profile.
# The isolated x404-meeting-prep profile does not have a Slack session or channel directory.

mkdir -p "$SRC_DIR"

# Compute next sync date/time in Singapore time.
# Weekly syncs are Wednesdays at 8pm ET / Thursdays at 8am SGT (9am SGT during EST).
# uutils date does not accept combined date/time/zone strings, so:
# 1) Get the next Wednesday date in America/New_York.
# 2) Convert that date at 20:00 ET to an ISO timestamp with offset.
# 3) Interpret that timestamp in Asia/Singapore to get the Thursday SGT date/time.
NEXT_DATE_ET=$(TZ=America/New_York date -d 'next wednesday' +%Y-%m-%d)
NEXT_ISO_UTC=$(TZ=America/New_York date -d "${NEXT_DATE_ET} 20:00" +%Y-%m-%dT%H:%M:%S%z)
NEXT_DATE_SGT=$(TZ=Asia/Singapore date -d "$NEXT_ISO_UTC" +%Y-%m-%d)
TIME_SGT=$(TZ=Asia/Singapore date -d "$NEXT_ISO_UTC" +%H:%M)
DAY_SGT=$(TZ=Asia/Singapore date -d "$NEXT_ISO_UTC" +%A)
FOLDER_NAME="$SRC_DIR/${NEXT_DATE_SGT} x404 Humans Found Sync"
AGENDA_FILE="$FOLDER_NAME/${NEXT_DATE_SGT} x404 Humans Found Sync Proposed Agenda.md"

mkdir -p "$FOLDER_NAME"

# Build prompt. The sub-agent only writes/updates the agenda file.
PROMPT=$(cat <<EOF
You are the x404 meeting-prep sub-agent. Read these files and the specified Slack channels, then produce or update a proposed agenda for the next x404 Humans Found sync.

Sync details:
- Thursday SGT date: ${NEXT_DATE_SGT}
- Day/time SGT: ${DAY_SGT} ${TIME_SGT}
- Equivalent ET: Wed ${NEXT_DATE_ET} 20:00

Input files:
- $KB/wiki/action-items.md
- $KB/wiki/open-questions.md
- $KB/wiki/decisions.md
- $KB/wiki/mission-objectives-commitments.md (if it exists)
- $KB/ops-guides/2026-08-18-hermes-kb-orchestration-recap.md (reference only)

Slack channels to read with slack_history (last 7 days):
- C0AV70KSN8P (#general)
- C0B5T66ESGY (#meetings)
- C0BPT5G8D45 (#orchestration)
- C0BQURPSA8M (#market-research)

Output file (exact path — no other filename):
${AGENDA_FILE}

Required structure and order:
# ${NEXT_DATE_SGT} x404 Humans Found Sync — Proposed Agenda (Initial Draft)

> **Date:** ${DAY_SGT} ${NEXT_DATE_SGT}, ${TIME_SGT} SGT (Wed ${NEXT_DATE_ET} 20:00 ET)
> **Status:** Proposed — please edit or comment in Slack.

## 1. Hermes / KB / Orchestration Recap
- Tony walkthrough of KB restructure, agent identity, meeting-note pipeline, market-research radar sub-agent, weekly agenda/stale-action crons, Slack 2-way status.
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

Rules:
- Keep it concise and scannable.
- Do not include full GitHub URLs as plain text. Use Slack mrkdwn hyperlinks: <URL|display> where display is the relative KB folder/file path.
- Correct example: <https://github.com/X404Humans/x404knowledge/blob/main/ops-guides/2026-08-18-hermes-kb-orchestration-recap.md|ops-guides/2026-08-18-hermes-kb-orchestration-recap.md>
- Do NOT reverse the link: the URL must come first, then the pipe, then the display text.
- Do NOT post to Slack yourself. Only write the markdown file.

If the agenda file already exists, read it first and update it rather than overwriting. If you update it, bump the draft label in the title from "Initial Draft" to "Second Draft", "Third Draft", etc.
EOF
)

# Run the writer sub-agent in the default profile so slack_history can access the gateway session.
$HERMES_BIN chat -q "$PROMPT" --quiet --toolsets slack,file,web,terminal

# The sub-agent should have produced the file at exactly AGENDA_FILE.
if [[ ! -f "$AGENDA_FILE" ]]; then
    echo "ERROR: Agenda file was not created at expected path: $AGENDA_FILE" >&2
    exit 1
fi

AGENDA_URL="https://github.com/X404Humans/x404knowledge/blob/main/sources/meeting%20notes/${NEXT_DATE_SGT}%20x404%20Humans%20Found%20Sync/${NEXT_DATE_SGT}%20x404%20Humans%20Found%20Sync%20Proposed%20Agenda.md"
AGENDA_PATH="sources/meeting notes/${NEXT_DATE_SGT} x404 Humans Found Sync/${NEXT_DATE_SGT} x404 Humans Found Sync Proposed Agenda.md"

# Only post once per meeting date. Re-runs may update the file, but Slack is notified once.
if ! grep -Fxq "${NEXT_DATE_SGT}" "$SENT_FILE" 2>/dev/null; then
    # Use a heredoc so newlines are real, not literal \n.
    $HERMES_BIN send --to "$SLACK_CHANNEL" --file - <<MSG
:calendar: _Proposed Agenda — ${NEXT_DATE_SGT} x404 Sync — Initial Draft_

Updated the proposed agenda for the next sync. Please edit or add items in thread.

<${AGENDA_URL}|${AGENDA_PATH}>
MSG
    echo "${NEXT_DATE_SGT}" >> "$SENT_FILE"
fi

echo "$(date -Iseconds) Meeting prep ran for ${NEXT_DATE_SGT}" >> "$LOG_FILE"

#!/bin/bash
# x404 knowledge-sync watchdog. Runs as a no-agent Hermes cron job: stdout
# is delivered to Slack verbatim, so this prints NOTHING when healthy and
# a short alert when not. Always exits 0 — the Hermes cron framework
# treats a non-zero exit as "script failed" and suppresses delivery, so
# the alert itself must travel via stdout content, not the exit code.
# Health state is also recorded to kb-sync-monitor.log for local checks.
set -uo pipefail

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1001}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"

REPO_DIR="/data/knowledge"
SYNC_LOG="$REPO_DIR/.sync/git-sync-knowledge.log"
STATE_LOG="$REPO_DIR/.sync/kb-sync-monitor.log"
SERVICE="hermes-knowledge-git-sync.service"
STALE_AFTER_SECS=900   # ~15 minutes

alerts=()
now_epoch=$(date -u +%s)

state_log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" >> "$STATE_LOG"; }

# --- Check 1: did the last timer-triggered run actually succeed? ---
svc_info=$(systemctl --user show "$SERVICE" -p ExecMainStartTimestamp -p ExecMainStatus -p Result 2>&1)
exec_status=$(sed -n 's/^ExecMainStatus=//p' <<<"$svc_info")
result=$(sed -n 's/^Result=//p' <<<"$svc_info")
start_ts=$(sed -n 's/^ExecMainStartTimestamp=//p' <<<"$svc_info")

if [[ -n "$exec_status" && "$exec_status" != "0" ]]; then
    alerts+=("last run of $SERVICE exited status=$exec_status (result=$result)")
fi

if [[ -n "$start_ts" && "$start_ts" != "n/a" ]]; then
    start_epoch=$(date -u -d "$start_ts" +%s 2>/dev/null || echo 0)
    if [[ "$start_epoch" -gt 0 ]]; then
        age=$(( now_epoch - start_epoch ))
        if (( age > STALE_AFTER_SECS )); then
            alerts+=("$SERVICE has not run in ${age}s (expected every 5m, threshold ${STALE_AFTER_SECS}s)")
        fi
    fi
else
    alerts+=("could not read $SERVICE last-start timestamp — is the timer enabled?")
fi

# --- Check 2: any recent authentication failures in the sync log? ---
if [[ -f "$SYNC_LOG" ]]; then
    cutoff_epoch=$(( now_epoch - STALE_AFTER_SECS ))
    recent_auth_fail=$(awk -v cutoff="$cutoff_epoch" '
        /^2[0-9]{3}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/ {
            ts = substr($1, 1, 19)
            gsub(/[TZ]/, " ", ts)
            cmd = "date -u -d \"" ts "\" +%s"
            cmd | getline epoch
            close(cmd)
            last_epoch = epoch
        }
        /Invalid username or token|Authentication failed/ {
            if (last_epoch >= cutoff) print
        }
    ' "$SYNC_LOG" | tail -3)
    if [[ -n "$recent_auth_fail" ]]; then
        alerts+=("recent GitHub authentication failures in $SYNC_LOG (last 15m)")
    fi
fi

if (( ${#alerts[@]} > 0 )); then
    state_log "ALERT: ${alerts[*]}"
    echo ":warning: *x404 knowledge-sync watchdog*"
    for a in "${alerts[@]}"; do
        echo "- $a"
    done
    echo "Check: journalctl --user -u $SERVICE -n 50 ; tail -n 50 $SYNC_LOG"
    exit 0
fi

state_log "OK"
exit 0

#!/bin/bash
set -euo pipefail

REPO_DIR="/data/runtime/hermes"
LOG="$REPO_DIR/logs/git-sync-runtime.log"

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" >> "$LOG"; }

log "Starting daily runtime git sync"

if systemctl --user is-failed hermes-gateway.service >/dev/null 2>&1; then
    log "ABORT: hermes-gateway.service is in a failed state, skipping sync"
    exit 1
fi

cd "$REPO_DIR"

git add -A

if git diff --cached --quiet; then
    log "No changes to commit, exiting"
    exit 0
fi

CHANGED=$(git diff --cached --name-only | wc -l)
git commit -q -m "Automated daily runtime sync — $(date -u +%Y-%m-%d)

$CHANGED file(s) changed."
log "Committed $CHANGED changed file(s)"

if git push origin main >> "$LOG" 2>&1; then
    log "Pushed to origin/main"
else
    log "ERROR: push failed, changes remain committed locally for next run"
    exit 1
fi

log "Daily runtime git sync complete"

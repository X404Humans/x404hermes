#!/bin/bash
set -euo pipefail

BACKUP_DIR="/data/backups/hermes-migration-20260815-041401"
TARGETS=(
    "$BACKUP_DIR/hermes-rw"
    "$BACKUP_DIR/hermes-stale-20260815-041523"
)
LOG="/data/runtime/hermes/logs/migration-cleanup.log"

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" >> "$LOG"; }

log "Starting migration backup cleanup"

for t in "${TARGETS[@]}"; do
    if [[ -d "$t" ]]; then
        rm -rf -- "$t"
        log "Removed $t"
    else
        log "Skipped (already absent): $t"
    fi
done

for t in "${TARGETS[@]}"; do
    if [[ -e "$t" ]]; then
        log "ERROR: $t still exists after rm -rf, aborting unit cleanup"
        exit 1
    fi
done

rmdir --ignore-fail-on-non-empty "$BACKUP_DIR" 2>/dev/null || true

log "Verified both targets removed. Disabling and removing cleanup systemd units."
systemctl --user disable --now hermes-migration-cleanup.timer >> "$LOG" 2>&1 || true
rm -f /data/.config/systemd/user/hermes-migration-cleanup.timer
rm -f /data/.config/systemd/user/hermes-migration-cleanup.service
systemctl --user daemon-reload >> "$LOG" 2>&1 || true

log "Cleanup complete. Removing this script."
rm -f -- "$0"

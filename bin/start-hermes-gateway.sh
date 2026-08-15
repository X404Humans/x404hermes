#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="/data/runtime/hermes-rw"
VENV="/data/runtime/hermes-slack-venv"
export HERMES_HOME
export XDG_STATE_HOME="$HERMES_HOME/.local/state"
export XDG_CACHE_HOME="$HERMES_HOME/.local/cache"
export XDG_DATA_HOME="$HERMES_HOME/.local/share"
export HOME="$HERMES_HOME"
mkdir -p "$HERMES_HOME"/.local/{state,cache,share}
mkdir -p "$HERMES_HOME"/{logs,sessions,skills,memories,pairing,cron,cache,audio_cache,image_cache}
exec "$VENV/bin/hermes" gateway run "$@"

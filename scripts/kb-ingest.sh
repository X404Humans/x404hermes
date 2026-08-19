#!/bin/bash
set -euo pipefail
export XDG_CONFIG_HOME=/data/runtime/config
export GH_CONFIG_DIR=/data/runtime/config/gh
export HOME=/data
exec /data/knowledge/.sync/kb-ingest.py

#!/bin/bash
# Bidirectional sync for a team knowledge base living in /data/knowledge.
# Pulls changes from GitHub, commits any local changes made on the VPS, and pushes.
# Intended to run from a Hermes cron job or system cron.

set -euo pipefail

KNOWLEDGE_DIR="/data/knowledge"
REMOTE="origin"
BRANCH="main"
COMMIT_MESSAGE="auto: sync knowledge base [hermes]"

# Source GitHub token from the active Hermes runtime .env if not already set
if [ -z "${GITHUB_TOKEN:-}" ]; then
  HERMES_ENV="${HERMES_HOME:-/data/runtime/hermes-rw}/.env"
  if [ -f "$HERMES_ENV" ] && grep -q "^GITHUB_TOKEN=" "$HERMES_ENV"; then
    export GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" "$HERMES_ENV" | head -1 | cut -d= -f2 | tr -d '\n\r')
  fi
fi

cd "$KNOWLEDGE_DIR"

# Ensure git identity is configured for commits
git config user.name "x404-hermes" 2>/dev/null || true
git config user.email "x404@agentmail.to" 2>/dev/null || true

# Pull latest changes from the team, rebasing any local commits on top
git pull --rebase "$REMOTE" "$BRANCH" || {
  echo "Failed to pull/rebase from $REMOTE/$BRANCH" >&2
  exit 1
}

# If there are local changes (e.g., ingested meeting notes), commit and push
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -m "$COMMIT_MESSAGE" || true
  git push "$REMOTE" "$BRANCH"
fi

#!/usr/bin/env bash
# deploy-app-pr.sh — verbose, safe PR flow:
# - sync local main from origin
# - commit ONLY app/ changes
# - create branch, push, open PR (or give you the link)
# - switch you back to main

set -euo pipefail
cd "$(dirname "$0")"

TITLE="${1:-Update app (HTML/CSS/JS)}"
BODY="${2:-Automated PR created by deploy-app-pr.sh}"

step() { printf '\n==> %s\n' "$*"; }

step "Syncing local 'main' from origin/main"
git fetch --prune origin
# ensure we are on main; create if missing
git switch main 2>/dev/null || git switch -c main
# fast-forward from origin/main; if diverged, stop with a clear message
if ! git pull --ff-only origin main; then
  echo "❌ Local 'main' diverged from origin. Run these once, then re-run this script:"
  echo "   git fetch origin"
  echo "   git reset --hard origin/main"
  exit 1
fi

step "Staging ONLY app/ changes"
git add -A -- app/

if git diff --cached --quiet; then
  echo "✅ No changes detected in app/ (nothing to commit)."
  exit 0
fi

BR="app-update-$(date +%Y%m%d-%H%M%S)"
step "Creating branch: $BR"
git switch -c "$BR"

step "Committing"
git commit -m "$TITLE"

step "Pushing '$BR' to origin"
git push -u origin "$BR"

PR_URL=""
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  step "Creating PR via GitHub CLI"
  gh pr create -B main -H "$BR" -t "$TITLE" -b "$BODY" >/dev/null
  PR_URL="$(gh pr view --json url -q .url || true)"
fi

if [[ -z "$PR_URL" ]]; then
  # Build compare URL if gh isn't available
  URL="$(git config --get remote.origin.url)"
  if [[ "$URL" =~ ^git@github\.com:(.+)/(.+)\.git$ ]]; then
    OWNER="${BASH_REMATCH[1]}"; REPO="${BASH_REMATCH[2]}"
  elif [[ "$URL" =~ ^https://github\.com/(.+)/(.+)\.git$ ]]; then
    OWNER="${BASH_REMATCH[1]}"; REPO="${BASH_REMATCH[2]}"
  else
    echo "Could not parse remote URL: $URL"; exit 1
  fi
  PR_URL="https://github.com/${OWNER}/${REPO}/compare/main...${BR}?expand=1"
fi

step "Switching you back to 'main'"
git switch main

echo
echo "📝 Open PR: $PR_URL"
command -v open >/dev/null && open "$PR_URL" || true

cat <<'NEXT'

Next in browser:
  1) Click “Create pull request”
  2) Wait for the PR check to turn green
  3) Click “Merge” (choose “Squash and merge”)

After merge: deploy runs automatically.

Tip: to see step-by-step shell debug, run:
  DEBUG=1 bash -x ./deploy-app-pr.sh
NEXT

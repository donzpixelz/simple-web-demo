#!/usr/bin/env bash
# deploy-app-pr.sh — clean PR flow: update main from origin, branch, commit ONLY app/, open/create PR, return to main

set -euo pipefail
cd "$(dirname "$0")"

TITLE="${1:-Update app (HTML/CSS/JS)}"
BODY="${2:-Automated PR created by deploy-app-pr.sh}"

echo "🔄 Making sure 'main' is up to date (from origin/main)..."
git fetch --prune origin
# Switch to main (create it if needed)
git switch main 2>/dev/null || git switch -c main
# Pull explicitly from origin/main (doesn't require upstream tracking)
git pull --ff-only origin main

echo "📦 Staging changes under app/..."
git add -A -- app/

if git diff --cached --quiet; then
  echo "✅ No changes detected in app/ (nothing to commit)."
  exit 0
fi

BR="app-update-$(date +%Y%m%d-%H%M%S)"
echo "🌱 Creating branch: $BR"
git switch -c "$BR"

echo "💾 Committing..."
git commit -m "$TITLE"

echo "📤 Pushing '$BR' to origin..."
git push -u origin "$BR"

PR_URL=""
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo "📝 Creating PR via GitHub CLI..."
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

echo "🧭 Switching you back to 'main' so your prompt looks normal..."
git switch main

echo "📝 Open PR: $PR_URL"
command -v open >/dev/null && open "$PR_URL" || true

cat <<'NEXT'
➡️  In the browser:
    1) Click “Create pull request”
    2) Wait for the PR check to turn green
    3) Click “Merge” (choose “Squash and merge”)

🚀 After merge, the deploy runs automatically.
🧹 Optional cleanup (after you merge):
    git fetch --prune
    git branch --merged main | egrep -v '(^\*|main)' | xargs -n 1 git branch -d
NEXT

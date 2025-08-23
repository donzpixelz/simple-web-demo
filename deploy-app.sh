#!/usr/bin/env bash
# deploy-app.sh — commit & push ONLY changes under app/, then print your site URL(s)

set -euo pipefail

# --- Settings (edit if needed) ---
AWS_REGION="us-east-2"
EC2_KEY_NAME="simple-web-demo-key"
FALLBACK_HOST_DNS="ec2-18-222-151-36.us-east-2.compute.amazonaws.com"
FALLBACK_HOST_IP="18.222.151.36"
PRIMARY_PORT=80
ALT_PORT=8080
# ---------------------------------

# cd to the directory this script lives in (repo root)
cd "$(dirname "$0")" || exit 1

# Resolve EC2 host:
# 1) DEPLOY_HOST env var, 2) .deploy-host file, 3) AWS CLI lookup, 4) fallback
get_host() {
  if [[ -n "${DEPLOY_HOST:-}" ]]; then
    echo "$DEPLOY_HOST"; return
  fi
  if [[ -f .deploy-host ]]; then
    local H
    H="$(head -n1 .deploy-host || true)"
    if [[ -n "$H" ]]; then echo "$H"; return; fi
  fi
  if command -v aws >/dev/null 2>&1; then
    local DNS
    DNS="$(aws ec2 describe-instances \
      --region "$AWS_REGION" \
      --filters "Name=key-name,Values=${EC2_KEY_NAME}" "Name=instance-state-name,Values=running" \
      --query "Reservations[].Instances[].PublicDnsName" --output text 2>/dev/null | head -n1 || true)"
    if [[ -n "$DNS" && "$DNS" != "None" ]]; then echo "$DNS"; return; fi
    local IP
    IP="$(aws ec2 describe-instances \
      --region "$AWS_REGION" \
      --filters "Name=key-name,Values=${EC2_KEY_NAME}" "Name=instance-state-name,Values=running" \
      --query "Reservations[].Instances[].PublicIpAddress" --output text 2>/dev/null | head -n1 || true)"
    if [[ -n "$IP" && "$IP" != "None" ]]; then echo "$IP"; return; fi
  fi
  if [[ -n "$FALLBACK_HOST_DNS" ]]; then echo "$FALLBACK_HOST_DNS"; else echo "$FALLBACK_HOST_IP"; fi
}

# Get an IPv4 for the plain link
get_ip() {
  local H="$1"
  if [[ "$H" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "$H"; return
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY 2>/dev/null || true
import socket,sys
print(socket.gethostbyname(sys.argv[1]))
PY
    return
  fi
  if command -v dig >/dev/null 2>&1; then
    dig +short "$H" A | head -n1
    return
  fi
  echo "$FALLBACK_HOST_IP"
}

HOST="$(get_host)"
IP="$(get_ip "$HOST")"

printf '📦 Checking for changes in app/...\n'

# Stage only app/ (the '--' guards against weird path matches)
git add -A -- app/

# If nothing is staged, bail out quietly but still show the URLs
if git diff --cached --quiet; then
  printf '✅ No changes detected in app/ (nothing to commit).\n'
  printf '🌐 Open:  http://%s/  (or http://%s:%s/)\n' "$HOST" "$HOST" "$ALT_PORT"
  [[ -n "$IP" ]] && printf '🔗 Plain: http://%s/\n' "$IP"
  exit 0
fi

printf '📤 Committing and pushing app/ changes...\n'
git commit -m "Update app (HTML/CSS/JS)"
git push origin main

printf '🚀 Done. Open:  http://%s/  (or http://%s:%s/)\n' "$HOST" "$HOST" "$ALT_PORT"
[[ -n "$IP" ]] && printf '🔗 Plain: http://%s/\n' "$IP"

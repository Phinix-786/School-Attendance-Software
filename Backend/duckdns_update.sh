#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# DuckDNS updater for your-domain.duckdns.org
# Checks current public IP vs what DuckDNS has; updates if needed.
# Run as a systemd timer (every 5 min) or cron.
#
# Required env vars (put in /etc/your-domain.env):
#   DUCKDNS_TOKEN=<your-duckdns-token>
#   DUCKDNS_DOMAIN=your-domain   # just the subdomain, not .duckdns.org
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ENV_FILE="${ENV_FILE:-/etc/your-domain.env}"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

: "${DUCKDNS_TOKEN:?DUCKDNS_TOKEN not set}"
: "${DUCKDNS_DOMAIN:?DUCKDNS_DOMAIN not set}"

LOG="/var/log/your-domain-duckdns.log"
touch "$LOG"

log() { echo "$(date -Iseconds) $*" | tee -a "$LOG"; }

# Get current public IP
CURRENT_IP=$(curl -sf https://api4.ipify.org || curl -sf https://checkip.amazonaws.com | tr -d '[:space:]')
if [[ -z "$CURRENT_IP" ]]; then
    log "ERROR: could not determine public IP"
    exit 1
fi

# Get IP DuckDNS currently knows about
DDNS_IP=$(dig +short "${DUCKDNS_DOMAIN}.duckdns.org" @8.8.8.8 | tail -1)

if [[ "$CURRENT_IP" == "$DDNS_IP" ]]; then
    log "IP unchanged ($CURRENT_IP) – no update needed"
    exit 0
fi

log "IP changed: $DDNS_IP -> $CURRENT_IP – updating DuckDNS"

RESULT=$(curl -sf \
    "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${CURRENT_IP}")

if [[ "$RESULT" == "OK" ]]; then
    log "DuckDNS update OK (${DUCKDNS_DOMAIN}.duckdns.org -> $CURRENT_IP)"
else
    log "ERROR: DuckDNS returned: $RESULT"
    exit 1
fi

#!/usr/bin/env bash
# 04-cloudflare.sh — Guide and verify Cloudflare Named Tunnel setup
# Run as: bash 04-cloudflare.sh
set -euo pipefail

HEALTH_STACK_DIR="$HOME/health-stack"
ENV_FILE="$HEALTH_STACK_DIR/.env.pi"

echo "============================================================"
echo " Cloudflare Named Tunnel Setup Guide"
echo "============================================================"
echo ""
echo " Steps to get your tunnel token:"
echo ""
echo " 1. Go to: https://one.dash.cloudflare.com"
echo " 2. Select your account → Zero Trust → Networks → Tunnels"
echo " 3. Click 'Create a tunnel' → name it (e.g. healthstack-pi)"
echo " 4. Choose 'Docker' as the connector"
echo " 5. Copy the token shown in the docker run command"
echo " 6. Under 'Public Hostname', add:"
echo "      Subdomain: app  (or leave empty)"
echo "      Domain:    (your Cloudflare-managed domain)"
echo "      Service:   http://localhost:80"
echo ""
echo " Once you have the token:"
echo "   nano $ENV_FILE"
echo "   → set EXPOSE_MODE=cloudflare"
echo "   → set CLOUDFLARE_TUNNEL_TOKEN=<paste-token>"
echo "   → update ALLOWED_ORIGINS in backend/.env to match tunnel URL"
echo "   Then: bash scripts/update.sh"
echo ""

if [ ! -f "$ENV_FILE" ]; then
    echo " .env.pi not found at $ENV_FILE"
    echo " Run 03-deploy.sh first."
    exit 0
fi

EXPOSE_MODE=$(grep '^EXPOSE_MODE=' "$ENV_FILE" | cut -d'=' -f2 | tr -d '[:space:]')
TOKEN=$(grep '^CLOUDFLARE_TUNNEL_TOKEN=' "$ENV_FILE" | cut -d'=' -f2 | tr -d '[:space:]')

echo "============================================================"
echo " Current status"
echo "============================================================"
echo " EXPOSE_MODE: ${EXPOSE_MODE}"

if [ -z "$TOKEN" ]; then
    echo " CLOUDFLARE_TUNNEL_TOKEN: (not set)"
else
    echo " CLOUDFLARE_TUNNEL_TOKEN: (set — ${#TOKEN} chars)"
fi

if [ "${EXPOSE_MODE}" = "cloudflare" ] && docker ps --format '{{.Names}}' 2>/dev/null | grep -q healthstack_tunnel; then
    echo ""
    echo " Tunnel container logs (last 15 lines):"
    docker logs healthstack_tunnel 2>&1 | tail -15
fi

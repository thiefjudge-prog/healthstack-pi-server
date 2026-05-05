#!/usr/bin/env bash
# update.sh — Pull latest code and restart containers
# Run as: bash ~/healthstack-pi-server/scripts/update.sh
set -euo pipefail

HEALTH_STACK_DIR="$HOME/health-stack"
OPS_REPO_DIR="$HOME/healthstack-pi-server"

echo "==> Pulling latest Health_Stack..."
git -C "$HEALTH_STACK_DIR" pull

echo "==> Pulling latest ops configs..."
git -C "$OPS_REPO_DIR" pull

echo "==> Copying updated configs..."
cp "$OPS_REPO_DIR/docker-compose.pi.yml" "$HEALTH_STACK_DIR/docker-compose.pi.yml"
cp -r "$OPS_REPO_DIR/nginx/" "$HEALTH_STACK_DIR/nginx/"

EXPOSE_MODE=$(grep '^EXPOSE_MODE=' "$HEALTH_STACK_DIR/.env.pi" | cut -d'=' -f2 | tr -d '[:space:]')
echo "==> Rebuilding and restarting (profile: ${EXPOSE_MODE})..."

cd "$HEALTH_STACK_DIR"
docker compose -f docker-compose.pi.yml \
    --env-file .env.pi \
    --profile "${EXPOSE_MODE}" \
    up -d --build

echo ""
echo "==> Update complete."
docker compose -f docker-compose.pi.yml ps

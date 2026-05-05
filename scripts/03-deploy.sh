#!/usr/bin/env bash
# 03-deploy.sh — Clone repos and launch HealthStack Pro on the Pi
# Run as: bash 03-deploy.sh
# Prerequisites: 01-system.sh and 02-docker.sh must have run first.
set -euo pipefail

HEALTH_STACK_DIR="$HOME/health-stack"
OPS_REPO_DIR="$HOME/healthstack-pi-server"

echo "==> Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker not found. Run 02-docker.sh first."; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "ERROR: Docker Compose not found. Run 02-docker.sh first."; exit 1; }

echo "==> Cloning Health_Stack..."
if [ -d "$HEALTH_STACK_DIR/.git" ]; then
    echo "    Already cloned — pulling latest..."
    git -C "$HEALTH_STACK_DIR" pull
else
    git clone https://github.com/RubenGZ/Health_Stack.git "$HEALTH_STACK_DIR"
fi

echo "==> Cloning healthstack-pi-server (ops)..."
if [ -d "$OPS_REPO_DIR/.git" ]; then
    echo "    Already cloned — pulling latest..."
    git -C "$OPS_REPO_DIR" pull
else
    git clone https://github.com/thiefjudge-prog/healthstack-pi-server.git "$OPS_REPO_DIR"
fi

echo "==> Copying Pi configs into Health_Stack directory..."
cp "$OPS_REPO_DIR/docker-compose.pi.yml" "$HEALTH_STACK_DIR/docker-compose.pi.yml"
cp -r "$OPS_REPO_DIR/nginx/" "$HEALTH_STACK_DIR/nginx/"

echo "==> Checking environment files..."
if [ ! -f "$HEALTH_STACK_DIR/.env.pi" ]; then
    cp "$OPS_REPO_DIR/templates/.env.pi.example" "$HEALTH_STACK_DIR/.env.pi"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  ACTION REQUIRED: Edit $HEALTH_STACK_DIR/.env.pi"
    echo "  │  At minimum set: POSTGRES_PASSWORD, REDIS_PASSWORD, EXPOSE_MODE │"
    echo "  │  Then re-run: bash 03-deploy.sh                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    exit 1
fi

if [ ! -f "$HEALTH_STACK_DIR/backend/.env" ]; then
    cp "$OPS_REPO_DIR/templates/backend.env.example" "$HEALTH_STACK_DIR/backend/.env"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  ACTION REQUIRED: Edit $HEALTH_STACK_DIR/backend/.env          │"
    echo "  │  Set: JWT_PRIVATE_KEY_PEM, JWT_PUBLIC_KEY_PEM,                 │"
    echo "  │       HEALTH_LINK_MASTER_KEY, ALLOWED_ORIGINS                  │"
    echo "  │  Then re-run: bash 03-deploy.sh                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    exit 1
fi

EXPOSE_MODE=$(grep '^EXPOSE_MODE=' "$HEALTH_STACK_DIR/.env.pi" | cut -d'=' -f2 | tr -d '[:space:]')
echo "==> EXPOSE_MODE=${EXPOSE_MODE}"

echo "==> Building and launching containers (profile: ${EXPOSE_MODE})..."
echo "    (First build takes 5-15 min on Pi 3B — be patient)"
cd "$HEALTH_STACK_DIR"
docker compose -f docker-compose.pi.yml \
    --env-file .env.pi \
    --profile "${EXPOSE_MODE}" \
    up -d --build

echo ""
echo "==> Waiting for backend to start..."
sleep 15
docker compose -f docker-compose.pi.yml ps

echo ""
echo "==> Deploy complete!"
if [ "${EXPOSE_MODE}" = "quick" ]; then
    echo ""
    echo "  Cloudflare Quick Tunnel URL (may take 30s to appear):"
    docker logs healthstack_tunnel_quick 2>&1 | grep -i "trycloudflare\|https://" | tail -5 || \
        echo "  Run: docker logs healthstack_tunnel_quick"
fi

#!/usr/bin/env bash
# 02-docker.sh — Install Docker Engine + Compose plugin on Raspberry Pi OS 64-bit
# Run as: bash 02-docker.sh
set -euo pipefail

if command -v docker &>/dev/null; then
    echo "==> Docker already installed: $(docker --version)"
    docker compose version
    exit 0
fi

echo "==> Installing Docker Engine (arm64)..."
curl -fsSL https://get.docker.com | sh

echo "==> Adding ${USER} to docker group (no sudo needed after re-login)..."
sudo usermod -aG docker "$USER"

echo "==> Enabling Docker on boot..."
sudo systemctl enable docker
sudo systemctl start docker

echo ""
echo "==> Docker installed: $(docker --version)"
echo "==> Docker Compose: $(docker compose version)"
echo ""
echo "IMPORTANT: Log out and back in (or run 'newgrp docker') before using Docker."

#!/usr/bin/env bash
# 01-system.sh — OS prep for Raspberry Pi 3B (1 GB RAM, 64 GB SD)
# Run as: bash 01-system.sh
set -euo pipefail

echo "==> Updating OS packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

echo "==> Configuring 1 GB swap..."
sudo dphys-swapfile swapoff 2>/dev/null || true
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
echo "    Swap:"
free -h | grep Swap

echo "==> Reducing GPU memory split to 16 MB (headless server)..."
if grep -q "^gpu_mem=" /boot/firmware/config.txt 2>/dev/null; then
    sudo sed -i 's/^gpu_mem=.*/gpu_mem=16/' /boot/firmware/config.txt
elif grep -q "^gpu_mem=" /boot/config.txt 2>/dev/null; then
    sudo sed -i 's/^gpu_mem=.*/gpu_mem=16/' /boot/config.txt
else
    echo "gpu_mem=16" | sudo tee -a /boot/firmware/config.txt
fi

echo "==> Disabling Wi-Fi power management (prevents random drops)..."
sudo iwconfig wlan0 power off 2>/dev/null || echo "    (wlan0 not found — skipped)"

echo "==> Installing useful tools..."
sudo apt-get install -y -qq git curl jq

echo ""
echo "==> Done. Reboot recommended to apply GPU memory split:"
echo "    sudo reboot"

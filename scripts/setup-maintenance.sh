#!/usr/bin/env bash
set -euo pipefail

# System maintenance extras:
# - fwupd service/timer for firmware updates
# - zram-generator configuration

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

sudo pacman -S --needed --noconfirm fwupd zram-generator

sudo systemctl enable --now fwupd.service || true
sudo systemctl enable --now fwupd-refresh.timer || true

# Conservative zram setup sized from available memory.
sudo install -d -m 755 /etc/systemd
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOCFG'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOCFG

# Restart generator + target. Swap activation can require reboot on some setups.
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

echo "Maintenance setup complete (fwupd + zram-generator)."

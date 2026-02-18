#!/usr/bin/env bash
set -euo pipefail

# Configure reflector periodic mirror refresh.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

sudo pacman -S --needed --noconfirm reflector
sudo install -d -m 755 /etc/xdg/reflector

sudo tee /etc/xdg/reflector/reflector.conf >/dev/null <<'EOCFG'
--country US
--latest 25
--protocol https
--sort rate
--save /etc/pacman.d/mirrorlist
EOCFG

sudo systemctl enable --now reflector.timer

echo "Reflector timer configured and enabled."

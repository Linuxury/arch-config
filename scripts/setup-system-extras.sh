#!/usr/bin/env bash
set -euo pipefail

# Install and configure requested system extras.
# Includes: reflector, flatpak, ufw, bluez stack, fstrim timer.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

sudo pacman -S --needed --noconfirm \
  reflector flatpak ufw bluez bluez-utils

sudo systemctl enable --now bluetooth
sudo systemctl enable --now fstrim.timer

# Firewall policy: safe default for local machine use.
# Skip auto-enable on SSH sessions to avoid accidental remote lockout.
if [[ -n "${SSH_CONNECTION:-}" ]]; then
  echo "SSH session detected; installed ufw but skipped auto-enable."
  echo "Enable manually when ready: sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw enable"
else
  ufw_status="$(sudo ufw status || true)"
  if command -v rg >/dev/null 2>&1; then
    if ! printf '%s\n' "${ufw_status}" | rg -qi "Status: active"; then
      sudo ufw default deny incoming
      sudo ufw default allow outgoing
      sudo ufw --force enable
    fi
  elif ! printf '%s\n' "${ufw_status}" | grep -qi "Status: active"; then
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw --force enable
  fi
fi

echo "System extras setup complete."

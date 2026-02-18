#!/usr/bin/env bash
set -euo pipefail

# Service/infrastructure layer.
# Env toggles:
#   ENABLE_LAPTOP=0|1
#   ENABLE_REFLECTOR_TIMER=0|1
#   ENABLE_FWUPD=0|1
#   ENABLE_ZRAM=0|1
#   ENABLE_SSH_HARDENING=0|1

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENABLE_LAPTOP="${ENABLE_LAPTOP:-0}"
ENABLE_REFLECTOR_TIMER="${ENABLE_REFLECTOR_TIMER:-1}"
ENABLE_FWUPD="${ENABLE_FWUPD:-1}"
ENABLE_ZRAM="${ENABLE_ZRAM:-1}"
ENABLE_SSH_HARDENING="${ENABLE_SSH_HARDENING:-1}"

if [[ -x "${SCRIPT_DIR}/setup-system-extras.sh" ]]; then
  "${SCRIPT_DIR}/setup-system-extras.sh"
fi

if [[ "${ENABLE_REFLECTOR_TIMER}" == "1" && -x "${SCRIPT_DIR}/setup-reflector-timer.sh" ]]; then
  "${SCRIPT_DIR}/setup-reflector-timer.sh"
fi

sudo pacman -S --needed --noconfirm tailscale power-profiles-daemon
sudo systemctl enable --now tailscaled
sudo systemctl enable --now power-profiles-daemon

if [[ "${ENABLE_FWUPD}" == "1" || "${ENABLE_ZRAM}" == "1" ]]; then
  if [[ -x "${SCRIPT_DIR}/setup-maintenance.sh" ]]; then
    "${SCRIPT_DIR}/setup-maintenance.sh"
  fi
fi

if [[ "${ENABLE_SSH_HARDENING}" == "1" && -x "${SCRIPT_DIR}/setup-ssh-hardening.sh" ]]; then
  "${SCRIPT_DIR}/setup-ssh-hardening.sh"
fi

if [[ "${ENABLE_LAPTOP}" == "1" && -x "${SCRIPT_DIR}/setup-laptop.sh" ]]; then
  "${SCRIPT_DIR}/setup-laptop.sh"
fi

#!/usr/bin/env bash
set -euo pipefail

# Core platform install layer.
# Usage: ./scripts/install-core.sh [zen-lts|mainline-zen|zen-stable|none]
# Env toggles:
#   INSTALL_MICROCODE=1 INSTALL_GPU=1 CONFIGURE_BOOT=1 CONFIGURE_SNAPSHOTS=1

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_PROFILE="${1:-zen-lts}"
INSTALL_MICROCODE="${INSTALL_MICROCODE:-1}"
INSTALL_GPU="${INSTALL_GPU:-1}"
CONFIGURE_BOOT="${CONFIGURE_BOOT:-1}"
CONFIGURE_SNAPSHOTS="${CONFIGURE_SNAPSHOTS:-1}"

install_kernels() {
  case "${KERNEL_PROFILE}" in
    zen-lts)
      sudo pacman -S --needed --noconfirm \
        linux-zen linux-zen-headers \
        linux-lts linux-lts-headers
      ;;
    mainline-zen)
      if pacman -Si linux-mainline >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm \
          linux-mainline linux-mainline-headers \
          linux-zen linux-zen-headers
      else
        echo "linux-mainline is not in enabled repos. Falling back to zen-lts profile."
        KERNEL_PROFILE="zen-lts"
        sudo pacman -S --needed --noconfirm \
          linux-zen linux-zen-headers \
          linux-lts linux-lts-headers
      fi
      ;;
    zen-stable)
      sudo pacman -S --needed --noconfirm \
        linux-zen linux-zen-headers \
        linux linux-headers
      ;;
    none)
      echo "Skipping kernel package changes."
      ;;
    *)
      echo "Unknown kernel profile: ${KERNEL_PROFILE}" >&2
      echo "Use one of: zen-lts, mainline-zen, zen-stable, none" >&2
      exit 1
      ;;
  esac
}

if ! sudo -n true 2>/dev/null; then
  echo "Sudo credentials required. You may be prompted." >&2
fi

sudo pacman -Syu --noconfirm
install_kernels

sudo pacman -S --needed --noconfirm \
  networkmanager \
  pipewire pipewire-pulse wireplumber \
  xdg-desktop-portal xdg-desktop-portal-gtk \
  greetd \
  systemd-boot-pacman-hook \
  snapper snap-pac btrfs-assistant \
  fish fastfetch starship

if pacman -Si ghostty >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm ghostty
else
  echo "ghostty is not in enabled repos. Install from AUR or another source if needed."
fi

sudo systemctl enable --now NetworkManager
if [[ -L /etc/systemd/system/display-manager.service ]]; then
  current_dm_target="$(readlink -f /etc/systemd/system/display-manager.service || true)"
  if [[ "${current_dm_target}" == *"/greetd.service" ]]; then
    sudo systemctl enable --now greetd
  else
    echo "Display manager already configured (${current_dm_target}). Skipping greetd enable."
  fi
else
  sudo systemctl enable --now greetd
fi

if [[ "${INSTALL_MICROCODE}" == "1" && -x "${SCRIPT_DIR}/install-microcode.sh" ]]; then
  "${SCRIPT_DIR}/install-microcode.sh" auto
fi

if [[ "${INSTALL_GPU}" == "1" && -x "${SCRIPT_DIR}/install-gpu-drivers.sh" ]]; then
  "${SCRIPT_DIR}/install-gpu-drivers.sh" auto
fi

if [[ "${CONFIGURE_BOOT}" == "1" && -x "${SCRIPT_DIR}/configure-systemd-boot.sh" ]]; then
  case "${KERNEL_PROFILE}" in
    mainline-zen)
      sudo "${SCRIPT_DIR}/configure-systemd-boot.sh" linux-mainline linux-zen
      ;;
    zen-stable)
      sudo "${SCRIPT_DIR}/configure-systemd-boot.sh" linux-zen linux
      ;;
    *)
      sudo "${SCRIPT_DIR}/configure-systemd-boot.sh" linux-zen linux-lts
      ;;
  esac
fi

if [[ "${CONFIGURE_SNAPSHOTS}" == "1" && -x "${SCRIPT_DIR}/setup-btrfs-snapshots.sh" ]]; then
  sudo "${SCRIPT_DIR}/setup-btrfs-snapshots.sh"
fi

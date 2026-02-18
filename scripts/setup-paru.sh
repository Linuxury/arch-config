#!/usr/bin/env bash
set -euo pipefail

# Install paru AUR helper.
# Tries repo package first, then falls back to building from AUR as non-root user.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

if command -v paru >/dev/null 2>&1; then
  echo "paru is already installed."
  exit 0
fi

if pacman -Si paru >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm paru
  echo "Installed paru from enabled repositories."
  exit 0
fi

sudo pacman -S --needed --noconfirm git base-devel

workdir="$(mktemp -d /tmp/paru-build.XXXXXX)"
trap 'rm -rf "${workdir}"' EXIT

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run this script as root for AUR build fallback." >&2
  exit 1
fi

git clone https://aur.archlinux.org/paru.git "${workdir}/paru"
(
  cd "${workdir}/paru"
  makepkg -si --noconfirm
)

echo "Installed paru from AUR build fallback."

#!/usr/bin/env bash
set -euo pipefail

# Install baseline gaming stack.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/install-utils.sh"

pacman_install_prompt "gaming bundle" \
  steam lutris gamemode mangohud goverlay \
  wine-staging winetricks \
  gamescope \
  lib32-mesa lib32-vulkan-icd-loader \
  vulkan-tools

echo "Gaming stack installed."
echo "Steam launch option tip: gamemoderun mangohud %command%"

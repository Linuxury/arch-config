#!/usr/bin/env bash
set -euo pipefail

# Configure Chaotic-AUR repository on Arch Linux.
# Source: https://aur.chaotic.cx/

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  sudo pacman-key --lsign-key 3056513887B78AEB
  sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

  tmp_conf="$(mktemp /tmp/pacman.conf.XXXXXX)"
  cp /etc/pacman.conf "${tmp_conf}"
  {
    echo
    echo '[chaotic-aur]'
    echo 'Include = /etc/pacman.d/chaotic-mirrorlist'
  } >> "${tmp_conf}"
  sudo install -m 644 "${tmp_conf}" /etc/pacman.conf
  rm -f "${tmp_conf}"

  sudo pacman -Sy
  echo "Chaotic-AUR repository added."
else
  echo "Chaotic-AUR already configured in /etc/pacman.conf."
fi

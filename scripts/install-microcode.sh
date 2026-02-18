#!/usr/bin/env bash
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

if ! command -v lscpu >/dev/null 2>&1; then
  echo "Missing lscpu (from util-linux)." >&2
  exit 1
fi

MODE="${1:-auto}"
CPU_VENDOR="$(lscpu | awk -F: '/Vendor ID/{gsub(/^[ \t]+/,"",$2); print $2; exit}')"

install_amd() {
  sudo pacman -S --needed --noconfirm amd-ucode
  echo "Installed AMD microcode package: amd-ucode"
}

install_intel() {
  sudo pacman -S --needed --noconfirm intel-ucode
  echo "Installed Intel microcode package: intel-ucode"
}

case "${MODE}" in
  auto)
    case "${CPU_VENDOR}" in
      GenuineIntel) install_intel ;;
      AuthenticAMD) install_amd ;;
      *)
        echo "Unknown CPU vendor: ${CPU_VENDOR:-unknown}."
        echo "Run manually with: ./scripts/install-microcode.sh intel|amd"
        ;;
    esac
    ;;
  intel)
    install_intel
    ;;
  amd)
    install_amd
    ;;
  both)
    install_intel
    install_amd
    ;;
  *)
    echo "Usage: $0 [auto|intel|amd|both]" >&2
    exit 1
    ;;
esac

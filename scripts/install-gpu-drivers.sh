#!/usr/bin/env bash
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

if ! command -v lspci >/dev/null 2>&1; then
  echo "Missing lspci (from pciutils)." >&2
  exit 1
fi

MODE="${1:-auto}"
GPU_LINES="$(lspci -nn | rg -i 'vga|3d|display' || true)"

install_intel() {
  sudo pacman -S --needed --noconfirm mesa vulkan-intel lib32-vulkan-intel
}

install_amd() {
  sudo pacman -S --needed --noconfirm mesa vulkan-radeon lib32-vulkan-radeon
}

install_nvidia_proprietary() {
  sudo pacman -S --needed --noconfirm nvidia nvidia-utils lib32-nvidia-utils
}

install_nvidia_open() {
  sudo pacman -S --needed --noconfirm nvidia-open nvidia-utils lib32-nvidia-utils
}

install_common_helpers() {
  sudo pacman -S --needed --noconfirm mesa-utils vulkan-tools
}

auto_detect_install() {
  local did_install=0

  if echo "${GPU_LINES}" | rg -qi 'intel'; then
    install_intel
    did_install=1
  fi

  if echo "${GPU_LINES}" | rg -qi 'amd|advanced micro devices|ati'; then
    install_amd
    did_install=1
  fi

  if echo "${GPU_LINES}" | rg -qi 'nvidia'; then
    install_nvidia_open
    echo "Installed NVIDIA open kernel module stack."
    echo "If unsupported on your GPU, switch to proprietary: ./scripts/install-gpu-drivers.sh nvidia"
    did_install=1
  fi

  if [[ "${did_install}" -eq 0 ]]; then
    echo "Could not auto-detect a supported GPU from lspci output."
    echo "Detected lines:"
    echo "${GPU_LINES:-<none>}"
    echo "Run manually with: ./scripts/install-gpu-drivers.sh intel|amdgpu|nvidia|nvidia-open|all-open"
  fi
}

case "${MODE}" in
  auto)
    auto_detect_install
    ;;
  intel)
    install_intel
    ;;
  amdgpu|amd)
    install_amd
    ;;
  nvidia)
    install_nvidia_proprietary
    ;;
  nvidia-open)
    install_nvidia_open
    ;;
  all-open)
    install_intel
    install_amd
    install_nvidia_open
    ;;
  *)
    echo "Usage: $0 [auto|intel|amdgpu|amd|nvidia|nvidia-open|all-open]" >&2
    exit 1
    ;;
esac

install_common_helpers

echo "GPU setup step complete. Reboot is recommended."

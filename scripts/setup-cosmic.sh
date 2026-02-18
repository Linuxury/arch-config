#!/usr/bin/env bash
set -euo pipefail

# Install COSMIC components where available.
# Tries enabled pacman repos first, then AUR via paru if available.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/install-utils.sh"

REPORT_FILE="${REPORT_FILE:-}"

report_item() {
  local status="$1"
  local item="$2"
  if [[ -n "${REPORT_FILE}" ]]; then
    echo "cosmic|${status}|${item}" >> "${REPORT_FILE}"
  fi
}

install_repo() {
  local pkg="$1"
  if pacman -Si "$pkg" >/dev/null 2>&1; then
    pacman_install_prompt "$pkg" "$pkg"
    report_item "installed" "$pkg"
    return 0
  fi
  return 1
}

install_aur() {
  local pkg="$1"
  if command -v paru >/dev/null 2>&1 && paru -Si "$pkg" >/dev/null 2>&1; then
    paru_install_prompt "$pkg" "$pkg"
    report_item "installed" "$pkg"
    return 0
  fi
  return 1
}

# Conservative list of common COSMIC package names/candidates.
candidates=(
  cosmic-greeter
  cosmic-session
  cosmic-desktop
  cosmic-comp
  cosmic-applets
  cosmic-launcher
  cosmic-settings
  cosmic-files
  cosmic-terminal
  cosmic-edit
  cosmic-store
)

installed=0
for pkg in "${candidates[@]}"; do
  if install_repo "$pkg"; then
    echo "Installed COSMIC package from repo: $pkg"
    installed=1
  elif install_aur "$pkg"; then
    echo "Installed COSMIC package from AUR: $pkg"
    installed=1
  else
    report_item "unavailable" "$pkg"
  fi
done

if [[ "$installed" -eq 0 ]]; then
  echo "No COSMIC candidates were installed automatically."
  echo "Check availability with: pacman -Ss cosmic"
  if command -v paru >/dev/null 2>&1; then
    echo "Also check AUR with: paru -Ss cosmic"
  fi
else
  echo "COSMIC setup step complete."
fi

if [[ -x "${SCRIPT_DIR}/configure-greetd-cosmic.sh" ]]; then
  "${SCRIPT_DIR}/configure-greetd-cosmic.sh"
fi

if [[ -n "${REPORT_FILE}" ]]; then
  installed_count="$(awk -F'|' '$1=="cosmic" && $2=="installed"{c++} END{print c+0}' "${REPORT_FILE}")"
  unavailable_count="$(awk -F'|' '$1=="cosmic" && $2=="unavailable"{c++} END{print c+0}' "${REPORT_FILE}")"
  echo "COSMIC report: installed=${installed_count} unavailable=${unavailable_count}"
fi

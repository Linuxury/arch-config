#!/usr/bin/env bash
set -euo pipefail

# Install requested desktop apps.
# Uses pacman first, then paru for AUR-only packages.

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
    echo "apps|${status}|${item}" >> "${REPORT_FILE}"
  fi
}

install_repo_if_available() {
  local pkg="$1"
  if pacman -Si "$pkg" >/dev/null 2>&1; then
    pacman_install_prompt "$pkg" "$pkg"
    report_item "installed" "$pkg"
    return 0
  fi
  return 1
}

install_first_repo_candidate() {
  local name="$1"
  shift
  local cand
  for cand in "$@"; do
    if install_repo_if_available "$cand"; then
      echo "Installed ${name}: ${cand}"
      return 0
    fi
  done
  echo "Could not install ${name} from enabled repositories." >&2
  return 1
}

install_aur_if_available() {
  local pkg="$1"
  if ! command -v paru >/dev/null 2>&1; then
    return 1
  fi
  if paru -Si "$pkg" >/dev/null 2>&1; then
    paru_install_prompt "$pkg" "$pkg"
    report_item "installed" "$pkg"
    return 0
  fi
  return 1
}

install_first_aur_candidate() {
  local name="$1"
  shift
  local cand
  for cand in "$@"; do
    if install_aur_if_available "$cand"; then
      echo "Installed ${name}: ${cand}"
      return 0
    fi
  done
  echo "Could not install ${name} from AUR candidates." >&2
  return 1
}

# Core packages requested.
repo_packages=(
  topgrade
  thunderbird
  firefox
  helix
  gnome-disk-utility
  flatpak
  loupe
  amberol
  showtime
  papers
)

for pkg in "${repo_packages[@]}"; do
  if ! install_repo_if_available "$pkg"; then
    report_item "unavailable" "$pkg"
    echo "Skipping unavailable repo package: $pkg"
  fi
done

# Nerd fonts: install first matching candidate.
install_first_repo_candidate "nerd-fonts" \
  ttf-jetbrains-mono-nerd \
  ttf-firacode-nerd \
  nerd-fonts || report_item "unavailable" "nerd-fonts"

# OnlyOffice candidates (repo or AUR depending on setup).
if ! install_first_repo_candidate "OnlyOffice" onlyoffice-desktopeditors onlyoffice 2>/dev/null; then
  install_first_aur_candidate "OnlyOffice" onlyoffice-bin onlyoffice-desktopeditors-bin || report_item "unavailable" "OnlyOffice"
fi

# Zed candidates.
if ! install_first_repo_candidate "Zed" zed zed-preview 2>/dev/null; then
  install_first_aur_candidate "Zed" zed-bin zed-preview-bin || report_item "unavailable" "Zed"
fi

# AUR targets requested.
aur_packages=(
  protonplus
  fluent-reader-bin
  sgdboop-bin
  lsfg-vk-git
)

for pkg in "${aur_packages[@]}"; do
  if ! install_aur_if_available "$pkg"; then
    report_item "unavailable" "$pkg"
    echo "Skipping unavailable AUR package: $pkg"
  fi
done

if [[ -n "${REPORT_FILE}" ]]; then
  installed_count="$(awk -F'|' '$1=="apps" && $2=="installed"{c++} END{print c+0}' "${REPORT_FILE}")"
  unavailable_count="$(awk -F'|' '$1=="apps" && $2=="unavailable"{c++} END{print c+0}' "${REPORT_FILE}")"
  echo "Apps report: installed=${installed_count} unavailable=${unavailable_count}"
fi

echo "Apps setup complete."

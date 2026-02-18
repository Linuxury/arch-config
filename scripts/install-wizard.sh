#!/usr/bin/env bash
set -euo pipefail

# Interactive post-install wizard for this repo.
# Flow: minimal archinstall -> clone repo -> run this script.
# Usage: ./scripts/install-wizard.sh [--dry-run]

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_PROFILE="zen-lts"
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--dry-run]" >&2
      exit 1
      ;;
  esac
done

mkdir -p "${SCRIPT_DIR}/../logs"
LOG_FILE="${SCRIPT_DIR}/../logs/install-wizard-$(date +%Y%m%d-%H%M%S).log"
REPORT_FILE="$(mktemp /tmp/arch-wizard-report.XXXXXX)"
trap 'rm -f "${REPORT_FILE}"' EXIT
export REPORT_FILE

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "Log file: ${LOG_FILE}"
echo "Dry run: ${DRY_RUN}"

print_section() {
  local title="$1"
  local desc="$2"
  echo
  echo "== ${title} =="
  echo "${desc}"
}

ask_yes_no() {
  local prompt="$1"
  local default_yes="${2:-yes}"
  local answer

  while true; do
    if [[ "${default_yes}" == "yes" ]]; then
      read -r -p "${prompt} [Y/n]: " answer || true
      answer="${answer:-Y}"
    else
      read -r -p "${prompt} [y/N]: " answer || true
      answer="${answer:-N}"
    fi

    case "${answer}" in
      Y|y|yes|YES) return 0 ;;
      N|n|no|NO) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

choose_kernel_profile() {
  echo
  echo "Kernel profiles:"
  echo "  1) zen-lts      (recommended: zen main + lts fallback)"
  echo "  2) mainline-zen (rc/mainline main + zen fallback)"
  echo "  3) zen-stable   (zen main + stable fallback)"
  echo "  4) none         (skip kernel package changes)"

  while true; do
    read -r -p "Choose profile [1-4] (default 1): " choice || true
    choice="${choice:-1}"
    case "${choice}" in
      1) KERNEL_PROFILE="zen-lts"; return 0 ;;
      2) KERNEL_PROFILE="mainline-zen"; return 0 ;;
      3) KERNEL_PROFILE="zen-stable"; return 0 ;;
      4) KERNEL_PROFILE="none"; return 0 ;;
      *) echo "Please choose 1, 2, 3, or 4." ;;
    esac
  done
}

detect_chassis() {
  local chassis
  chassis="$(hostnamectl chassis 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  if [[ -z "${chassis}" || "${chassis}" == "n/a" ]]; then
    if [[ -r /sys/class/dmi/id/chassis_type ]]; then
      case "$(cat /sys/class/dmi/id/chassis_type)" in
        8|9|10|14) chassis="laptop" ;;
        3|4|5|6|7|15|16) chassis="desktop" ;;
        *) chassis="unknown" ;;
      esac
    else
      chassis="unknown"
    fi
  fi
  echo "${chassis}"
}

has_battery() {
  compgen -G "/sys/class/power_supply/BAT*" >/dev/null 2>&1
}

has_fingerprint_candidate() {
  local fp_pattern='fingerprint|fpc|goodix|synaptics|elan|validity|upek|egis'
  if command -v lsusb >/dev/null 2>&1 && lsusb | rg -qi "${fp_pattern}"; then
    return 0
  fi
  if command -v lspci >/dev/null 2>&1 && lspci -nn | rg -qi "${fp_pattern}"; then
    return 0
  fi
  return 1
}

section_status() {
  local status="$1"
  local section="$2"
  echo "section|${status}|${section}" >> "${REPORT_FILE}"
}

run_step() {
  local section="$1"
  shift
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "[DRY-RUN] ${section}: $*"
    section_status "skipped" "${section}"
    return 0
  fi

  while true; do
    echo "[RUN] ${section}"
    if "$@"; then
      section_status "installed" "${section}"
      return 0
    fi

    echo "Section '${section}' failed."
    if [[ ! -t 0 && ! -r /dev/tty ]]; then
      section_status "failed" "${section}"
      return 1
    fi

    if [[ -w /dev/tty ]]; then
      echo "Choose action for '${section}': [r]etry, [s]kip section, [a]bort" > /dev/tty
      read -r -p "> " step_choice < /dev/tty || true
    else
      echo "Choose action for '${section}': [r]etry, [s]kip section, [a]bort"
      read -r -p "> " step_choice || true
    fi
    case "${step_choice:-a}" in
      r|R)
        continue
        ;;
      s|S)
        section_status "skipped" "${section}"
        return 0
        ;;
      a|A)
        section_status "failed" "${section}"
        return 1
        ;;
      *)
        echo "Please choose r, s, or a."
        ;;
    esac
  done
}

create_checkpoint() {
  local label="$1"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    return 0
  fi
  if [[ "$(findmnt -no FSTYPE / 2>/dev/null || true)" != "btrfs" ]]; then
    return 0
  fi
  if ! command -v snapper >/dev/null 2>&1; then
    return 0
  fi
  if [[ ! -f /etc/snapper/configs/root ]]; then
    return 0
  fi
  sudo snapper -c root create -d "${label}" || echo "Warning: failed to create snapshot checkpoint: ${label}"
}

print_report() {
  echo
  echo "== Install Summary =="
  for sec in core repos services userland postflight; do
    s="$(awk -F'|' -v sec="$sec" '$1=="section" && $3==sec {print $2; exit}' "${REPORT_FILE}")"
    if [[ -z "$s" ]]; then
      s="skipped"
    fi
    printf '%-10s %s\n' "${sec}:" "${s}"
  done

  for sec in apps cosmic; do
    installed_count="$(awk -F'|' -v sec="$sec" '$1==sec && $2=="installed"{c++} END{print c+0}' "${REPORT_FILE}")"
    unavailable_count="$(awk -F'|' -v sec="$sec" '$1==sec && $2=="unavailable"{c++} END{print c+0}' "${REPORT_FILE}")"
    if [[ "${installed_count}" -gt 0 || "${unavailable_count}" -gt 0 ]]; then
      printf '%-10s installed=%s unavailable=%s\n' "${sec}:" "${installed_count}" "${unavailable_count}"
    fi
  done
}

# Detect profile hints.
CHASSIS="$(detect_chassis)"
BATTERY_DETECTED="no"
FINGERPRINT_HINT="no"
IS_LAPTOP="no"

if has_battery; then
  BATTERY_DETECTED="yes"
fi

if has_fingerprint_candidate; then
  FINGERPRINT_HINT="yes"
fi

case "${CHASSIS}" in
  laptop|notebook|portable|tablet) IS_LAPTOP="yes" ;;
esac

if [[ "${BATTERY_DETECTED}" == "yes" ]]; then
  IS_LAPTOP="yes"
fi

print_section "Hardware Detection" "Detected hardware profile and proposed defaults."
echo "Detected chassis: ${CHASSIS}"
echo "Battery detected: ${BATTERY_DETECTED}"
echo "Fingerprint device hint: ${FINGERPRINT_HINT}"

if [[ "${IS_LAPTOP}" == "yes" ]]; then
  echo "Proposed profile: laptop"
else
  echo "Proposed profile: desktop"
fi

USE_LAPTOP_DEFAULT="${IS_LAPTOP}"
if ask_yes_no "Use these defaults as starting point?" yes; then
  :
else
  if ask_yes_no "Set starting profile to laptop?" no; then
    USE_LAPTOP_DEFAULT="yes"
  else
    USE_LAPTOP_DEFAULT="no"
  fi
fi

# Selection state.
section_core="no"
section_repos="no"
section_services="no"
section_userland="no"

opt_microcode="yes"
opt_gpu="yes"
opt_boot="yes"
opt_snapshots="yes"
opt_chaotic="yes"
opt_paru="yes"
opt_laptop="no"
opt_reflector_timer="yes"
opt_fwupd="yes"
opt_zram="yes"
opt_ssh_hardening="yes"
opt_apps="yes"
opt_dev="yes"
opt_gaming="yes"
opt_cosmic="yes"
opt_postflight="yes"

if [[ "${USE_LAPTOP_DEFAULT}" == "yes" ]]; then
  opt_laptop="yes"
fi

print_section "Core Layer" "Base OS stack: kernel, network/audio/session baseline, microcode/GPU, bootloader config, and Btrfs snapshots."
if ask_yes_no "Install core layer?" yes; then
  section_core="yes"
  choose_kernel_profile
  if ask_yes_no "Install CPU microcode?" "${opt_microcode}"; then opt_microcode="yes"; else opt_microcode="no"; fi
  if ask_yes_no "Install GPU drivers?" "${opt_gpu}"; then opt_gpu="yes"; else opt_gpu="no"; fi
  if ask_yes_no "Configure systemd-boot quiet default + fallback?" "${opt_boot}"; then opt_boot="yes"; else opt_boot="no"; fi
  if ask_yes_no "Configure Btrfs snapshots (Snapper) when root is Btrfs?" "${opt_snapshots}"; then opt_snapshots="yes"; else opt_snapshots="no"; fi
fi

print_section "Repo Layer" "Repository/AUR setup: Chaotic-AUR and paru."
if ask_yes_no "Install repo layer?" yes; then
  section_repos="yes"
  if ask_yes_no "Configure Chaotic-AUR?" "${opt_chaotic}"; then opt_chaotic="yes"; else opt_chaotic="no"; fi
  if ask_yes_no "Install paru?" "${opt_paru}"; then opt_paru="yes"; else opt_paru="no"; fi
fi

print_section "Service Layer" "System services: reflector, ufw, bluetooth, fstrim, sshd, tailscale, power profiles."
if ask_yes_no "Install service layer?" yes; then
  section_services="yes"
  if ask_yes_no "Enable reflector periodic mirror refresh?" "${opt_reflector_timer}"; then opt_reflector_timer="yes"; else opt_reflector_timer="no"; fi
  if ask_yes_no "Enable firmware updates (fwupd)?" "${opt_fwupd}"; then opt_fwupd="yes"; else opt_fwupd="no"; fi
  if ask_yes_no "Enable zram swap profile?" "${opt_zram}"; then opt_zram="yes"; else opt_zram="no"; fi
  if ask_yes_no "Apply SSH hardening (root login off, key-only when keys are present)?" "${opt_ssh_hardening}"; then opt_ssh_hardening="yes"; else opt_ssh_hardening="no"; fi
  if ask_yes_no "Enable laptop extras (fingerprint + laptop power helpers)?" "${opt_laptop}"; then opt_laptop="yes"; else opt_laptop="no"; fi
fi

print_section "Userland Layer" "Desktop and user tools: curated apps, development toolchain, gaming stack, and optional COSMIC packages."
if ask_yes_no "Install userland layer?" yes; then
  section_userland="yes"
  echo "Apps bundle includes browser/mail/editor/productivity + utilities:"
  echo "  firefox, thunderbird, helix, flatpak, topgrade, disk utility, media viewers,"
  echo "  nerd fonts, and best-effort candidates for OnlyOffice/Zed (+ some AUR extras if paru exists)."
  if ask_yes_no "Install apps bundle?" "${opt_apps}"; then opt_apps="yes"; else opt_apps="no"; fi

  echo "Development bundle includes:"
  echo "  Python toolchain (python/pip/virtualenv/pipx/uv) + Rust toolchain (rustup stable)"
  echo "  plus build/debug tools (base-devel, cmake, clang, lldb, pkgconf)."
  if ask_yes_no "Install development bundle?" "${opt_dev}"; then opt_dev="yes"; else opt_dev="no"; fi

  echo "Gaming bundle includes:"
  echo "  steam, lutris, gamemode, mangohud/goverlay, wine-staging/winetricks,"
  echo "  gamescope, and 32-bit Vulkan/Mesa runtime dependencies."
  if ask_yes_no "Install gaming bundle?" "${opt_gaming}"; then opt_gaming="yes"; else opt_gaming="no"; fi

  echo "COSMIC bundle uses available repo/AUR package names (best effort):"
  echo "  cosmic-session, cosmic-desktop, cosmic-comp, cosmic-launcher, cosmic-settings,"
  echo "  cosmic-files, cosmic-terminal, cosmic-store, etc."
  if ask_yes_no "Install COSMIC packages where available?" "${opt_cosmic}"; then opt_cosmic="yes"; else opt_cosmic="no"; fi
fi

# Dependency safety: userland COSMIC/AUR flow works best with repo layer.
if [[ "${section_userland}" == "yes" && "${opt_cosmic}" == "yes" && "${section_repos}" != "yes" ]]; then
  print_section "Dependency Hint" "COSMIC/AUR installs are more reliable with repo layer (Chaotic-AUR + paru)."
  if ask_yes_no "Enable repo layer automatically to avoid missing dependencies?" yes; then
    section_repos="yes"
    opt_chaotic="yes"
    opt_paru="yes"
  fi
fi

print_section "Summary" "Review selected layers before execution."
echo "Core:      ${section_core} (kernel=${KERNEL_PROFILE}, microcode=${opt_microcode}, gpu=${opt_gpu}, boot=${opt_boot}, snapshots=${opt_snapshots})"
echo "Repos:     ${section_repos} (chaotic=${opt_chaotic}, paru=${opt_paru})"
echo "Services:  ${section_services} (laptop extras=${opt_laptop}, reflector timer=${opt_reflector_timer}, fwupd=${opt_fwupd}, zram=${opt_zram}, ssh hardening=${opt_ssh_hardening})"
echo "Userland:  ${section_userland} (apps=${opt_apps}, dev=${opt_dev}, gaming=${opt_gaming}, cosmic=${opt_cosmic})"
if [[ "${section_userland}" == "yes" ]]; then
  [[ "${opt_apps}" == "yes" ]] && echo "  - apps: browser/mail/editor/productivity utilities (+ best-effort OnlyOffice/Zed/AUR extras)"
  [[ "${opt_dev}" == "yes" ]] && echo "  - dev: Python + Rust toolchains with base build/debug tooling"
  [[ "${opt_gaming}" == "yes" ]] && echo "  - gaming: Steam/Lutris/Wine/Gamescope with Vulkan runtime deps"
  [[ "${opt_cosmic}" == "yes" ]] && echo "  - cosmic: install available COSMIC packages from repo/AUR candidates"
fi
if ask_yes_no "Run postflight validation at the end?" "${opt_postflight}"; then opt_postflight="yes"; else opt_postflight="no"; fi

if ask_yes_no "Proceed with selected actions now?" yes; then
  create_checkpoint "pre-install-wizard"

  if [[ "${section_core}" == "yes" ]]; then
    run_step core env \
      INSTALL_MICROCODE=$([[ "${opt_microcode}" == "yes" ]] && echo 1 || echo 0) \
      INSTALL_GPU=$([[ "${opt_gpu}" == "yes" ]] && echo 1 || echo 0) \
      CONFIGURE_BOOT=$([[ "${opt_boot}" == "yes" ]] && echo 1 || echo 0) \
      CONFIGURE_SNAPSHOTS=$([[ "${opt_snapshots}" == "yes" ]] && echo 1 || echo 0) \
      "${SCRIPT_DIR}/install-core.sh" "${KERNEL_PROFILE}"
  else
    section_status "skipped" "core"
  fi

  if [[ "${section_repos}" == "yes" ]]; then
    run_step repos env \
      USE_CHAOTIC=$([[ "${opt_chaotic}" == "yes" ]] && echo 1 || echo 0) \
      INSTALL_PARU=$([[ "${opt_paru}" == "yes" ]] && echo 1 || echo 0) \
      "${SCRIPT_DIR}/setup-repos.sh"
  else
    section_status "skipped" "repos"
  fi

  if [[ "${section_services}" == "yes" ]]; then
    run_step services env \
      ENABLE_LAPTOP=$([[ "${opt_laptop}" == "yes" ]] && echo 1 || echo 0) \
      ENABLE_REFLECTOR_TIMER=$([[ "${opt_reflector_timer}" == "yes" ]] && echo 1 || echo 0) \
      ENABLE_FWUPD=$([[ "${opt_fwupd}" == "yes" ]] && echo 1 || echo 0) \
      ENABLE_ZRAM=$([[ "${opt_zram}" == "yes" ]] && echo 1 || echo 0) \
      ENABLE_SSH_HARDENING=$([[ "${opt_ssh_hardening}" == "yes" ]] && echo 1 || echo 0) \
      "${SCRIPT_DIR}/install-services.sh"
  else
    section_status "skipped" "services"
  fi

  if [[ "${section_userland}" == "yes" ]]; then
    run_step userland env \
      INSTALL_APPS=$([[ "${opt_apps}" == "yes" ]] && echo 1 || echo 0) \
      INSTALL_DEV=$([[ "${opt_dev}" == "yes" ]] && echo 1 || echo 0) \
      INSTALL_GAMING=$([[ "${opt_gaming}" == "yes" ]] && echo 1 || echo 0) \
      INSTALL_COSMIC=$([[ "${opt_cosmic}" == "yes" ]] && echo 1 || echo 0) \
      "${SCRIPT_DIR}/install-userland.sh"
  else
    section_status "skipped" "userland"
  fi

  if [[ "${opt_postflight}" == "yes" && -x "${SCRIPT_DIR}/postflight-check.sh" ]]; then
    run_step postflight "${SCRIPT_DIR}/postflight-check.sh"
  else
    section_status "skipped" "postflight"
  fi

  create_checkpoint "post-install-wizard"
  print_report

  echo
  echo "Install wizard completed."
  echo "If some COSMIC packages were unavailable, check names with: pacman -Ss cosmic"
  echo "Recommended: reboot now so kernel/driver/boot changes are active."
else
  echo "Canceled before making changes."
fi

#!/usr/bin/env bash
set -euo pipefail

# Non-interactive full install using layered scripts.
# Usage: ./scripts/postinstall-cosmic.sh [zen-lts|mainline-zen|zen-stable|none] [--dry-run]

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
    zen-lts|mainline-zen|zen-stable|none) KERNEL_PROFILE="$arg" ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [zen-lts|mainline-zen|zen-stable|none] [--dry-run]" >&2
      exit 1
      ;;
  esac
done

mkdir -p "${SCRIPT_DIR}/../logs"
LOG_FILE="${SCRIPT_DIR}/../logs/install-$(date +%Y%m%d-%H%M%S).log"
REPORT_FILE="$(mktemp /tmp/arch-install-report.XXXXXX)"
trap 'rm -f "${REPORT_FILE}"' EXIT
export REPORT_FILE

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "Log file: ${LOG_FILE}"
echo "Dry run: ${DRY_RUN}"

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

  echo "[RUN] ${section}"
  if "$@"; then
    section_status "installed" "${section}"
  else
    section_status "failed" "${section}"
    return 1
  fi
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

is_laptop="0"
if hostnamectl chassis 2>/dev/null | rg -qi 'laptop|notebook|portable|tablet'; then
  is_laptop="1"
elif compgen -G "/sys/class/power_supply/BAT*" >/dev/null 2>&1; then
  is_laptop="1"
fi

echo "Detected laptop profile for service layer: ${is_laptop}"

create_checkpoint "pre-postinstall-cosmic"

run_step repos env USE_CHAOTIC=1 INSTALL_PARU=1 "${SCRIPT_DIR}/setup-repos.sh"

run_step core env \
  INSTALL_MICROCODE=1 INSTALL_GPU=1 CONFIGURE_BOOT=1 CONFIGURE_SNAPSHOTS=1 \
  "${SCRIPT_DIR}/install-core.sh" "${KERNEL_PROFILE}"

run_step services env \
  ENABLE_LAPTOP="${is_laptop}" ENABLE_REFLECTOR_TIMER=1 ENABLE_FWUPD=1 ENABLE_ZRAM=1 ENABLE_SSH_HARDENING=1 \
  "${SCRIPT_DIR}/install-services.sh"

run_step userland env INSTALL_APPS=1 INSTALL_DEV=1 INSTALL_GAMING=1 INSTALL_COSMIC=1 "${SCRIPT_DIR}/install-userland.sh"

if [[ -x "${SCRIPT_DIR}/postflight-check.sh" ]]; then
  run_step postflight "${SCRIPT_DIR}/postflight-check.sh"
fi

create_checkpoint "post-postinstall-cosmic"

print_report

echo
echo "COSMIC setup was included in userland layer."
echo "If something was skipped due to package availability, check: pacman -Ss cosmic"
echo
echo "Usage:"
echo "  ./scripts/postinstall-cosmic.sh [zen-lts|mainline-zen|zen-stable|none] [--dry-run]"

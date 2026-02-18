#!/usr/bin/env bash
set -euo pipefail

# Configure systemd-boot for quiet startup and fallback kernel entry.
# Usage: ./scripts/configure-systemd-boot.sh [main_kernel_pkg] [fallback_kernel_pkg]
# Example: ./scripts/configure-systemd-boot.sh linux-zen linux-lts

MAIN_KERNEL="${1:-linux-zen}"
FALLBACK_KERNEL="${2:-linux-lts}"
BOOT_PATH="/boot"

if command -v bootctl >/dev/null 2>&1; then
  detected_boot_path="$(bootctl --print-boot-path 2>/dev/null || true)"
  if [[ -n "${detected_boot_path}" ]]; then
    BOOT_PATH="${detected_boot_path}"
  fi
fi

LOADER_DIR="${BOOT_PATH}/loader"
ENTRY_DIR="${LOADER_DIR}/entries"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Please run as root (e.g. sudo ./scripts/configure-systemd-boot.sh)." >&2
  exit 1
fi

if [[ ! -d "${BOOT_PATH}" ]]; then
  echo "${BOOT_PATH} is missing. Mount your EFI/systemd-boot partition first." >&2
  exit 1
fi

mkdir -p "${ENTRY_DIR}"

kernel_suffix() {
  case "$1" in
    linux) echo "linux" ;;
    linux-zen) echo "linux-zen" ;;
    linux-lts) echo "linux-lts" ;;
    linux-mainline) echo "linux-mainline" ;;
    *)
      echo "Unsupported kernel package: $1" >&2
      exit 1
      ;;
  esac
}

build_initrd_lines() {
  if [[ -f /boot/amd-ucode.img ]]; then
    echo "initrd /amd-ucode.img"
  fi
  if [[ -f /boot/intel-ucode.img ]]; then
    echo "initrd /intel-ucode.img"
  fi
}

ROOT_UUID="$(findmnt -no UUID / || true)"
if [[ -z "${ROOT_UUID}" ]]; then
  echo "Could not detect root UUID from mounted /." >&2
  exit 1
fi

ROOT_SUBVOL="$(findmnt -no OPTIONS / | tr ',' '\n' | awk -F= '/^subvol=/{print $2; exit}')"
if [[ -n "${ROOT_SUBVOL}" ]]; then
  ROOTFLAGS="rootflags=subvol=${ROOT_SUBVOL}"
else
  ROOTFLAGS=""
fi

MAIN_SUFFIX="$(kernel_suffix "${MAIN_KERNEL}")"
FALLBACK_SUFFIX="$(kernel_suffix "${FALLBACK_KERNEL}")"

cat > "${LOADER_DIR}/loader.conf" <<EOL
default arch.conf
timeout 0
editor no
console-mode max
EOL

cat > "${ENTRY_DIR}/arch.conf" <<EOL
title   Arch Linux (${MAIN_SUFFIX})
linux   /vmlinuz-${MAIN_SUFFIX}
$(build_initrd_lines)
initrd  /initramfs-${MAIN_SUFFIX}.img
options root=UUID=${ROOT_UUID} rw ${ROOTFLAGS} quiet loglevel=3 rd.udev.log_level=3 udev.log_priority=3 systemd.show_status=auto vt.global_cursor_default=0
EOL

cat > "${ENTRY_DIR}/arch-fallback.conf" <<EOL
title   Arch Linux Fallback (${FALLBACK_SUFFIX})
linux   /vmlinuz-${FALLBACK_SUFFIX}
$(build_initrd_lines)
initrd  /initramfs-${FALLBACK_SUFFIX}.img
options root=UUID=${ROOT_UUID} rw ${ROOTFLAGS} systemd.show_status=true loglevel=4
EOL

echo "Configured systemd-boot entries:" 
echo "  default:   arch.conf (${MAIN_KERNEL})"
echo "  fallback:  arch-fallback.conf (${FALLBACK_KERNEL})"
echo "loader.conf set with hidden/no-wait menu (timeout 0) and editor disabled."

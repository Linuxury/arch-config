#!/usr/bin/env bash
set -euo pipefail

# Post-install validator for this project.

pass() { echo "[PASS] $*"; }
warn() { echo "[WARN] $*"; }

match_quiet() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -q "${pattern}" "$@" 2>/dev/null
  else
    grep -Eq "${pattern}" "$@" 2>/dev/null
  fi
}

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "command present: $cmd"
  else
    warn "missing command: $cmd"
  fi
}

check_service() {
  local unit="$1"
  if systemctl is-enabled "$unit" >/dev/null 2>&1; then
    pass "enabled: $unit"
  else
    warn "not enabled: $unit"
  fi
  if systemctl is-active "$unit" >/dev/null 2>&1; then
    pass "active: $unit"
  else
    warn "not active: $unit"
  fi
}

echo "== Postflight Check =="

for cmd in pacman fish fastfetch starship reflector flatpak ufw tailscale firefox thunderbird helix; do
  check_cmd "$cmd"
done

for unit in NetworkManager greetd reflector.timer fstrim.timer sshd tailscaled power-profiles-daemon bluetooth; do
  check_service "$unit"
done

if [[ -f /etc/ssh/sshd_config.d/99-hardening.conf ]]; then
  pass "ssh hardening file exists"
else
  warn "ssh hardening file missing"
fi

if [[ -f /etc/systemd/zram-generator.conf ]]; then
  pass "zram config exists"
else
  warn "zram config missing"
fi

if systemctl list-unit-files | (command -v rg >/dev/null 2>&1 && rg -q '^systemd-zram-setup@zram0\.service' || grep -Eq '^systemd-zram-setup@zram0\.service'); then
  if systemctl is-active systemd-zram-setup@zram0.service >/dev/null 2>&1; then
    pass "zram service active"
  else
    warn "zram service not active (may require reboot)"
  fi
fi

if [[ -f /boot/loader/loader.conf ]]; then
  if match_quiet '^timeout 0$' /boot/loader/loader.conf; then
    pass "systemd-boot timeout=0"
  else
    warn "systemd-boot timeout not set to 0"
  fi
fi

if [[ "$(findmnt -no FSTYPE / 2>/dev/null || true)" == "btrfs" ]]; then
  if command -v snapper >/dev/null 2>&1; then
    pass "snapper present on btrfs root"
  else
    warn "btrfs root without snapper"
  fi
fi

echo "== Done =="

#!/usr/bin/env bash
set -euo pipefail

# Laptop-oriented setup: fingerprint stack + power profile helpers.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

sudo pacman -S --needed --noconfirm \
  fprintd libfprint \
  power-profiles-daemon upower acpi

sudo systemctl enable --now power-profiles-daemon

# fprintd is usually DBus-activated; enabling directly is harmless if unit exists.
if systemctl list-unit-files | rg -q '^fprintd\.service'; then
  sudo systemctl enable --now fprintd.service || true
fi

echo "Laptop setup complete."
echo "Enroll fingerprint: fprintd-enroll"
echo "Verify fingerprint: fprintd-verify"
echo "For max battery life, use either power-profiles-daemon OR TLP (not both)."

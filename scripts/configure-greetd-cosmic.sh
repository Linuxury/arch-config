#!/usr/bin/env bash
set -euo pipefail

# Configure greetd to launch COSMIC greeter on boot.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

if ! pacman -Qi greetd >/dev/null 2>&1; then
  echo "greetd is not installed; skipping COSMIC greeter autostart setup."
  exit 0
fi

if ! command -v cosmic-greeter >/dev/null 2>&1; then
  echo "cosmic-greeter command not found; install cosmic-greeter and re-run this script."
  exit 0
fi

tmp_conf="$(mktemp /tmp/greetd-config.toml.XXXXXX)"
cat > "${tmp_conf}" <<'EOF'
[terminal]
vt = 1

[default_session]
command = "cosmic-greeter"
user = "greeter"
EOF

sudo install -d -m 755 /etc/greetd
if [[ -f /etc/greetd/config.toml ]]; then
  sudo install -m 644 /etc/greetd/config.toml "/etc/greetd/config.toml.bak.$(date +%Y%m%d-%H%M%S)"
fi
sudo install -m 644 "${tmp_conf}" /etc/greetd/config.toml
rm -f "${tmp_conf}"

# Ensure greetd owns display-manager alias and is active on boot.
sudo systemctl enable --now --force greetd
echo "Configured greetd to launch cosmic-greeter and enabled it at boot."

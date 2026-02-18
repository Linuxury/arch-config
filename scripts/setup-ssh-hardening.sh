#!/usr/bin/env bash
set -euo pipefail

# SSH hardening with guard rails.
# - Always disables root login
# - Disables password auth only if at least one authorized key is found,
#   unless FORCE_SSH_KEY_ONLY=1 is set.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

FORCE_SSH_KEY_ONLY="${FORCE_SSH_KEY_ONLY:-0}"

sudo pacman -S --needed --noconfirm openssh

has_any_authorized_key=0
while IFS= read -r file; do
  if [[ -s "$file" ]]; then
    has_any_authorized_key=1
    break
  fi
done < <(find /home -maxdepth 3 -type f -path '*/.ssh/authorized_keys' 2>/dev/null || true)

sudo install -d -m 755 /etc/ssh/sshd_config.d

if [[ "$FORCE_SSH_KEY_ONLY" == "1" || "$has_any_authorized_key" == "1" ]]; then
  sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null <<'EOCFG'
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
X11Forwarding no
EOCFG
  echo "Applied key-only SSH hardening."
else
  sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null <<'EOCFG'
PermitRootLogin no
PubkeyAuthentication yes
X11Forwarding no
EOCFG
  echo "No authorized_keys found in /home; kept password auth enabled to avoid lockout."
  echo "After adding SSH keys, rerun with FORCE_SSH_KEY_ONLY=1 for strict mode."
fi

sudo systemctl enable --now sshd
sudo sshd -t
sudo systemctl restart sshd

echo "SSH hardening setup complete."

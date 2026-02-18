#!/usr/bin/env bash
set -euo pipefail

# Set up Snapper + snap-pac for Btrfs root snapshots.

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Please run as root (e.g. sudo ./scripts/setup-btrfs-snapshots.sh)." >&2
  exit 1
fi

ROOT_FS="$(findmnt -no FSTYPE / || true)"
if [[ "${ROOT_FS}" != "btrfs" ]]; then
  echo "Root filesystem is '${ROOT_FS:-unknown}', not btrfs. Skipping Snapper setup."
  exit 0
fi

pacman -S --needed --noconfirm snapper snap-pac btrfs-assistant

if [[ ! -d /.snapshots ]]; then
  mkdir -p /.snapshots
fi

if [[ ! -f /etc/snapper/configs/root ]]; then
  snapper -c root create-config /
fi

# Keep timeline snapshots on with conservative limits for desktops.
sed -i 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="12"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="4"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

echo "Snapper configured for / with timeline + cleanup timers enabled."
echo "snap-pac will auto-create snapshots around pacman transactions."
echo "Tip: view snapshots with 'sudo snapper -c root list'."

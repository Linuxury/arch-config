# Install Arch Linux with archinstall

## 1. Pre-install checklist
- Confirm UEFI mode in firmware settings.
- Connect to network:
  - Ethernet: usually automatic
  - Wi-Fi: `iwctl` -> connect
- Enable NTP:
  - `timedatectl set-ntp true`
- Verify time:
  - `timedatectl status`

## 2. Start installer
Run:
```bash
archinstall
```

## 3. Recommended archinstall choices
Use these as a baseline:
- Language/Keyboard: your locale
- Mirrors: nearest region
- Disk config: guided partitioning (unless you need custom)
- Filesystem: `btrfs` or `ext4`
- Bootloader: `systemd-boot` (UEFI) or `grub` if preferred
- Swap: enable zram or swap partition/file
- Hostname: set your machine name
- Root password: set securely
- User account: create an admin user with sudo
- Profile type: minimal/base
- Audio: PipeWire
- Network: NetworkManager
- Timezone: your region

## 4. Finalize and reboot
After install completes:
```bash
reboot
```

Log in with the user created in `archinstall`.

## 5. First boot essentials
```bash
sudo pacman -Syu
sudo pacman -S --needed git base-devel networkmanager
sudo systemctl enable --now NetworkManager
```

## 6. Apply this project setup
From project root:
```bash
./scripts/install-wizard.sh
```

This wizard asks section-by-section with a short description and lets you choose what to install.
It also detects hardware (chassis/battery/fingerprint hints), shows what was detected, and proposes laptop/desktop defaults that you can override.
Wizard execution order is dependency-safe: `repos -> core -> services -> userland`.
If you pick COSMIC in userland without repos, it can suggest enabling repo layer automatically.
At the end, it prints a stricter summary with section status plus installed/unavailable counts for dynamic package groups (apps/COSMIC).

Non-interactive alternative:
```bash
./scripts/postinstall-cosmic.sh zen-lts
```

Preview mode (no changes applied):
```bash
./scripts/install-wizard.sh --dry-run
./scripts/postinstall-cosmic.sh zen-lts --dry-run
```

Layer scripts (for advanced/custom flows):
```bash
./scripts/setup-repos.sh
./scripts/install-core.sh zen-lts
./scripts/install-services.sh
./scripts/install-userland.sh
./scripts/postflight-check.sh
```

Logs are written to:
- `logs/install-wizard-YYYYMMDD-HHMMSS.log`
- `logs/install-YYYYMMDD-HHMMSS.log`

Kernel profiles:
- `zen-lts`: `linux-zen` primary + `linux-lts` fallback (recommended default)
- `mainline-zen`: `linux-mainline` primary + `linux-zen` fallback
- `zen-stable`: `linux-zen` primary + `linux` fallback
- `none`: no kernel changes

What the script now configures:
- `systemd-boot` entries with no wait (`timeout 0`)
- quiet default entry (`arch.conf`) that mostly shows errors only
- explicit verbose fallback entry (`arch-fallback.conf`)
- Snapper + `snap-pac` on Btrfs with timeline/cleanup timers
- Core extras: `reflector`, `flatpak`, `ufw`, Bluetooth stack, and `fstrim.timer`
- Reflector timer automation
- Firmware update service (`fwupd`) and zram swap profile
- SSH hardening profile
- Chaotic-AUR repository
- `paru` AUR helper
- Gaming package baseline
- Python + Rust development baseline
- Requested app/services baseline (`sshd`, `tailscale`, browser/mail/editors, productivity/media tools)
- Laptop baseline (`fprintd`, `power-profiles-daemon`, `upower`)
- COSMIC package install step (repo/AUR candidates when available)

## 7. Manual alternative (without scripts)
If you prefer not to run scripts, install manually:

Microcode:
- Intel CPU: `sudo pacman -S intel-ucode`
- AMD CPU: `sudo pacman -S amd-ucode`

GPU drivers:
- Intel iGPU: `sudo pacman -S mesa vulkan-intel lib32-vulkan-intel`
- AMD GPU: `sudo pacman -S mesa vulkan-radeon lib32-vulkan-radeon`
- NVIDIA proprietary: `sudo pacman -S nvidia nvidia-utils lib32-nvidia-utils`
- NVIDIA open modules: `sudo pacman -S nvidia-open nvidia-utils lib32-nvidia-utils`

Your preferred user tools:
```bash
sudo pacman -S fish fastfetch starship
```

Optional terminal:
```bash
sudo pacman -S ghostty
```
If `ghostty` is unavailable in enabled repos, install from AUR.

Install `paru` manually:
```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

Core extras:
```bash
sudo pacman -S --needed reflector flatpak ufw bluez bluez-utils
sudo systemctl enable --now bluetooth
sudo systemctl enable --now fstrim.timer
```

Reflector timer automation:
```bash
./scripts/setup-reflector-timer.sh
```

Firmware + zram:
```bash
./scripts/setup-maintenance.sh
```

SSH hardening:
```bash
./scripts/setup-ssh-hardening.sh
```

Chaotic-AUR:
```bash
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
```
Add to `/etc/pacman.conf`:
```ini
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
```
Then refresh databases:
```bash
sudo pacman -Sy
```

Gaming baseline:
```bash
sudo pacman -S --needed steam lutris gamemode mangohud goverlay wine-staging winetricks gamescope
```

Python + Rust baseline:
```bash
sudo pacman -S --needed python python-pip python-virtualenv pipx uv rustup base-devel pkgconf cmake clang lldb
pipx ensurepath
rustup toolchain install stable
rustup default stable
rustup component add rustfmt clippy rust-analyzer
```

Requested apps/services baseline:
```bash
sudo pacman -S --needed openssh tailscale topgrade thunderbird firefox helix gnome-disk-utility power-profiles-daemon flatpak ufw loupe amberol showtime papers
sudo systemctl enable --now sshd tailscaled power-profiles-daemon
```

AUR/Chaotic targets from your list:
```bash
paru -S --needed protonplus fluent-reader-bin sgdboop-bin lsfg-vk-git
```
Plus candidates that vary by repo state:
- OnlyOffice: `onlyoffice-desktopeditors` or `onlyoffice-bin`
- Zed: `zed`, `zed-preview`, or `zed-bin`
- Nerd Fonts: `ttf-jetbrains-mono-nerd` and/or `ttf-firacode-nerd`

Laptop extras:
```bash
sudo pacman -S --needed fprintd libfprint power-profiles-daemon upower acpi
fprintd-enroll
```
Recommendation:
- Keep `power-profiles-daemon` for laptop + gaming workflow.
- Use `TLP` only if you want maximum battery saving and are okay giving up PPD integration.
- Do not run `TLP` and `power-profiles-daemon` together.

## 8. Quiet systemd-boot + fallback (manual)
If you want to apply boot settings manually:
```bash
sudo ./scripts/configure-systemd-boot.sh linux-zen linux-lts
```

For your preferred RC primary:
```bash
sudo ./scripts/configure-systemd-boot.sh linux-mainline linux-zen
```

## 9. Btrfs snapshots with Snapper (manual)
If root is Btrfs:
```bash
sudo ./scripts/setup-btrfs-snapshots.sh
sudo snapper -c root list
```

Recommended Btrfs subvolumes for new installs:
- `@` for `/`
- `@home` for `/home`
- `@log` for `/var/log`
- `@pkg` for `/var/cache/pacman/pkg`
- `@snapshots` for `/.snapshots`

## 10. Postflight validation
After setup:
```bash
./scripts/postflight-check.sh
```

## 11. Snapper checkpoints
When root is Btrfs and Snapper root config exists, installers create checkpoints automatically:
- `pre-install-wizard` and `post-install-wizard`
- `pre-postinstall-cosmic` and `post-postinstall-cosmic`

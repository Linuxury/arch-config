# Arch Linux + archinstall + COSMIC DE Project

This project is a practical, reproducible guide for:
- Installing Arch Linux using `archinstall`
- Bootstrapping a desktop setup with COSMIC DE components
- Keeping post-install steps scripted and versioned

## Project Layout
- `docs/INSTALL.md`: End-to-end install workflow
- `docs/COSMIC.md`: COSMIC package and session setup notes
- `scripts/postinstall-cosmic.sh`: Post-install automation starter
- `scripts/install-wizard.sh`: Interactive section-by-section installer (recommended flow)
- `scripts/install-core.sh`: Core layer (kernel + core packages + microcode/GPU + boot + snapshots)
- `scripts/setup-repos.sh`: Repo layer (Chaotic-AUR + paru)
- `scripts/install-services.sh`: Service layer (system services + optional laptop extras)
- `scripts/install-userland.sh`: Userland layer (apps + dev + gaming + COSMIC)
- `scripts/install-microcode.sh`: CPU microcode installer (`auto|intel|amd|both`)
- `scripts/install-gpu-drivers.sh`: GPU driver installer (`auto|intel|amdgpu|nvidia|nvidia-open|all-open`)
- `scripts/configure-systemd-boot.sh`: Quiet boot + fallback entry generator
- `scripts/setup-btrfs-snapshots.sh`: Snapper + `snap-pac` setup for Btrfs
- `scripts/setup-paru.sh`: Install `paru` AUR helper
- `scripts/setup-system-extras.sh`: Install `reflector`, `flatpak`, `ufw`, `bluez`; enable Bluetooth + TRIM
- `scripts/setup-reflector-timer.sh`: Configure and enable periodic reflector mirror refresh
- `scripts/setup-maintenance.sh`: Enable firmware updates (`fwupd`) + configure zram
- `scripts/setup-ssh-hardening.sh`: Apply SSH hardening with key-presence safety checks
- `scripts/setup-chaotic-aur.sh`: Configure Chaotic-AUR repository
- `scripts/setup-gaming.sh`: Install gaming packages (Steam/Lutris/GameMode/MangoHud)
- `scripts/setup-dev.sh`: Install Python + Rust developer baseline
- `scripts/setup-apps.sh`: Install requested desktop apps (browser/mail/editors/fonts/media/productivity)
- `scripts/setup-cosmic.sh`: Install COSMIC packages from repos/AUR when available
- `scripts/setup-laptop.sh`: Laptop extras (fingerprint + power profile tools)

## Quick Start
1. Boot Arch ISO and connect to the internet.
2. Run `archinstall` with the profile choices documented in `docs/INSTALL.md`.
3. Reboot into your new system.
4. Clone this repo.
5. Run `scripts/install-wizard.sh` as your user (with sudo available), review detected hardware profile, then answer prompts section-by-section.
6. In the wizard, enable COSMIC package install (or install manually after checking `pacman -Ss cosmic`).

Optional preview mode:
- `./scripts/install-wizard.sh --dry-run`
- `./scripts/postinstall-cosmic.sh zen-lts --dry-run`

## Goals
- Repeatable setup process
- Minimal manual steps
- Easy to customize for your hardware and preferences

## Included Preferences
- Layered installer model: `core`, `repos`, `services`, `userland` (ordered to satisfy dependencies)
- Kernel profile `zen-lts` (recommended default)
- Kernel profile `mainline-zen` (RC/mainline primary + zen fallback)
- Kernel profile `zen-stable` (zen primary + stable fallback)
- Shell and terminal: `fish`, `ghostty` (if available in enabled repos)
- CLI extras: `fastfetch`, `starship`
- AUR helper: `paru`
- Additional repo: `chaotic-aur`
- Core extras: `reflector`, `flatpak`, `ufw`, Bluetooth stack, `fstrim.timer`
- Maintenance: `fwupd`, zram swap profile, reflector timer automation
- Security: SSH hardening profile (`PermitRootLogin no`, key-first policy)
- Gaming baseline: Steam, Lutris, GameMode, MangoHud, Wine
- Dev baseline: Python (`pipx`, `uv`) and Rust (`rustup`, stable toolchain)
- Requested apps/services: `sshd`, `tailscale`, `protonplus`, `topgrade`, `loupe`, `amberol`, `showtime`, `onlyoffice`, `zed`, `thunderbird`, `firefox`, `fluent-reader-bin`, `helix`, `papers`, `sgdboop-bin`, `lsfg-vk-git`, Nerd Fonts, `gnome-disk-utility`, `power-profiles-daemon`
- COSMIC packages install step integrated in wizard/userland layer
- Laptop setup: fingerprint stack (`fprintd`) and battery profile tooling
- Bootloader setup: `systemd-boot` with `timeout 0`, quiet default entry, and verbose fallback entry
- Snapshots: `snapper` + `snap-pac` + timers on Btrfs root

## Validation
- `scripts/postflight-check.sh`: checks expected commands/services/config files after install

## Logging
- Wizard logs: `logs/install-wizard-YYYYMMDD-HHMMSS.log`
- Non-interactive logs: `logs/install-YYYYMMDD-HHMMSS.log`

## Snapper Checkpoints
- If root is Btrfs and Snapper root config exists, installers create:
- `pre-install-wizard` / `post-install-wizard`
- `pre-postinstall-cosmic` / `post-postinstall-cosmic`

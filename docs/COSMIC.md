# COSMIC DE on Arch

COSMIC packaging on Arch can evolve quickly. Always confirm package names before install.

## 1. Discover available COSMIC packages
```bash
pacman -Ss cosmic
```

If official repos do not include all needed components, check AUR helpers or build instructions.

## 2. Typical components to look for
- COSMIC session package
- COSMIC applets / panel
- Greeter/session integration
- Wayland dependencies and portals

## 3. Display manager
Install and enable a display manager if needed:
```bash
sudo pacman -S greetd
sudo systemctl enable --now greetd
```

To configure greetd to launch `cosmic-greeter` automatically at boot:
```bash
./scripts/configure-greetd-cosmic.sh
```

You can also use SDDM/GDM depending on available COSMIC session files.

## 4. Session validation
After install:
- Reboot
- Select COSMIC session from login screen
- Confirm portal and audio services are active

## 5. Troubleshooting commands
```bash
loginctl show-session $(loginctl | awk '/tty|seat|pts/{print $1; exit}') -p Type -p Name
systemctl --user status xdg-desktop-portal.service
journalctl -b -p warning --no-pager | tail -n 80
```

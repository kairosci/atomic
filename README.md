# Fedora Atomic Config

Configuration scripts for **Fedora Kionite** (KDE) and **Fedora Silverblue** (GNOME) with automatic distro detection.

## Features

| Feature                               | Kionite | Silverblue |
|---------------------------------------|:-------:|:----------:|
| Distro Auto Detection                 | ✓       | ✓          |
| Remove Bloatware                      | ✓       | ✓          |
| Brave Browser                         | ✓       | ✓          |
| Flatpak Apps (Discord)                | ✓       | ✓          |
| TLP Power Management                  | ✓       | ✓          |
| Distrobox + libvirt/QEMU              | ✓       | ✓          |
| Papirus Icons                         | ✓       | ✓          |
| OS Optimization (kernel, services)    | ✓       | ✓          |
| GNOME Extensions                      | —       | ✓          |

## Installation

```bash
git clone https://codeberg.org/kairosci/fedora-atomic-config.git
cd fedora-atomic-config
sudo ./setup.sh
```

Restart terminal, then:

```bash
sudo atomic
```

## Structure

```text
├── index.sh                # Interactive menu
├── lib/common.sh           # Shared utilities
├── config/
│   ├── index.sh            # Main config entry
│   └── script/
│       ├── kionite/        # KDE specific
│       ├── silverblue/     # GNOME specific
│       └── *.sh            # Common scripts
└── utils/                  # Utility scripts
```

## GNOME Extensions (Silverblue)

- **Dash to Dock** — Bottom dock
- **AppIndicator** — Tray icons
- **Blur my Shell** — Blur effects
- **Just Perfection** — Fast animations
- **Caffeine** — Prevent suspend

## Notes

- Dev tools should be in **Distrobox**, not base system

## License

MIT

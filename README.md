# Atomic Manager (v2.1)

Configuration scripts for **Fedora Kionite** (KDE) and **Fedora Silverblue** (GNOME) with automatic distro detection.

## Features

## Features

Atomic Manager automatically detects your distribution (**Fedora Silverblue** or **Fedora Kionite**) and applies the appropriate configuration.

### Core Configuration

- **Automatic Detection**: Adapts scripts based on the running OS (GNOME vs KDE).
- **Zsh Environment**: Sets up Zsh with Oh My Zsh for a superior shell experience.
- **System Optimization**: Configures kernel parameters, services, and TLP for battery life.
- **Deep Clean**: Utilities to reset user configuration and clean up the home directory.

### Applications & Development

- **Toolbox Integration**: Sets up a Fedora-based `toolbox` container for development (Node.js, dev tools), keeping the base system clean.
- **Browsers**: Installs Brave Browser.
- **Flatpak Management**: Installs curated Flatpak apps (Discord, etc.) and applies overrides (Papirus Icons).
- **Virtualization**: Sets up libvirt/QEMU for VM management.

### Desktop Enhancements

- **GNOME Extensions** (Silverblue): Configures Dash to Dock, AppIndicator, Blur my Shell, Just Perfection, and Caffeine.
- **Bloatware Removal**: Removes unnecessary pre-installed applications for a slimmer system.

## Installation

```bash
git clone https://github.com/redigere/atomic.git
cd atomic
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

- Development tools should be installed in **Toolbox**, not on the immutable base system.

## License

MIT

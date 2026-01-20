#!/usr/bin/env zsh
# @file set-extensions.sh
# @brief Installs and configures GNOME Shell extensions
# @description
#   Installs extensions via CLI, enables them, and configures
#   Dash to Dock, Just Perfection, and Blur My Shell.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

readonly -a GNOME_EXTENSIONS=(
    "appindicatorsupport@rgcjonas.gmail.com"
    "dash-to-dock@micxgx.gmail.com"
    "blur-my-shell@aunetx"
    "just-perfection-desktop@just-perfection"
    "caffeine@patapon.info"
    "user-theme@gnome-shell-extensions.gcampax.github.com"
)

# @description Installs GNOME Extension Manager via Flatpak.
install-extension-manager() {
    log-info "Installing GNOME Extension Manager via Flatpak"

    if ! flatpak list --app | grep -q "com.mattjakeman.ExtensionManager"; then
        flatpak install flathub com.mattjakeman.ExtensionManager -y
        log-success "Extension Manager installed"
    else
        log-info "Extension Manager already installed"
    fi
}

# @description Enables user extensions in GNOME.
enable-user-extensions() {
    log-info "Enabling GNOME user extensions"
    dconf write /org/gnome/shell/disable-user-extensions false
}

# @description Configures Dash to Dock for minimal, floating style.
configure-dash-to-dock() {
    log-info "Configuring Dash to Dock (Premium Floating)..."

    dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 42
    dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed false
    dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height false

    dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide-mode "'ALL_WINDOWS'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/autohide-in-fullscreen true

    dconf write /org/gnome/shell/extensions/dash-to-dock/custom-theme-shrink true
    dconf write /org/gnome/shell/extensions/dash-to-dock/transparency-mode "'FIXED'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/background-opacity 0.2

    dconf write /org/gnome/shell/extensions/dash-to-dock/show-trash false
    dconf write /org/gnome/shell/extensions/dash-to-dock/show-mounts false
}

# @description Configures Just Perfection for cleaner UI.
configure-just-perfection() {
    log-info "Configuring Just Perfection..."

    dconf write /org/gnome/shell/extensions/just-perfection/search false
    dconf write /org/gnome/shell/extensions/just-perfection/workspace true
    dconf write /org/gnome/shell/extensions/just-perfection/animation 4
    dconf write /org/gnome/shell/extensions/just-perfection/panel-corner-size 1
    dconf write /org/gnome/shell/extensions/just-perfection/workspace-background-corner-size 1
}

# @description Configures Blur My Shell for glassmorphism effect.
configure-blur-my-shell() {
    log-info "Configuring Blur My Shell (Glassmorphism)..."

    dconf write /org/gnome/shell/extensions/blur-my-shell/brightness 0.6
    dconf write /org/gnome/shell/extensions/blur-my-shell/sigma 30
    dconf write /org/gnome/shell/extensions/blur-my-shell/noise-amount 0.05

    dconf write /org/gnome/shell/extensions/blur-my-shell/panel/blur true
    dconf write /org/gnome/shell/extensions/blur-my-shell/panel/pipeline "'pipeline_default'"
    dconf write /org/gnome/shell/extensions/blur-my-shell/appfolder/blur true
    dconf write /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/blur true
    dconf write /org/gnome/shell/extensions/blur-my-shell/overview/blur true
}

# @description Installs CLI tools for extension management.
install-cli-tools() {
    log-info "Installing CLI tools for extension management..."

    if ! command -v pip &>/dev/null; then
        log-info "Installing pip..."
        python3 -m ensurepip --user --default-pip
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if ! command -v gnome-extensions-cli &>/dev/null; then
        log-info "Installing gnome-extensions-cli..."
        pip install --user gnome-extensions-cli
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

# @description Installs and enables GNOME extensions via CLI.
install-extensions-cli() {
    log-info "Installing GNOME extensions via CLI..."

    for ext in "${GNOME_EXTENSIONS[@]}"; do
        log-info "Processing $ext..."
        gnome-extensions-cli install "$ext"
        gnome-extensions-cli enable "$ext"
    done
}

# @description Removes Extension Manager after setup.
remove-extension-manager() {
    log-info "Removing GNOME Extension Manager (cleanup)..."
    if flatpak list --app | grep -q "com.mattjakeman.ExtensionManager"; then
        flatpak uninstall flathub com.mattjakeman.ExtensionManager -y
    fi
}

# @description Main entry point.
main() {
    ensure-user
    install-cli-tools
    install-extensions-cli
    enable-user-extensions

    if command -v dconf &>/dev/null; then
        if dconf list /org/gnome/shell/extensions/dash-to-dock/ &>/dev/null; then
            configure-dash-to-dock
        fi

        if dconf list /org/gnome/shell/extensions/just-perfection/ &>/dev/null; then
            configure-just-perfection
        fi

        if dconf list /org/gnome/shell/extensions/blur-my-shell/ &>/dev/null; then
            configure-blur-my-shell
        fi
    fi

    remove-extension-manager
}

main "$@"

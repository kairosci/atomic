#!/usr/bin/env zsh
# Set GNOME Extensions

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

install-extension-manager() {
    log-info "Installing GNOME Extension Manager via Flatpak"

    if ! flatpak list --app | grep -q "com.mattjakeman.ExtensionManager"; then
        flatpak install flathub com.mattjakeman.ExtensionManager -y
        log-success "Extension Manager installed"
    else
        log-info "Extension Manager already installed"
    fi
}

enable-user-extensions() {
    log-info "Enabling GNOME user extensions"
    dconf write /org/gnome/shell/disable-user-extensions false
}

#######################################
# Configures Dash to Dock settings for a minimal, floating interaction.
# Sets dock position, size, transparency, and hides unnecessary elements.
# Globals:
#   None
# Arguments:
#   None
#######################################
configure-dash-to-dock() {
    log-info "Configuring Dash to Dock (Premium Floating)..."

    # Dock Position & Size
    dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 42
    dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed false
    dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height false

    # Behavior
    dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide-mode "'ALL_WINDOWS'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/autohide-in-fullscreen true

    # Aesthetic (Glassy)
    dconf write /org/gnome/shell/extensions/dash-to-dock/custom-theme-shrink true
    dconf write /org/gnome/shell/extensions/dash-to-dock/transparency-mode "'FIXED'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/background-opacity 0.2

    # Indicators
    dconf write /org/gnome/shell/extensions/dash-to-dock/show-trash false
    dconf write /org/gnome/shell/extensions/dash-to-dock/show-mounts false
}

#######################################
# Configures Just Perfection for a cleaner UI.
# Hides search, sets corner radius, speeds up animations.
# Globals:
#   None
# Arguments:
#   None
#######################################
configure-just-perfection() {
    log-info "Configuring Just Perfection..."

    dconf write /org/gnome/shell/extensions/just-perfection/search false
    dconf write /org/gnome/shell/extensions/just-perfection/workspace true

    # Animation handled in optimize-animations.sh usually, but default here
    dconf write /org/gnome/shell/extensions/just-perfection/animation 4

    # Set sharp corners (1 = no rounded borders) to match the "Solid" theme tweak
    dconf write /org/gnome/shell/extensions/just-perfection/panel-corner-size 1
    dconf write /org/gnome/shell/extensions/just-perfection/workspace-background-corner-size 1
}

#######################################
# Configures Blur My Shell for maximum aesthetic appeal.
# Enables blur on pipeline, dash, panel, and overview.
# Globals:
#   None
# Arguments:
#   None
#######################################
configure-blur-my-shell() {
    log-info "Configuring Blur My Shell (Glassmorphism)..."

    # General Settings - brightness 0.6 for that dark glass look
    dconf write /org/gnome/shell/extensions/blur-my-shell/brightness 0.6
    dconf write /org/gnome/shell/extensions/blur-my-shell/sigma 30
    dconf write /org/gnome/shell/extensions/blur-my-shell/noise-amount 0.05 # Slight noise for texture

    # Panel
    dconf write /org/gnome/shell/extensions/blur-my-shell/panel/blur true
    dconf write /org/gnome/shell/extensions/blur-my-shell/panel/pipeline "'pipeline_default'"

    # Appfolder
    dconf write /org/gnome/shell/extensions/blur-my-shell/appfolder/blur true

    # Dash
    dconf write /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/blur true

    # Overview
    dconf write /org/gnome/shell/extensions/blur-my-shell/overview/blur true
}

#######################################
# Installs CLI tools (pip, gnome-extensions-cli) for extension management.
# Globals:
#   PATH
#   HOME
# Arguments:
#   None
#######################################
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

#######################################
# Installs GNOME extensions using the CLI.
# Enables them after installation.
# Globals:
#   GNOME_EXTENSIONS
# Arguments:
#   None
#######################################
install-extensions-cli() {
    log-info "Installing GNOME extensions via CLI..."

    for ext in "${GNOME_EXTENSIONS[@]}"; do
        log-info "Processing $ext..."
        gnome-extensions-cli install "$ext"
        gnome-extensions-cli enable "$ext"
    done
}

#######################################
# Removes GNOME Extension Manager if installed via Flatpak.
# Globals:
#   None
# Arguments:
#   None
#######################################
remove-extension-manager() {
    log-info "Removing GNOME Extension Manager (cleanup)..."
    if flatpak list --app | grep -q "com.mattjakeman.ExtensionManager"; then
        flatpak uninstall flathub com.mattjakeman.ExtensionManager -y
    fi
}

#######################################
# Main entry point for the extension setup script.
# Arguments:
#   None
#######################################
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

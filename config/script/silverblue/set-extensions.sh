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

configure-dash-to-dock() {
    log-info "Configuring Dash to Dock (Ubuntu-style)"
    
    dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height false
    dconf write /org/gnome/shell/extensions/dash-to-dock/multi-monitor true
    dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide-mode "'ALL_WINDOWS'"
    dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 48
    dconf write /org/gnome/shell/extensions/dash-to-dock/transparency-mode "'DYNAMIC'"
}

configure-just-perfection() {
    log-info "Configuring Just Perfection"
    
    dconf write /org/gnome/shell/extensions/just-perfection/search false
    dconf write /org/gnome/shell/extensions/just-perfection/workspace true
    dconf write /org/gnome/shell/extensions/just-perfection/animation 5
}

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

install-extensions-cli() {
    log-info "Installing GNOME extensions via CLI..."
    
    for ext in "${GNOME_EXTENSIONS[@]}"; do
        log-info "Processing $ext..."
        gnome-extensions-cli install "$ext"
        gnome-extensions-cli enable "$ext"
    done
}

remove-extension-manager() {
    log-info "Removing GNOME Extension Manager (cleanup)..."
    if flatpak list --app | grep -q "com.mattjakeman.ExtensionManager"; then
        flatpak uninstall flathub com.mattjakeman.ExtensionManager -y
    fi
}

main() {
    ensure-user
    install-cli-tools
    install-extensions-cli
    enable-user-extensions
    
    if command -v dconf &>/dev/null && dconf list /org/gnome/shell/extensions/dash-to-dock/ &>/dev/null; then
        configure-dash-to-dock
    fi
    
    if command -v dconf &>/dev/null && dconf list /org/gnome/shell/extensions/just-perfection/ &>/dev/null; then
        configure-just-perfection
    fi
    
    remove-extension-manager
}

main "$@"

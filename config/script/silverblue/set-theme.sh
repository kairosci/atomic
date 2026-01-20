#!/usr/bin/bash
# Set Themes (Orchis + Papirus)
# Installs Orchis GTK theme and Papirus Icons

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

readonly ICON_THEME="Papirus"
readonly GTK_THEME="Orchis-Dark"
readonly ORCHIS_REPO="https://github.com/vinceliuice/Orchis-theme.git"
readonly THEME_DIR="$HOME/.local/share/themes"

install-orchis() {
    log-info "Installing Orchis theme..."
    
    local work_dir
    work_dir="$(mktemp -d)"
    
    # Ensure theme directory exists
    mkdir -p "$THEME_DIR"
    
    # Clone and install
    git clone --depth 1 "$ORCHIS_REPO" "$work_dir/orchis"
    
    pushd "$work_dir/orchis" > /dev/null
    ./install.sh -t all -c dark
    popd > /dev/null
    
    rm -rf "$work_dir"
    log-success "Orchis theme installed"
}

apply-theme() {
    log-info "Applying visual settings for GNOME"
    
    # Set GTK/Cursor/Sound
    dconf write /org/gnome/desktop/interface/gtk-theme "'$GTK_THEME'"
    dconf reset /org/gnome/desktop/interface/cursor-theme
    dconf reset /org/gnome/desktop/sound/theme-name
    
    # Set Icons to Papirus
    dconf write /org/gnome/desktop/interface/icon-theme "'$ICON_THEME'"
    
    # Set Dark Mode
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    
    log-success "Visual settings applied"
}

override-flatpak-icons() {
    log-info "Overriding Flatpak icons..."
    flatpak override --user --filesystem=~/.icons:ro
    flatpak override --user --filesystem=~/.local/share/icons:ro
    flatpak override --user --filesystem=/usr/share/icons:ro
    flatpak override --user --filesystem=~/.themes:ro
    flatpak override --user --filesystem=~/.local/share/themes:ro
    log-success "Flatpak permissions updated"
}

main() {
    ensure-user
    install-orchis
    apply-theme
    override-flatpak-icons
}

main "$@"

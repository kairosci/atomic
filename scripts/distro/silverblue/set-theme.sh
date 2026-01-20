#!/usr/bin/env zsh
# @file set-theme.sh
# @brief Installs Orchis GTK theme and Papirus Icons
# @description
#   Installs Orchis GTK theme (dark/light variants) and Papirus icons.
#   Configures GNOME to use these themes and sets dark mode.
#   Also configures Flatpak permissions for icon themes.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

readonly ICON_THEME="Papirus"
readonly GTK_THEME="Orchis-Dark"
readonly ORCHIS_REPO="https://github.com/vinceliuice/Orchis-theme.git"
readonly THEME_DIR="$HOME/.local/share/themes"


#######################################
# Installs the Orchis GTK theme from source.
# Clones the repository, installs Dark and Light variants,
# and minimizes the installation size.
# Globals:
#   ORCHIS_REPO
#   THEME_DIR
#   HOME
# Arguments:
#   None
#######################################
install-orchis() {
    log-info "Installing Orchis theme..."

    local work_dir
    work_dir="$(mktemp -d)"

    mkdir -p "$THEME_DIR"
    git clone --depth 1 "$ORCHIS_REPO" "$work_dir/orchis"

    pushd "$work_dir/orchis" > /dev/null
    ./install.sh -c dark --shell --libadwaita
    ./install.sh -c light --shell --libadwaita
    popd > /dev/null

    rm -rf "$work_dir"
    log-success "Orchis theme installed"
}

#######################################
# Removes unused Orchis theme variants.
# Iterates through the theme directory and removes any variant
# that is not 'Orchis-Dark' or 'Orchis-Light'.
# Globals:
#   THEME_DIR
# Arguments:
#   None
#######################################
clean-orchis-variants() {
    log-info "Cleaning up unused Orchis variants..."
    if [[ -d "$THEME_DIR" ]]; then
        find "$THEME_DIR" -maxdepth 1 -type d -name "Orchis*" | while read -r theme_path; do
            local theme_name
            theme_name="$(basename "$theme_path")"
            if [[ "$theme_name" != "Orchis-Dark" && "$theme_name" != "Orchis-Light" ]]; then
                log-info "Removing unused variant: $theme_name"
                rm -rf "$theme_path"
            fi
        done
        log-success "Unused variants removed"
    fi
}

#######################################
# Applies visual settings for GNOME.
# Configures GTK theme, icons, color scheme, and shell theme.
# Globals:
#   GTK_THEME
#   ICON_THEME
# Arguments:
#   None
#######################################
apply-theme() {
    log-info "Applying visual settings for GNOME"

    dconf write /org/gnome/desktop/interface/gtk-theme "'$GTK_THEME'"
    dconf reset /org/gnome/desktop/interface/cursor-theme
    dconf reset /org/gnome/desktop/sound/theme-name

    dconf write /org/gnome/desktop/interface/icon-theme "'$ICON_THEME'"
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    dconf write /org/gnome/shell/extensions/user-theme/name "'Orchis-Dark'"

    log-success "Visual settings applied"
}

#######################################
# Overrides Flatpak permission to allow theme access.
# grants read-only access to icon and theme directories.
# Globals:
#   GTK_THEME
# Arguments:
#   None
#######################################
override-flatpak-icons() {
    log-info "Overriding Flatpak icons..."
    flatpak override --user --filesystem=~/.icons:ro
    flatpak override --user --filesystem=~/.local/share/icons:ro
    flatpak override --user --filesystem=/usr/share/icons:ro
    flatpak override --user --filesystem=~/.themes:ro
    flatpak override --user --filesystem=~/.local/share/themes:ro
    flatpak override --user --env=GTK_THEME="$GTK_THEME"
    log-success "Flatpak permissions updated"
}

#######################################
# Main entry point for the theme setup script.
# Arguments:
#   None
#######################################
main() {
    ensure-user
    install-orchis
    clean-orchis-variants
    apply-theme
    override-flatpak-icons
}


main "$@"

#!/usr/bin/env zsh
# Set Themes (Orchis + Papirus)
# Installs Orchis GTK theme (Premium Dark) and Papirus Icons

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

readonly ICON_THEME="Papirus-Dark" # Ensure we use Dark icons
readonly GTK_THEME="Orchis-Dark-Compact" # We will install the compact version
readonly ORCHIS_REPO="https://github.com/vinceliuice/Orchis-theme.git"
readonly THEME_DIR="$HOME/.local/share/themes"
readonly FONT_DIR="$HOME/.local/share/fonts"
readonly INTER_FONT_URL="https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"


#######################################
# Downloads and installs the Inter font family.
# Globals:
#   FONT_DIR
#   INTER_FONT_URL
# Arguments:
#   None
#######################################
install-inter-font() {
    log-info "Installing Inter font..."

    if [[ -d "$FONT_DIR/Inter" ]]; then
        log-info "Inter font already installed."
        return
    fi

    mkdir -p "$FONT_DIR"
    local temp_zip
    temp_zip="$(mktemp).zip"

    log-info "Downloading Inter font..."
    curl -LDo "$temp_zip" "$INTER_FONT_URL"

    log-info "Extracting Inter font..."
    unzip -o "$temp_zip" -d "$FONT_DIR/Inter" >/dev/null

    rm -f "$temp_zip"

    # Update font cache
    fc-cache -f "$FONT_DIR"

    log-success "Inter font installed."
}

#######################################
# Installs the Orchis GTK theme from source.
# Clones the repository, installs Dark and Light variants,
# and minimizes the installation size.
# Tweaks: Black, Solid, Primary opacity.
# Globals:
#   ORCHIS_REPO
#   THEME_DIR
#   HOME
# Arguments:
#   None
#######################################
install-orchis() {
    log-info "Installing Orchis theme (Premium Dark)..."

    local work_dir
    work_dir="$(mktemp -d)"

    mkdir -p "$THEME_DIR"
    git clone --depth 1 "$ORCHIS_REPO" "$work_dir/orchis"

    pushd "$work_dir/orchis" > /dev/null

    # Install Dark variants with premium tweaks
    # -c dark: Dark version
    # -t black: Deep black background
    # -t solid: Solid panels (no transparency issues)
    # -t primary: Primary color tweaks
    # --tweaks compact: Compact version for better density
    ./install.sh -c dark -t black solid primary --tweaks compact --shell --libadwaita

    popd > /dev/null

    rm -rf "$work_dir"
    log-success "Orchis theme installed (Premium Dark)"
}

#######################################
# Removes unused Orchis theme variants.
# Iterates through the theme directory and removes any variant
# that is not our target 'Orchis-Dark-Compact'.
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
            # Keep only the specifically installed variant (and maybe standard Dark as fallback if needed, but we want strict adherence)
            if [[ "$theme_name" != "Orchis-Dark-Compact" ]]; then
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
# Sets Inter as the interface font.
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

    # Ensure Shell matches the dark theme (User Theme extension must be enabled)
    # The install script usually names the shell theme "Orchis-Dark-Compact" if installed with those flags
    dconf write /org/gnome/shell/extensions/user-theme/name "'$GTK_THEME'"

    # Set Fonts
    log-info "Setting UI fonts..."
    dconf write /org/gnome/desktop/interface/font-name "'Inter Regular 11'"
    dconf write /org/gnome/desktop/interface/document-font-name "'Inter Regular 11'"
    dconf write /org/gnome/desktop/interface/monospace-font-name "'Monospace 10'"
    dconf write /org/gnome/desktop/wm/preferences/titlebar-font "'Inter Bold 11'"

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
    install-inter-font
    install-orchis
    clean-orchis-variants
    apply-theme
    override-flatpak-icons
}

main "$@"

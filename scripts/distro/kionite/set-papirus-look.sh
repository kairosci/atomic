#!/usr/bin/env zsh
# @file set-papirus-look.sh
# @brief Applies Papirus theme and icons to Kionite
# @description
#   Configures KDE with Papirus icons, BreezeDark theme,
#   window buttons on right, and optimized animations.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

# @description Writes a KDE config value using kwriteconfig.
# @arg $1 string Config file name
# @arg $2 string Group name
# @arg $3 string Key name
# @arg $4 string Value
apply-kwrite() {
    local file="$1" group="$2" key="$3" value="$4"

    for tool in kwriteconfig6 kwriteconfig5; do
        if command -v "$tool" &>/dev/null; then
            "$tool" --file "$file" --group "$group" --key "$key" "$value"
            return
        fi
    done

    log-warn "No kwriteconfig tool found."
}

# @description Reloads KWin configuration.
reload-kwin() {
    for tool in qdbus6 qdbus qdbus-qt5; do
        if command -v "$tool" &>/dev/null; then
            "$tool" org.kde.KWin /KWin reconfigure 2>/dev/null || true
            return
        fi
    done
}

# @description Applies Papirus icons and BreezeDark theme.
configure-theme() {
    log-info "Applying Papirus theme..."

    apply-kwrite "kdeglobals" "Icons" "Theme" "Papirus"
    apply-kwrite "kcminputrc" "Mouse" "cursorTheme" "breeze_cursors"
    apply-kwrite "kdeglobals" "General" "ColorScheme" "BreezeDark"

    local font="Noto Sans,10,-1,5,50,0,0,0,0,0"
    local font_mono="Noto Sans Mono,10,-1,5,50,0,0,0,0,0"

    apply-kwrite "kdeglobals" "General" "font" "$font"
    apply-kwrite "kdeglobals" "General" "menuFont" "$font"
    apply-kwrite "kdeglobals" "General" "toolBarFont" "$font"
    apply-kwrite "kdeglobals" "General" "smallestReadableFont" "Noto Sans,8,-1,5,50,0,0,0,0,0"
    apply-kwrite "kdeglobals" "WM" "activeFont" "Noto Sans,10,-1,5,75,0,0,0,0,0"
    apply-kwrite "kdeglobals" "General" "fixed" "$font_mono"
}

# @description Configures KWin window buttons on right side.
configure-kwin() {
    log-info "Configuring window buttons (right side)..."

    apply-kwrite "kwinrc" "org.kde.kdecoration2" "ButtonsOnLeft" "M"
    apply-kwrite "kwinrc" "org.kde.kdecoration2" "ButtonsOnRight" "IAX"
    apply-kwrite "kwinrc" "TabBox" "LayoutName" "thumbnail_grid"

    reload-kwin
}

# @description Optimizes KWin animations.
configure-animations() {
    log-info "Optimizing animations..."

    apply-kwrite "kdeglobals" "KDE" "AnimationDurationFactor" "0.5"
    apply-kwrite "kwinrc" "Compositing" "LatencyPolicy" "High"

    reload-kwin
}

# @description Overrides Flatpak permissions for icons.
override-flatpak-icons() {
    log-info "Overriding Flatpak icons..."
    flatpak override --user --filesystem=~/.icons:ro
    flatpak override --user --filesystem=~/.local/share/icons:ro
    flatpak override --user --filesystem=/usr/share/icons:ro
    log-success "Flatpak icons overridden"
}

# @description Main entry point.
main() {
    ensure-user

    configure-theme
    configure-kwin
    configure-animations
    override-flatpak-icons

    log-success "Papirus look applied"
}

main "$@"

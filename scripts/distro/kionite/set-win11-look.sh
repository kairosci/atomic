#!/usr/bin/env zsh
# @file set-win11-look.sh
# @brief Configures KDE Plasma to look like Windows 11
# @description
#   Applies Windows 11-style theming to KDE:
#   - Floating centered bottom panel
#   - Floating top panel with rounded corners
#   - Rounded window corners
#   - Centered taskbar icons (if possible via config)

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

# Configuration constants
readonly CORNER_RADIUS="10"
readonly ICON_THEME="Papirus-Light"

#######################################
# Writes a KDE configuration value.
#######################################
apply-kwrite() {
    local file="$1" group="$2" key="$3" value="$4"
    for tool in kwriteconfig6 kwriteconfig5; do
        if command-v "$tool" &>/dev/null; then
            "$tool" --file "$file" --group "$group" --key "$key" "$value"
            return
        fi
    done
}

#######################################
# Reloads KWin.
#######################################
reload-kwin() {
    for tool in qdbus6 qdbus qdbus-qt5; do
        if command-v "$tool" &>/dev/null; then
            "$tool" org.kde.KWin /KWin reconfigure 2>/dev/null && return
        fi
    done
}

#######################################
# Sprint 1: Look & Feel
#######################################
configure-look-feel() {
    log-info "Sprint 1: Configuring Windows 11 Look & Feel..."

    # Global Theme & Colors
    apply-kwrite "kdeglobals" "General" "ColorScheme" "BreezeLight"
    apply-kwrite "kdeglobals" "Icons" "Theme" "$ICON_THEME"

    # Window Decorations: Rounded Corners & Centered Title
    apply-kwrite "kwinrc" "org.kde.kdecoration2" "ButtonsOnLeft" ""
    apply-kwrite "kwinrc" "org.kde.kdecoration2" "ButtonsOnRight" "IAX"
    apply-kwrite "kwinrc" "org.kde.kdecoration2" "CloseOnDoubleClickOnMenu" "false"

    # Breeze specific rounding
    apply-kwrite "breezerc" "Common" "CornerRadius" "$CORNER_RADIUS"
    apply-kwrite "breezerc" "Windeco" "CornerRadius" "$CORNER_RADIUS"

    # Centered Title (requires specific decoration or newer Plasma)
    # Most modern Breeze versions support it via alignment
    apply-kwrite "kwinrc" "org.kde.kdecoration2" "TitleAlignment" "Center"

    reload-kwin
    log-success "Sprint 1 completed"
}

#######################################
# Sprint 2 & 3: Panels (The "De-Spiking")
#######################################
configure-panels() {
    log-info "Sprint 2 & 3: Configuring Floating & Rounded Panels..."

    # Enable floating panels globally (Plasma 5.25+)
    # This involves setting the floating property in plasmashellrc
    # We target both top and bottom panels often used in these setups

    apply-kwrite "plasmashellrc" "Panel" "Floating" "1"

    # Centering icons (Windows 11 style)
    # This is typically handled by the 'Icons-only Task Manager' settings
    # We can hint it via configuration
    # apply-kwrite "plasmashellrc" "Applets" "alignment" "1" # Center alignment if available

    # Specifically for the "Top Panel" mentioned by the user
    # We ensure opacity and floating are set to make it less 'sharp'
    apply-kwrite "plasmashellrc" "PlasmaViews" "panelOpacity" "2" # Adaptive

    log-success "Panels configured for floating mode and adaptive opacity"
}

#######################################
# Sprint 4: Integration
#######################################
configure-integration() {
    log-info "Sprint 4: Finalizing Integration..."

    # Faster animations to feel like Win11
    apply-kwrite "kdeglobals" "KDE" "AnimationDurationFactor" "0.5"

    log-success "Integration steps completed"
}

#######################################
# Main
#######################################
main() {
    ensure-user
    log-title "KDE Windows 11 Transformation"

    configure-look-feel
    configure-panels
    configure-integration

    log-success "Windows 11 look applied!"
    log-info "Please restart your session or run: kquitapp6 plasmashell && plasmashell &"
}

main "$@"

#!/usr/bin/bash
# Set Papirus Look (Kionite)

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

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

reload-kwin() {
    for tool in qdbus6 qdbus qdbus-qt5; do
        if command -v "$tool" &>/dev/null; then
            "$tool" org.kde.KWin /KWin reconfigure 2>/dev/null || true
            return
        fi
    done
}

configure-theme() {
    log-info "Applying Papirus theme..."
    
    apply-kwrite "kdeglobals" "Icons" "Theme" "Papirus"
    # Use default Breeze cursor as Papirus doesn't provide one
    apply-kwrite "kcminputrc" "Mouse" "cursorTheme" "breeze_cursors"
    apply-kwrite "kdeglobals" "General" "ColorScheme" "BreezeDark"
    
    # Reset fonts to Fedora defaults (Noto Sans)
    local font="Noto Sans,10,-1,5,50,0,0,0,0,0"
    local font_mono="Noto Sans Mono,10,-1,5,50,0,0,0,0,0"
    
    apply-kwrite "kdeglobals" "General" "font" "$font"
    apply-kwrite "kdeglobals" "General" "menuFont" "$font"
    apply-kwrite "kdeglobals" "General" "toolBarFont" "$font"
    apply-kwrite "kdeglobals" "General" "smallestReadableFont" "Noto Sans,8,-1,5,50,0,0,0,0,0"
    apply-kwrite "kdeglobals" "WM" "activeFont" "Noto Sans,10,-1,5,75,0,0,0,0,0"
    apply-kwrite "kdeglobals" "General" "fixed" "$font_mono"
}

configure-kwin() {
    log-info "Configuring window buttons (left side)..."
    
    apply-kwrite "kwinrc" "org.kde.kdecoration2" "ButtonsOnLeft" "XIA"
    apply-kwrite "kwinrc" "org.kde.kdecoration2" "ButtonsOnRight" "M"
    apply-kwrite "kwinrc" "TabBox" "LayoutName" "thumbnail_grid"
    
    reload-kwin
}

configure-animations() {
    log-info "Optimizing animations..."

    apply-kwrite "kdeglobals" "KDE" "AnimationDurationFactor" "0.5"
    apply-kwrite "kwinrc" "Compositing" "LatencyPolicy" "High"
    
    reload-kwin
}

override-flatpak-icons() {
    log-info "Overriding Flatpak icons..."
    flatpak override --user --filesystem=~/.icons:ro
    flatpak override --user --filesystem=~/.local/share/icons:ro
    flatpak override --user --filesystem=/usr/share/icons:ro
    log-success "Flatpak icons overridden"
}

main() {
    ensure-user
    
    configure-theme
    configure-kwin
    configure-animations
    override-flatpak-icons
    
    log-success "Papirus look applied"
}

main "$@"

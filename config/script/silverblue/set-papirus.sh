#!/usr/bin/bash
# Set Papirus Theme (Silverblue)

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

readonly ICON_THEME="Papirus"

apply-papirus-theme() {
    log-info "Applying Papirus theme for GNOME"
    
    # Reset GTK/Cursor/Sound to default (Adwaita) as Yaru is removed
    dconf reset /org/gnome/desktop/interface/gtk-theme
    dconf reset /org/gnome/desktop/interface/cursor-theme
    dconf reset /org/gnome/desktop/sound/theme-name
    
    # Set Icons to Papirus
    dconf write /org/gnome/desktop/interface/icon-theme "'$ICON_THEME'"
    
    # Set Dark Mode
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    
    log-success "Papirus theme applied"
}

main() {
    ensure-user
    apply-papirus-theme
}

main "$@"

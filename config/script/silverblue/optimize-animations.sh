#!/usr/bin/env zsh
# Optimize Animations (Silverblue)

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

optimize-animations() {
    log-info "Optimizing GNOME Animations..."

    dconf write /org/gnome/desktop/interface/enable-animations true
    
    local speed=5
    log-info "Setting Just Perfection Animation Speed to $speed (Very Fast)"
    dconf write /org/gnome/shell/extensions/just-perfection/animation "$speed"

    if dconf list /org/gnome/shell/extensions/dash-to-dock/ &>/dev/null; then
        log-info "Optimizing Dash to Dock animations..."
        dconf write /org/gnome/shell/extensions/dash-to-dock/animation-time 0.20
    fi
    
    if dconf list /org/gnome/shell/extensions/blur-my-shell/ &>/dev/null; then
        log-info "Tuning Blur My Shell for performance..."
        dconf write /org/gnome/shell/extensions/blur-my-shell/noise-amount 0.0
        dconf write /org/gnome/shell/extensions/blur-my-shell/brightness 1.0
        dconf write /org/gnome/shell/extensions/blur-my-shell/sigma 30
    fi

    dconf write /org/gnome/mutter/center-new-windows true
    
    log-success "GNOME animation settings applied."
}

main() {
    ensure-user
    optimize-animations
}

main "$@"

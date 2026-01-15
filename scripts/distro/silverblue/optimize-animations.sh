#!/usr/bin/env zsh
# Optimize Animations (Silverblue)

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

#######################################
# Optimizes GNOME animations for a premium, snappy feel.
# Adjusts animation speeds and corner radii globally.
# Globals:
#   None
# Arguments:
#   None
#######################################
optimize-animations() {
    log-info "Optimizing GNOME Animations (Premium Feel)..."

    dconf write /org/gnome/desktop/interface/enable-animations true

    # Speed: 4 is snappy but visible (not instant like 5 or 0)
    # This gives it a "high refresh rate" feel even on standard screens
    local speed=4
    log-info "Setting Just Perfection Animation Speed to $speed (Snappy)"
    dconf write /org/gnome/shell/extensions/just-perfection/animation "$speed"

    # Remove rounded corners (1 = no border/radius)
    log-info "Setting sharp corners (no rounded borders)..."
    dconf write /org/gnome/shell/extensions/just-perfection/panel-corner-size 1
    dconf write /org/gnome/shell/extensions/just-perfection/workspace-background-corner-size 1

    if dconf list /org/gnome/shell/extensions/dash-to-dock/ &>/dev/null; then
        log-info "Optimizing Dash to Dock animations..."
        # 0.25s is fluid; 0.20 was a bit too fast for the premium fade
        dconf write /org/gnome/shell/extensions/dash-to-dock/animation-time 0.25
    fi

    if dconf list /org/gnome/shell/extensions/blur-my-shell/ &>/dev/null; then
        log-info "Tuning Blur My Shell for performance..."
        # Ensure performant but pretty blur
        dconf write /org/gnome/shell/extensions/blur-my-shell/sigma 30
    fi

    dconf write /org/gnome/mutter/center-new-windows true

    log-success "GNOME animation settings applied."
}

#######################################
# Main entry point for the animation optimization script.
# Arguments:
#   None
#######################################
main() {
    ensure-user
    optimize-animations
}

main "$@"

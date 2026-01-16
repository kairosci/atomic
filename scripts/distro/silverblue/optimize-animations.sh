#!/usr/bin/env zsh
# @file optimize-animations.sh
# @brief Optimizes GNOME animations for Silverblue
# @description
#   Configures animation speeds, corner radii, and extension settings
#   for a snappy, premium feel.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

# @description Optimizes GNOME animations for a premium, snappy feel.
optimize-animations() {
    log-info "Optimizing GNOME Animations (Premium Feel)..."

    dconf write /org/gnome/desktop/interface/enable-animations true

    local speed=4
    log-info "Setting Just Perfection Animation Speed to $speed (Snappy)"
    dconf write /org/gnome/shell/extensions/just-perfection/animation "$speed"

    log-info "Setting sharp corners (no rounded borders)..."
    dconf write /org/gnome/shell/extensions/just-perfection/panel-corner-size 1
    dconf write /org/gnome/shell/extensions/just-perfection/workspace-background-corner-size 1

    if dconf list /org/gnome/shell/extensions/dash-to-dock/ &>/dev/null; then
        log-info "Optimizing Dash to Dock animations..."
        dconf write /org/gnome/shell/extensions/dash-to-dock/animation-time 0.25
    fi

    if dconf list /org/gnome/shell/extensions/blur-my-shell/ &>/dev/null; then
        log-info "Tuning Blur My Shell for performance..."
        dconf write /org/gnome/shell/extensions/blur-my-shell/sigma 30
    fi

    dconf write /org/gnome/mutter/center-new-windows true

    log-success "GNOME animation settings applied."
}

# @description Main entry point.
main() {
    ensure-user
    optimize-animations
}

main "$@"

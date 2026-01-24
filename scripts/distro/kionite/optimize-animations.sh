#!/usr/bin/env zsh
# @file optimize-animations.sh
# @brief Optimizes KWin animations for Kionite
# @description
#   Configures animation duration and compositing latency.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

# @description Optimizes KWin animations for snappy feel.
optimize-animations() {
    log-info "Optimizing KWin Animations..."

    local speed="0.5"
    local config_tool="kwriteconfig5"

    log-info "Setting Animation Duration Factor to $speed"
    command -v kwriteconfig6 &>/dev/null && config_tool="kwriteconfig6"

    "$config_tool" --file kdeglobals --group KDE --key AnimationDurationFactor "$speed"
    "$config_tool" --file kwinrc --group Compositing --key LatencyPolicy "High"

    log-success "Animation settings applied."

    log-info "Reloading KWin..."
    if command -v qdbus6 &>/dev/null; then
        if ! qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null; then
            log-warn "Failed to reload KWin via qdbus6"
        fi
    elif command -v qdbus &>/dev/null; then
        if ! qdbus org.kde.KWin /KWin reconfigure 2>/dev/null; then
            log-warn "Failed to reload KWin via qdbus"
        fi
    elif command -v qdbus-qt5 &>/dev/null; then
        if ! qdbus-qt5 org.kde.KWin /KWin reconfigure 2>/dev/null; then
            log-warn "Failed to reload KWin via qdbus-qt5"
        fi
    fi
}

# @description Main entry point.
main() {
    ensure-user
    optimize-animations
}

main "$@"

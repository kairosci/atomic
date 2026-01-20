#!/usr/bin/env zsh
# Optimize Animations (Kionite)

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

optimize-animations() {
    log-info "Optimizing KWin Animations..."

    local speed="0.5"

    log-info "Setting Animation Duration Factor to $speed"

    local config_tool="kwriteconfig5"
    command -v kwriteconfig6 &>/dev/null && config_tool="kwriteconfig6"

    "$config_tool" --file kdeglobals --group KDE --key AnimationDurationFactor "$speed"
    "$config_tool" --file kwinrc --group Compositing --key LatencyPolicy "High"

    log-success "Animation settings applied."

    log-info "Reloading KWin..."
    if command -v qdbus6 &>/dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v qdbus &>/dev/null; then
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v qdbus-qt5 &>/dev/null; then
        qdbus-qt5 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi
}

main() {
    ensure-user
    optimize-animations
}

main "$@"

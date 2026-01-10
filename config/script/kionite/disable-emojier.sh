#!/usr/bin/env zsh
# =============================================================================
# Disable Plasma Emojier
# Hides the KDE emoji selector via local desktop override
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Main Function
# =============================================================================

disable-plasma-emojier() {
    log-info "Disabling plasma-emojier"
    
    local user_home
    user_home="$(get-user-home)"
    
    local apps_dir="$user_home/.local/share/applications"
    local desktop_file="$apps_dir/org.kde.plasma.emojier.desktop"
    
    mkdir -p "$apps_dir"
    
    if [[ ! -f "$desktop_file" ]]; then
        cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=Emoji Selector
Hidden=true
NoDisplay=true
EOF
        fix-ownership "$desktop_file"
        log-success "Emojier hidden"
    else
        log-info "Emojier already hidden"
    fi
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    disable-plasma-emojier
}

main "$@"

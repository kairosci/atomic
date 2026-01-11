#!/usr/bin/env zsh
# *****************************************************************************
# Set Konsole Profile
# Creates a custom Konsole profile with Adwaita Mono font
# *****************************************************************************

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

# *****************************************************************************
# Constants
# *****************************************************************************

readonly PROFILE_NAME="Kionite"
readonly FONT_CONFIG="Adwaita Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

# *****************************************************************************
# Main Function
# *****************************************************************************

setup-konsole() {
    log-info "Creating Konsole profile '$PROFILE_NAME'"
    
    local user_home
    user_home="$(get-user-home)"
    
    local konsole_dir="$user_home/.local/share/konsole"
    local profile_path="$konsole_dir/$PROFILE_NAME.profile"
    
    mkdir -p "$konsole_dir"
    
    cat > "$profile_path" <<EOF
[Appearance]
Font=$FONT_CONFIG

[General]
Name=$PROFILE_NAME
Parent=FALLBACK/
EOF
    
    fix-ownership "$konsole_dir"
    fix-ownership "$profile_path"
    
    log-success "Konsole profile '$PROFILE_NAME' created"
}

# *****************************************************************************
# Entry Point
# *****************************************************************************

main() {
    ensure-root
    setup-konsole
}

main "$@"

#!/usr/bin/env zsh
# @file set-konsole.sh
# @brief Creates a custom Konsole profile
# @description
#   Sets up a Konsole profile with Adwaita Mono font.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

readonly PROFILE_NAME="Kionite"
readonly FONT_CONFIG="Adwaita Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

# @description Creates custom Konsole profile.
setup-konsole() {
    log-info "Creating Konsole profile '$PROFILE_NAME'"

    local user_home konsole_dir profile_path
    user_home="$(get-user-home)"
    konsole_dir="$user_home/.local/share/konsole"
    profile_path="$konsole_dir/$PROFILE_NAME.profile"

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

# @description Main entry point.
main() {
    ensure-root
    setup-konsole
}

main "$@"

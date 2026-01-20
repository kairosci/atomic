#!/usr/bin/bash
# =============================================================================
# Set Oh My Bash
# Installs and configures Oh My Bash with vscode theme
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Constants
# =============================================================================

readonly OMB_THEME="vscode"
readonly OMB_INSTALL_URL="https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh"

# =============================================================================
# Main Function
# =============================================================================

setup-omb() {
    log-info "Configuring Oh My Bash"
    
    local user_home
    user_home="$(get-user-home)"
    
    local real_user
    real_user="$(get-real-user)"
    
    local omb_dir="$user_home/.oh-my-bash"
    local bashrc="$user_home/.bashrc"
    
    # Check dependencies
    require-command git "git is required for Oh My Bash"
    require-command curl "curl is required for Oh My Bash"
    
    # Install Oh My Bash if missing
    if [[ ! -d "$omb_dir" ]]; then
        log-info "Installing Oh My Bash"
        curl -fsSL "$OMB_INSTALL_URL" | sudo -u "$real_user" bash -s -- --unattended
    else
        log-info "Oh My Bash already installed"
    fi
    
    # Configure theme
    if [[ -f "$bashrc" ]]; then
        if grep -q "OSH_THEME=\"$OMB_THEME\"" "$bashrc"; then
            log-info "Theme already set to '$OMB_THEME'"
        else
            log-info "Setting theme to '$OMB_THEME'"
            sed -i "s/^OSH_THEME=\".*\"/OSH_THEME=\"$OMB_THEME\"/" "$bashrc"
            
            if ! grep -q 'OSH_THEME=' "$bashrc"; then
                echo "OSH_THEME=\"$OMB_THEME\"" >> "$bashrc"
            fi
            
            fix-ownership "$bashrc"
            log-success "Theme updated. Restart terminal to apply."
        fi
    fi
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    require-root
    setup-omb
}

main "$@"

#!/usr/bin/bash
# =============================================================================
# Set Oh My Zsh
# Installs Oh My Zsh, removes Oh My Bash, and configures Zsh as default
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Constants
# =============================================================================

readonly OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
readonly ZSH_PATH="/usr/bin/zsh"

# =============================================================================
# Main Functions
# =============================================================================

cleanup-omb() {
    local user_home
    user_home="$(get-user-home)"
    local omb_dir="$user_home/.oh-my-bash"
    local bashrc="$user_home/.bashrc"
    
    if [[ -d "$omb_dir" ]]; then
        log-info "Removing Oh My Bash directory..."
        rm -rf "$omb_dir"
    fi
    
    if [[ -f "$bashrc" ]]; then
        log-info "Cleaning up Oh My Bash entries in .bashrc..."
        sed -i '/OSH/d' "$bashrc"
        sed -i '/oh-my-bash/d' "$bashrc"
    fi
}

install-omz() {
    local user_home
    user_home="$(get-user-home)"
    local real_user
    real_user="$(get-real-user)"
    local omz_dir="$user_home/.oh-my-zsh"
    
    # Check dependencies
    require-command git "git is required for Oh My Zsh"
    require-command curl "curl is required for Oh My Zsh"
    
    if ! command-exists zsh; then
        log-warn "zsh is not installed or not in PATH."
        log-warn "If you just installed it via set-rpm.sh, a system reboot is required."
        log-warn "Please reboot and try again."
        return 0
    fi
    
    # Install Oh My Zsh if missing
    if [[ ! -d "$omz_dir" ]]; then
        log-info "Installing Oh My Zsh..."
        curl -fsSL "$OMZ_INSTALL_URL" | sudo -u "$real_user" zsh -s -- --unattended > /dev/null 2>&1
        log-success "Oh My Zsh installed"
    else
        log-info "Oh My Zsh already installed"
    fi
}

set-default-shell() {
    local real_user
    real_user="$(get-real-user)"
    
    log-info "Changing default shell to zsh for $real_user..."
    
    if [[ -f "$ZSH_PATH" ]]; then
        chsh -s "$ZSH_PATH" "$real_user"
        log-success "Shell changed to $ZSH_PATH. Please log out and back in for changes to take effect."
    else
        log-error "zsh not found at $ZSH_PATH"
    fi
}

configure-zshrc() {
    local user_home
    user_home="$(get-user-home)"
    local zshrc="$user_home/.zshrc"
    
    if [[ ! -f "$zshrc" ]]; then
        log-warn ".zshrc not found, skipping theme configuration"
        return 0
    fi
    
    log-info "Configuring zsh theme to 'refined'..."
    
    # Change the theme from robbyrussell (default) to refined
    if grep -q 'ZSH_THEME="robbyrussell"' "$zshrc"; then
        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="refined"/' "$zshrc"
        log-success "Theme set to 'refined'"
    elif grep -q 'ZSH_THEME=' "$zshrc"; then
        # Replace any existing theme
        sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="refined"/' "$zshrc"
        log-success "Theme updated to 'refined'"
    else
        log-warn "ZSH_THEME not found in .zshrc"
    fi
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    ensure-root
    cleanup-omb
    install-omz
    configure-zshrc
    set-default-shell
}

main "$@"

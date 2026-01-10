#!/usr/bin/env zsh
# =============================================================================
# Fedora Atomic Setup
# Installs Atomic Manager and configures global access
# =============================================================================

set -euo pipefail

# Get script directory
readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"

# Source common library
source "$SCRIPT_DIR/lib/common.sh"

set-permissions() {
    log-info "Setting executable permissions..."
    chmod +x "$SCRIPT_DIR/index.sh" \
             "$SCRIPT_DIR/config/index.sh" \
             "$SCRIPT_DIR/config/script/"*.sh \
             "$SCRIPT_DIR/config/script/kionite/"*.sh \
             "$SCRIPT_DIR/config/script/silverblue/"*.sh \
             "$SCRIPT_DIR/utils/"*.sh \
             "$SCRIPT_DIR/lib/"*.sh 2>/dev/null || true
}

install-symlink() {
    log-info "Installing symlink..."
    
    # Use /usr/local/bin as /usr/bin is read-only on Silverblue/Kionite
    local link_path="/usr/local/bin/atomic"
    
    # Ensure /usr/local/bin exists
    if [[ ! -d "/usr/local/bin" ]]; then
        mkdir -p "/usr/local/bin"
    fi
    
    if [[ -L "$link_path" ]]; then
        rm "$link_path"
    fi
    
    ln -s "$SCRIPT_DIR/index.sh" "$link_path"
    
    if [[ -x "$link_path" ]]; then
        log-success "Symlink created at $link_path"
    else
        log-error "Failed to create symlink"
        exit 1
    fi
    
    # Cleanup old aliases if they exist
    local user_home
    user_home="$(get-user-home)"
    local bashrc="$user_home/.bashrc"
    
    if [[ -f "$bashrc" ]]; then
        if grep -q "alias atomic=" "$bashrc" || grep -q "alias kionite=" "$bashrc"; then
            log-info "Cleaning up old aliases from .bashrc..."
            sed -i '/# Fedora Atomic Manager/d' "$bashrc"
            sed -i '/alias atomic=/d' "$bashrc"
            sed -i '/# Kionite Manager/d' "$bashrc"
            sed -i '/alias kionite=/d' "$bashrc"
            sed -i "/alias sudo='sudo '/d" "$bashrc"
            log-success "Aliases removed (using system-wide command instead)"
        fi
    fi
}

main() {
    ensure-root
    
    local distro
    distro="$(detect-distro)"
    
    log-info "Installing Fedora Atomic Manager..."
    log-info "Detected: $distro"
    
    set-permissions
    install-symlink
    
    log-success "Installation completed!"
    log-info "You can now run 'atomic' from anywhere (after restarting terminal)."
}

main "$@"

#!/usr/bin/env zsh
# @file setup.sh
# @brief Installs Fedora Atomic Manager
# @description
#   Sets up executable permissions and creates a global symlink
#   for the atomic command.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"

source "$SCRIPT_DIR/lib/common.sh"

# @description Sets executable permissions on all scripts.
set-permissions() {
    log-info "Setting executable permissions..."
    chmod +x "$SCRIPT_DIR/index.sh" \
             "$SCRIPT_DIR/scripts/configure.sh" \
             "$SCRIPT_DIR/scripts/core/"*.sh \
             "$SCRIPT_DIR/scripts/distro/kionite/"*.sh \
             "$SCRIPT_DIR/scripts/distro/silverblue/"*.sh \
             "$SCRIPT_DIR/scripts/utils/"*.sh \
             "$SCRIPT_DIR/scripts/utils/folder-protection/"*.sh \
             "$SCRIPT_DIR/lib/"*.sh 2>/dev/null || true
}

# @description Installs the atomic command symlink.
install-symlink() {
    log-info "Installing symlink..."

    local link_path="/usr/local/bin/atomic"

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

    local user_home bashrc
    user_home="$(get-user-home)"
    bashrc="$user_home/.bashrc"

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

# @description Main entry point.
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

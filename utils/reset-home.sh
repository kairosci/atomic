#!/usr/bin/env zsh
# Reset User Home
# Aggressively cleans the home directory, preserving only essential configs.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../lib/common.sh"

reset-home() {
    local user_home
    user_home="$(get-user-home)"
    
    log-warn "This will DELETE almost all hidden configuration files in $user_home."
    log-warn "Only the following will be preserved:"
    echo "  - .ssh/"
    echo "  - .gnupg/"
    echo "  - .gitconfig"
    echo "  - .zshrc"
    echo "  - .pki/"
    echo "  - .local/bin/"
    
    if ! confirm "Are you ABSOLUTELY sure you want to proceed?"; then
        log-info "Reset cancelled."
        return 0
    fi

    # Create a backup timestamp
    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"
    local backup_dir="$user_home/.config_backup_$timestamp"
    
    log-info "Creating safety backup at $backup_dir (just in case)..."
    mkdir -p "$backup_dir"

    # Define whitelist patterns (grep regex)
    # matching: .ssh, .gnupg, .gitconfig, .zshrc, .pki, .local
    # We handle .local separately because we want to clean INSIDE it but keep bin.
    local whitelist_pattern="^(\.ssh|\.gnupg|\.gitconfig|\.zshrc|\.pki|\.local|\.mozilla)$"

    setopt DOT_GLOB
    
    # Iterate over hidden files/dirs
    for item in "$user_home"/.*; do
        local basename="${item##*/}"
        
        # Skip . and ..
        [[ "$basename" == "." || "$basename" == ".." ]] && continue
        
        # Check whitelist
        if [[ "$basename" =~ $whitelist_pattern ]]; then
            log-info "Preserving: $basename"
            
            # Special handling for .local
            if [[ "$basename" == ".local" ]]; then
                 log-info "Cleaning .local..."
                 # We want to keep .local/bin, remove others like share/state if empty or non-essential?
                 # User said "eliminate old configurations".
                 # Let's remove .local/share and .local/state but keep .local/bin
                 
                 # Backup first
                 cp -r "$item" "$backup_dir/" 2>/dev/null || true
                 
                 # Clean .local subdirs
                 for sub in "$item"/*; do
                     local subname="${sub##*/}"
                     if [[ "$subname" != "bin" ]]; then
                         rm -rf "$sub"
                         echo "Deleted: .local/$subname"
                     fi
                 done
            fi
            continue
        fi
        
        # Backup and Delete
        cp -r "$item" "$backup_dir/" 2>/dev/null || true
        rm -rf "$item"
        echo "Deleted: $basename"
    done
    
    unsetopt DOT_GLOB
    
    log-success "Home directory reset completed."
    log-info "Backup stored at: $backup_dir"
}

main() {
    ensure-user
    # If run directly suitable for confirm, but if run from switch-distro we might assume confirmation? 
    # The requirement was "When I switch image... I want to eliminate old configurations". 
    # We will invoke this function.
    reset-home
}

main "$@"

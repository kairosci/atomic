#!/usr/bin/env zsh
# Clean Orphan Directories

set -e

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly -a SAFE_DIRS=(
    "autostart" "dconf" "evolution" "gnome-session" "gtk-3.0" "gtk-4.0"
    "kde.org" "kdedefaults" "kconf_updater" "kwin" "latte" "plasma-workspace"
    "pulse" "systemd" "user-dirs.dirs" "mimeapps.list" "fontconfig"
    "menus" "icons" "themes" "applications" "desktop-directories"
    "lib" "bin" "flatpak" "keyrings" "fonts" "icc" "sounds" "wallpaper"
    "Trash" "kpeople" "kxmlgui5" "session" "xsettings" "akonadi" "baloo"
    "kwalletd" "fish" "zsh" "bash"
)

is-safe-dir() {
    local dir_name="$1"
    for safe in "${SAFE_DIRS[@]}"; do
        [[ "$dir_name" == "$safe" ]] && return 0
    done
    return 1
}

check-package-exists() {
    local name="$1"
    local lower_name="${name,,}"
    
    flatpak list --app --columns=application | grep -qi "$name" && return 0
    rpm -qa | grep -qi "$name" && return 0
    command -v "$name" &>/dev/null && return 0
    command -v "$lower_name" &>/dev/null && return 0
    
    return 1
}

scan-directory() {
    local target_dir="$1"
    local desc="$2"
    
    [[ -d "$target_dir" ]] || { log-warn "Directory not found: $target_dir"; return; }
    
    log-info "Scanning $target_dir ($desc)..."
    
    for dir_path in "$target_dir"/*; do
        [[ -d "$dir_path" ]] || continue
        
        local dir_name
        dir_name="$(basename "$dir_path")"
        
        is-safe-dir "$dir_name" && continue
        
        if check-package-exists "$dir_name"; then
            echo -e "\e[32m[FOUND]\e[0m $dir_name"
        else
            echo -e "\e[33m[ORPHAN?]\e[0m $dir_name"
            
            read -p "    Delete '$dir_name'? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log-info "Deleting $dir_name..."
                rm -rf "$dir_path"
                log-success "Deleted."
            else
                echo "    Skipped."
            fi
        fi
    done
}

main() {
    ensure-user
    
    echo "************************************************==="
    echo " CLEAN ORPHANED CONFIGURATIONS"
    echo "************************************************==="
    
    scan-directory "$HOME/.config" "User Config"
    scan-directory "$HOME/.local/share" "Local Data"
    
    log-info "Scanning Flatpak data (~/.var/app)..."
    if [[ -d "$HOME/.var/app" ]]; then
        for app_dir in "$HOME/.var/app"/*; do
            [[ -d "$app_dir" ]] || continue
            local app_id
            app_id="$(basename "$app_dir")"
            
            if ! flatpak list --app --columns=application | grep -q "^$app_id$"; then
                echo -e "\e[33m[ORPHAN FLATPAK]\e[0m $app_id"
                read -p "    Delete data for uninstalled Flatpak '$app_id'? [y/N] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log-info "Deleting $app_id data..."
                    rm -rf "$app_dir"
                    log-success "Deleted."
                fi
            fi
        done
    fi
    
    log-success "Cleanup scan completed."
}

main "$@"

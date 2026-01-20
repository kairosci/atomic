#!/usr/bin/env zsh
# Deep Clean User Home
# Removes configuration, cache, and data files to reset the environment

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Lists copied/adapted from config/script/manage-system.sh
readonly -a KIONITE_CONFIG_DIRS=(
    ".config/kdeconnect" ".config/kdeconnectrc" ".config/plasma-welcomerc"
    ".config/filelightrc" ".config/kdebugrc" ".config/khelpcenterrc"
    ".config/kcharselectrc" ".config/plasmaemojierrc" ".config/drkonqirc"
    ".config/krfbrc" ".config/discoverrc" ".config/kdeveloprc"
    ".config/kmail2rc" ".config/kmailsearchindexingrc" ".config/emaildefaults"
    ".config/emailidentities" ".config/khelpcenter" ".config/ksplashrc"
)

readonly -a KIONITE_SHARE_DIRS=(
    ".local/share/akonadi" ".local/share/akonadi_migration_agent"
    ".local/share/gravatar" ".local/share/kdevscratchpad"
    ".local/share/kdevelop" ".local/share/kmail2" ".local/share/local-mail"
    ".local/share/phishingurl" ".local/share/baloo" ".local/share/contacts"
    ".local/share/kactivitymanagerd" ".local/share/kded6" ".local/share/klipper"
    ".local/share/libkunitconversion" ".local/share/ksshaskpass"
    ".local/share/knewstuff3"
)

readonly -a SILVERBLUE_CONFIG_DIRS=(
    ".config/gnome-software" ".config/gnome-tour" ".config/gnome-contacts"
    ".config/gnome-weather" ".config/gnome-maps" ".config/totem"
    ".config/cheese" ".config/rhythmbox" ".config/yelp"
)

readonly -a SILVERBLUE_SHARE_DIRS=(
    ".local/share/gnome-software" ".local/share/gnome-maps"
    ".local/share/gnome-weather" ".local/share/totem"
    ".local/share/cheese" ".local/share/rhythmbox" ".local/share/yelp"
)

readonly -a COMMON_CONFIG_DIRS=(
    ".mozilla" ".config/ibus/typing-booster" ".config/toolboxrc"
)

readonly -a COMMON_SHARE_DIRS=(
    ".local/share/logs" ".local/share/user-places.xbel"
    ".local/share/user-places.xbel.bak" ".local/share/user-places.xbel.tbcache"
    ".local/share/recently-used.xbel" ".local/share/toolbox"
    ".local/share/waydroid" ".local/share/fonts/ubuntu"
)

# Additional cleanup for deep clean
readonly -a DEEP_CLEAN_DIRS=(
    ".cache/mozilla"
    ".cache/thumbnails"
    ".cache/pip"
    ".cache/yarn"
    ".cache/npm"
    ".local/state/wireplumber"
)

perform-cleanup() {
    local distro
    distro="$(detect-distro)"
    local user_home
    user_home="$(get-user-home)"

    log-title "Deep Cleaning $user_home ($distro)"

    local -a targets=()
    targets+=("${COMMON_CONFIG_DIRS[@]}" "${COMMON_SHARE_DIRS[@]}" "${DEEP_CLEAN_DIRS[@]}")
    
    case "$distro" in
        kionite)
            targets+=("${KIONITE_CONFIG_DIRS[@]}" "${KIONITE_SHARE_DIRS[@]}")
            ;;
        silverblue)
            targets+=("${SILVERBLUE_CONFIG_DIRS[@]}" "${SILVERBLUE_SHARE_DIRS[@]}")
            ;;
    esac

    # Add whole .cache if desired, but for now we look for specific targets inside it or just specific apps.
    # Actually, specific clean is safer, but "nice cleanup" implies catching junk. 
    # Let's offer to wipe ~/.cache entirely as a separate step.

    log-warn "The following items will be DELETED forever:"
    for item in "${targets[@]}"; do
        if [[ -e "$user_home/$item" ]]; then
            echo "  - $user_home/$item"
        fi
    done

    if confirm "Proceed with deletion?"; then
        for item in "${targets[@]}"; do
            if [[ -e "$user_home/$item" ]]; then
                rm -rf "$user_home/$item"
                echo "Deleted: $item"
            fi
        done
        log-success "Targeted files removed."
    fi

    echo ""
    if confirm "Do you also want to clear the ENTIRE ~/.cache folder? (Recommended for deep issues)"; then
         rm -rf "$user_home/.cache"/*
         log-success "Cache cleared."
    fi
}

main() {
    ensure-user
    perform-cleanup
}

main "$@"

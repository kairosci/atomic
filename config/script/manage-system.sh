#!/usr/bin/env zsh
# Manage System

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

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

readonly -a COSMIC_CONFIG_DIRS=(
    ".config/cosmic" ".config/cosmic-app-library" ".config/cosmic-comp"
    ".config/cosmic-greeter" ".config/cosmic-launcher" ".config/cosmic-osd"
    ".config/cosmic-panel" ".config/cosmic-session" ".config/cosmic-settings"
    ".config/cosmic-shortcut" ".config/cosmic-term" ".config/cosmic-workspaces"
)

readonly -a COSMIC_SHARE_DIRS=(
    ".local/share/cosmic"
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

system-cleanup() {
    log-info "System cleanup"
    journalctl --vacuum-files=0
    rpm-ostree cleanup --base --rollback -m
    log-success "System cleaned"
}

remove-user-configs() {
    local distro="$1"
    
    log-info "Removing user configs for $distro"
    
    local user_home
    user_home="$(get-user-home)"
    
    for dir in "${COMMON_CONFIG_DIRS[@]}" "${COMMON_SHARE_DIRS[@]}"; do
        rm -rf "$user_home/$dir"
    done
    
    case "$distro" in
        kionite)
            for dir in "${KIONITE_CONFIG_DIRS[@]}" "${KIONITE_SHARE_DIRS[@]}"; do
                rm -rf "$user_home/$dir"
            done
            ;;
        silverblue)
            for dir in "${SILVERBLUE_CONFIG_DIRS[@]}" "${SILVERBLUE_SHARE_DIRS[@]}"; do
                rm -rf "$user_home/$dir"
            done
            ;;
        cosmic)
            for dir in "${COSMIC_CONFIG_DIRS[@]}" "${COSMIC_SHARE_DIRS[@]}"; do
                rm -rf "$user_home/$dir"
            done
            ;;
    esac
    
    log-success "User configs removed"
}

system-upgrade() {
    log-info "Upgrading system"
    rpm-ostree reload
    rpm-ostree refresh-md
    rpm-ostree upgrade
    log-success "System upgraded"
}

flatpak-maintenance() {
    log-info "Flatpak maintenance"
    flatpak uninstall --unused --delete-data -y || true
    flatpak update -y
    log-success "Flatpak maintenance done"
}

main() {
    ensure-root
    local distro
    distro="$(detect-distro)"
    
    log-info "Detected distro: $distro"
    
    system-cleanup
    remove-user-configs "$distro"
    system-upgrade
    flatpak-maintenance
}

main "$@"

#!/usr/bin/bash
# Set Flatpak Apps

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly -a KIONITE_APPS_TO_REMOVE=(
    "org.kde.kmahjongg" "org.kde.kmines" "org.kde.kolourpaint"
    "org.kde.krdc" "org.kde.skanpage"
)

readonly -a SILVERBLUE_APPS_TO_REMOVE=(
    "org.gnome.Contacts" "org.gnome.Maps" "org.gnome.Weather"
    "org.gnome.Cheese" "org.gnome.Totem" "org.gnome.Rhythmbox3"
    "org.gnome.Characters" "org.gnome.SystemMonitor"
)

readonly -a COSMIC_APPS_TO_REMOVE=(
    "org.mozilla.firefox"
)

readonly -a COMMON_APPS_TO_REMOVE=(
    "org.fedoraproject.Platform.GL.default"
)

readonly -a APPS_TO_INSTALL=(
    "com.discordapp.Discord"
    "io.missioncenter.MissionCenter"
)

remove-defaults() {
    local distro="$1"
    
    log-info "Removing default Flatpak apps for $distro"
    
    local -a valid_apps=()
    local installed_apps
    installed_apps="$(flatpak list --app --columns=application 2>/dev/null || true)"
    
    for app in "${COMMON_APPS_TO_REMOVE[@]}"; do
        echo "$installed_apps" | grep -q "$app" && valid_apps+=("$app")
    done
    
    case "$distro" in
        kionite)
            for app in "${KIONITE_APPS_TO_REMOVE[@]}"; do
                if echo "$installed_apps" | grep -q "$app"; then
                    valid_apps+=("$app")
                else
                    log-info "Skipping $app (not installed)"
                fi
            done
            ;;
        silverblue)
            for app in "${SILVERBLUE_APPS_TO_REMOVE[@]}"; do
                if echo "$installed_apps" | grep -q "$app"; then
                    valid_apps+=("$app")
                else
                    log-info "Skipping $app (not installed)"
                fi
            done
            ;;
        cosmic)
            for app in "${COSMIC_APPS_TO_REMOVE[@]}"; do
                if echo "$installed_apps" | grep -q "$app"; then
                    valid_apps+=("$app")
                else
                    log-info "Skipping $app (not installed)"
                fi
            done
            ;;
    esac
    
    if [[ ${#valid_apps[@]} -gt 0 ]]; then
        flatpak uninstall --delete-data -y "${valid_apps[@]}"
        log-success "Default apps removed"
    else
        log-info "No default apps to remove"
    fi
}

setup-remotes() {
    log-info "Setting up Flatpak remotes"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    log-success "Remotes configured"
}

install-apps() {
    log-info "Installing Flatpak apps"
    
    if [[ ${#APPS_TO_INSTALL[@]} -gt 0 ]]; then
        flatpak install flathub "${APPS_TO_INSTALL[@]}" -y || true
        log-success "Apps installed"
    else
        log-info "No apps to install"
    fi
}

main() {
    ensure-root
    local distro
    distro="$(detect-distro)"
    
    log-info "Detected distro: $distro"
    
    remove-defaults "$distro"
    setup-remotes
    install-apps
}

main "$@"

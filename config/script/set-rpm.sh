#!/usr/bin/env zsh
# Set RPM Packages

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly -a COMMON_PACKAGES_TO_REMOVE=(
    "firefox" "firefox-langpacks"
)

readonly -a COMMON_PACKAGES_TO_INSTALL=(
    "libvirt" "tlp" "tlp-rdw" "qemu-kvm"
    "papirus-icon-theme" "zsh" "util-linux-user"
    "antigravity"
)

readonly -a KIONITE_PACKAGES_TO_REMOVE=(
    "${COMMON_PACKAGES_TO_REMOVE[@]}"
    "ibus-typing-booster"
    "kde-connect" "kde-connect-libs" "kdeconnectd"
    "kinfocenter" "plasma-drkonqi" "plasma-welcome" "plasma-welcome-fedora"
    "plasma-discover" "plasma-discover-rpm-ostree" "plasma-discover-flatpak"
    "plasma-discover-notifier" "plasma-discover-kns"
    "kcharselect" "kdebugsettings" "khelpcenter"
    "krfb" "krfb-libs" "kjournald" "kjournald-libs"
    "kwalletmanager5" "filelight"
)

readonly -a KIONITE_PACKAGES_TO_INSTALL=(
    "${COMMON_PACKAGES_TO_INSTALL[@]}"
    "kalk" "ksshaskpass" "rsms-inter-fonts"
)

readonly -a SILVERBLUE_PACKAGES_TO_REMOVE=(
    "${COMMON_PACKAGES_TO_REMOVE[@]}"
    "gnome-software" "gnome-software-rpm-ostree"
    "gnome-contacts" "gnome-maps" "gnome-weather" "gnome-tour"
    "gnome-connections" "gnome-characters" "gnome-font-viewer"
    "gnome-logs" "gnome-remote-desktop"
    "simple-scan" "totem" "cheese" "rhythmbox" "yelp"
)

readonly -a SILVERBLUE_PACKAGES_TO_INSTALL=(
    "${COMMON_PACKAGES_TO_INSTALL[@]}"
    "sassc" "gtk-murrine-engine"
)

readonly -a COSMIC_PACKAGES_TO_REMOVE=(
    "${COMMON_PACKAGES_TO_REMOVE[@]}"
)

readonly -a COSMIC_PACKAGES_TO_INSTALL=(
    "${COMMON_PACKAGES_TO_INSTALL[@]}"
)

remove-base-packages() {
    local distro="$1"
    local -n packages_ref="$2"
    
    log-info "Removing base packages for $distro"
    
    local -a valid_packages=()
    local ostree_status
    ostree_status="$(rpm-ostree status)"
    
    for pkg in "${packages_ref[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            if echo "$ostree_status" | grep -Fq "$pkg"; then
                log-info "Skipping $pkg (already has override)"
            else
                valid_packages+=("$pkg")
            fi
        else
            log-info "Skipping $pkg (not installed)"
        fi
    done
    
    if [[ ${#valid_packages[@]} -gt 0 ]]; then
        rpm-ostree override remove "${valid_packages[@]}"
        log-success "Base packages removed"
    else
        log-info "No base packages to remove"
    fi
}

install-third-party-repos() {
    log-info "Installing third-party repositories"
    
    if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
        log-info "Adding Brave repository"
        curl -fsS https://dl.brave.com/install.sh | sh
        log-success "Brave repository added"
    else
        log-info "Brave repository already exists"
    fi

    if [[ ! -f /etc/yum.repos.d/antigravity.repo ]]; then
        log-info "Adding Antigravity repository"
        cat << EOL > /etc/yum.repos.d/antigravity.repo
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOL
        log-success "Antigravity repository added"
    else
        log-info "Antigravity repository already exists"
    fi
}

install-packages() {
    local -n packages_ref="$1"
    
    log-info "Installing packages"
    
    if [[ ${#packages_ref[@]} -gt 0 ]]; then
        rpm-ostree install --idempotent --allow-inactive "${packages_ref[@]}"
        log-success "Packages installed"
    fi
}

main() {
    ensure-root
    local distro
    distro="$(detect-distro)"
    
    log-info "Detected distro: $distro"
    
    case "$distro" in
        kionite)
            remove-base-packages "Kionite" KIONITE_PACKAGES_TO_REMOVE
            install-third-party-repos
            install-packages KIONITE_PACKAGES_TO_INSTALL
            ;;
        silverblue)
            remove-base-packages "Silverblue" SILVERBLUE_PACKAGES_TO_REMOVE
            install-third-party-repos
            install-packages SILVERBLUE_PACKAGES_TO_INSTALL
            ;;
        cosmic)
            remove-base-packages "Cosmic" COSMIC_PACKAGES_TO_REMOVE
            install-third-party-repos
            install-packages COSMIC_PACKAGES_TO_INSTALL
            ;;
        *)
            log-error "Unknown distro: $distro"
            exit 1
            ;;
    esac
}

main "$@"

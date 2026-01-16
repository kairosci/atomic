#!/usr/bin/env zsh
# @file set-rpm.sh
# @brief Manages RPM packages via rpm-ostree
# @description
#   Removes base packages per distro and installs common packages
#   including third-party repositories.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly -a COMMON_PACKAGES_TO_REMOVE=(
    "firefox" "firefox-langpacks"
    "btop"
    "antigravity"
)

readonly -a COMMON_PACKAGES_TO_INSTALL=(
    "libvirt" "tlp" "tlp-rdw" "qemu-kvm"
    "papirus-icon-theme" "zsh" "util-linux-user"
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

# @description Removes base packages for a distro.
# @arg $1 string Distro name
# @arg $2 string Array reference name
remove-base-packages() {
    local distro="$1"
    local packages_ref="$2"
    local -a valid_packages=()
    local ostree_status

    log-info "Removing base packages for $distro"
    ostree_status="$(rpm-ostree status)"

    for pkg in "${(@P)packages_ref}"; do
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

# @description Installs third-party repositories.
install-third-party-repos() {
    log-info "Installing third-party repositories"

    if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
        log-info "Adding Brave repository"
        curl -fsS https://dl.brave.com/install.sh | sh
        log-success "Brave repository added"
    else
        log-info "Brave repository already exists"
    fi
}

# @description Installs packages via rpm-ostree.
# @arg $1 string Array reference name
install-packages() {
    local packages_ref="$1"

    log-info "Installing packages"

    if [[ ${#${(@P)packages_ref}} -gt 0 ]]; then
        rpm-ostree install --idempotent --allow-inactive "${(@P)packages_ref}"
        log-success "Packages installed"
    fi
}

# @description Main entry point.
main() {
    command-exists rpm-ostree || { log-warn "rpm-ostree not available, skipping"; return 0; }
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
            log-warn "Unknown distro: $distro, skipping RPM management"
            return 0
            ;;
    esac
}

main "$@"

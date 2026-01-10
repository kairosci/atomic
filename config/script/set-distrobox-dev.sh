#!/usr/bin/env zsh
# =============================================================================
# Set Distrobox Dev Container
# Creates a Fedora-based distrobox container for development
# Includes: Node.js, NPM, Build Tools, Zsh (with OMZ support via shared home)
# =============================================================================

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Constants
# =============================================================================

readonly CONTAINER_NAME="dev"
readonly CONTAINER_IMAGE="registry.fedoraproject.org/fedora:latest"
readonly PACKAGES="nodejs npm @development-tools zsh git curl wget"

# =============================================================================
# Main Functions
# =============================================================================

check-distrobox() {
    require-command distrobox "distrobox is required to create containers"
    require-command podman "podman is required for distrobox"
}

create-container() {
    log-info "Checking for existing '$CONTAINER_NAME' container..."
    
    if distrobox list | grep -q "$CONTAINER_NAME"; then
        log-warn "Container '$CONTAINER_NAME' already exists."
        read -r -p "Do you want to recreate it? [y/N] " response
        if [[ "$response" =~ ^[yY]$ ]]; then
            log-info "Stopping and removing existing container..."
            distrobox stop "$CONTAINER_NAME" -Y || true
            distrobox rm "$CONTAINER_NAME" -Y
        else
            log-info "Skipping creation."
            return 0
        fi
    fi

    log-info "Creating distrobox container '$CONTAINER_NAME'..."
    log-info "Image: $CONTAINER_IMAGE"
    log-info "Packages: $PACKAGES"

    # Create the container with packages pre-installed
    # We use --yes to avoid prompts
    distrobox create \
        --image "$CONTAINER_IMAGE" \
        --name "$CONTAINER_NAME" \
        --additional-packages "$PACKAGES" \
        --yes > /dev/null 2>&1

    log-success "Container '$CONTAINER_NAME' created successfully."
}

configure-omz-integration() {
    # Since Distrobox shares $HOME, existing OMZ config works if zsh is installed.
    # We just verified zsh is in the package list.
    # We can add a tip for the user.
    
    log-info "Note: This container shares your \$HOME, so your Host Oh-My-Zsh configuration should work automatically."
    log-info "To enter the container with Zsh, use: distrobox enter $CONTAINER_NAME"
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    log-title "Setting up '$CONTAINER_NAME' Distrobox Environment"
    
    check-distrobox
    create-container
    configure-omz-integration
    
    log-success "Setup complete!"
    echo -e "Enter the container with: ${BOLD}distrobox enter $CONTAINER_NAME${NC}"
}

main "$@"

#!/usr/bin/bash
# Fedora Atomic Common Library

set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"

# Colors and Formatting
readonly BOLD='\033[1m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'

# No Color
readonly NC='\033[0m'

detect-distro() {
    [[ -n "${FORCE_DISTRO:-}" ]] && return
    
    if grep -qi "Kinoite" /etc/os-release 2>/dev/null; then
        echo "kionite"
    elif grep -qi "Silverblue" /etc/os-release 2>/dev/null; then
        echo "silverblue"
    elif grep -qi "Cosmic" /etc/os-release 2>/dev/null; then
        echo "cosmic"
    else
        echo "unknown"
    fi
}

get-real-user() {
    echo "${SUDO_USER:-$USER}"
}

get-user-home() {
    getent passwd "$(get-real-user)" | cut -d: -f6
}

ensure-root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${YELLOW}Privilege escalation required for $SCRIPT_NAME...${NC}" >&2
        exec sudo "$0" "$@"
    fi
}

ensure-user() {
    if [[ "$EUID" -eq 0 ]] && [[ -z "${SUDO_USER:-}" ]]; then
        log-warn "Running as strict root. Some user-specific settings might not apply correctly."
    fi
}

log-info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log-warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log-error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log-success() { echo -e "${GREEN}[OK]${NC} $*"; }
log-title() { 
    echo -e "\n${BOLD}${BLUE}==== $* ====${NC}"
}

fix-ownership() {
    local path="$1"
    [[ -n "${SUDO_USER:-}" ]] && chown "$(get-real-user):$(get-real-user)" "$path"
}

fix-ownership-recursive() {
    local path="$1"
    [[ -n "${SUDO_USER:-}" ]] && chown -R "$(get-real-user):$(get-real-user)" "$path"
}

command-exists() {
    command -v "$1" &>/dev/null
}

require-command() {
    local cmd="$1"
    local msg="${2:-$cmd is required but not installed}"
    command-exists "$cmd" || { log-error "$msg"; exit 1; }
}

confirm() {
    local prompt="${1:-Are you sure?}"
    echo -ne "${YELLOW}$prompt [y/N] ${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log-info "Operation cancelled."
        return 1
    fi
    return 0
}

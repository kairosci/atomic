#!/usr/bin/env zsh
# Fedora Atomic Common Library

set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"

readonly BOLD='\033[1m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
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
        printf "${YELLOW}Privilege escalation required for %s...${NC}\n" "$SCRIPT_NAME" >&2
        local target_script="${SCRIPT_FILE:-${0:A}}"
        exec sudo "$target_script" "$@"
    fi
}

ensure-user() {
    if [[ "$EUID" -eq 0 ]] && [[ -z "${SUDO_USER:-}" ]]; then
        log-warn "Running as strict root. Some user-specific settings might not apply correctly."
    fi
}

log-info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log-warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2; }
log-error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
log-success() { printf "${GREEN}[OK]${NC} %s\n" "$*"; }
log-title() { 
    printf "\n${BOLD}${BLUE}**** %s ****${NC}\n" "$*"
}

fix-ownership() {
    local path="$1"
    [[ -n "${SUDO_USER:-}" ]] && /usr/bin/chown "$(get-real-user):$(get-real-user)" "$path"
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
    printf "${YELLOW}%s [y/N] ${NC}" "$prompt"
    read -r response
    if [[ ! "$response" =~ ^[yY]$ ]]; then
        log-info "Operation cancelled."
        return 1
    fi
    return 0
}

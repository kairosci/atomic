#!/usr/bin/env zsh
# @file common.sh
# @brief Fedora Atomic Common Library
# @description
#   Shared utilities for all Fedora Atomic scripts.
#   Provides logging, user detection, ownership management, and command validation.

set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"

readonly BOLD='\033[1m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# @description Detects the current Fedora Atomic variant.
# @stdout The distro name: kionite, silverblue, cosmic, or unknown
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

# @description Gets the real user when running under sudo.
# @stdout The actual username
get-real-user() {
    echo "${SUDO_USER:-$USER}"
}

# @description Gets the home directory of the real user.
# @stdout The home directory path
get-user-home() {
    getent passwd "$(get-real-user)" | cut -d: -f6
}

# @description Ensures the script runs with root privileges.
# @arg $@ string Arguments to pass to the re-executed script
ensure-root() {
    if [[ "$EUID" -ne 0 ]]; then
        printf "${YELLOW}Privilege escalation required for %s...${NC}\n" "$SCRIPT_NAME" >&2
        local target_script="${SCRIPT_FILE:-${0:A}}"
        exec sudo "$target_script" "$@"
    fi
}

# @description Warns if running as strict root without SUDO_USER context.
ensure-user() {
    if [[ "$EUID" -eq 0 ]] && [[ -z "${SUDO_USER:-}" ]]; then
        log-warn "Running as strict root. Some user-specific settings might not apply correctly."
    fi
}

# @description Logs an info message.
# @arg $* string Message to log
log-info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$*"
}

# @description Logs a warning message.
# @arg $* string Message to log
log-warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2
}

# @description Logs an error message.
# @arg $* string Message to log
log-error() {
    printf "${RED}[ERROR]${NC} %s\n" "$*" >&2
}

# @description Logs a success message.
# @arg $* string Message to log
log-success() {
    printf "${GREEN}[OK]${NC} %s\n" "$*"
}

# @description Logs a title/section header.
# @arg $* string Title text
log-title() {
    printf "\n${BOLD}${BLUE}**** %s ****${NC}\n" "$*"
}

# @description Fixes ownership of a path to the real user.
# @arg $1 string Path to fix
fix-ownership() {
    local path="$1"
    [[ -n "${SUDO_USER:-}" ]] && /usr/bin/chown "$(get-real-user):$(get-real-user)" "$path"
}

# @description Recursively fixes ownership of a path to the real user.
# @arg $1 string Path to fix
fix-ownership-recursive() {
    local path="$1"
    [[ -n "${SUDO_USER:-}" ]] && chown -R "$(get-real-user):$(get-real-user)" "$path"
}

# @description Checks if a command exists.
# @arg $1 string Command name
# @exitcode 0 Command exists
# @exitcode 1 Command not found
command-exists() {
    command -v "$1" &>/dev/null
}

# @description Requires a command to be available, exits if not found.
# @arg $1 string Command name
# @arg $2 string Optional error message
require-command() {
    local cmd="$1"
    local msg="${2:-$cmd is required but not installed}"
    command-exists "$cmd" || { log-error "$msg"; exit 1; }
}

# @description Prompts for user confirmation.
# @arg $1 string Optional prompt message
# @exitcode 0 User confirmed
# @exitcode 1 User declined
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

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

get-core-dir() {
    local script_dir="${SCRIPT_DIR:-${0:A:h}}"
    echo "$script_dir/core"
}

get-distro-dir() {
    local script_dir="${SCRIPT_DIR:-${0:A:h}}"
    echo "$script_dir/distro"
}

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

# @description Exits if not running on a supported Fedora Atomic system.
require-fedora-atomic() {
    local distro
    distro="$(detect-distro)"

    if [[ "$distro" == "unknown" ]]; then
        log-error "This script requires Fedora Atomic (Silverblue, Kinoite, or Cosmic)"
        log-error "Detected: unknown. Exiting."
        exit 1
    fi
}

log-info() {
  printf "${BLUE}[INFO]${NC} %s\n" "$*";
}

log-warn() {
  printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2;
}

log-error() {
  printf "${RED}[ERROR]${NC} %s\n" "$*" >&2;
}

log-success() {
  printf "${GREEN}[OK]${NC} %s\n" "$*";
}

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

# @description Global arrays for execution tracking
typeset -gA EXECUTION_RESULTS
typeset -ga EXECUTION_ORDER

# @description Clears execution tracking state.
clear-execution-tracking() {
    EXECUTION_RESULTS=()
    EXECUTION_ORDER=()
}

# @description Runs a script and tracks its execution status.
# @arg $1 string Script path
# @arg $2 string Optional display name
run-with-status() {
    local script="$1"
    local name="${2:-$(basename "$script")}"

    if [[ ! -f "$script" ]]; then
        EXECUTION_RESULTS["$name"]="NOT_FOUND"
        EXECUTION_ORDER+=("$name")
        log-warn "Script not found: $script"
        return 1
    fi

    log-info "Executing: $name"

    if "$script"; then
        EXECUTION_RESULTS["$name"]="SUCCESS"
    else
        EXECUTION_RESULTS["$name"]="FAILED"
    fi

    EXECUTION_ORDER+=("$name")
}

# @description Shows execution summary for all tracked scripts.
show-execution-summary() {
    if [[ ${#EXECUTION_ORDER[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    log-title "Execution Summary"

    local success_count=0
    local fail_count=0

    for name in "${EXECUTION_ORDER[@]}"; do
        local result="${EXECUTION_RESULTS[$name]:-UNKNOWN}"
        case "$result" in
            SUCCESS)
                printf "${GREEN}[PASS]${NC} %s\n" "$name"
                ((success_count++))
                ;;
            FAILED)
                printf "${RED}[FAIL]${NC} %s (exit code != 0)\n" "$name"
                ((fail_count++))
                ;;
            NOT_FOUND)
                printf "${YELLOW}[SKIP]${NC} %s (not found)\n" "$name"
                ;;
        esac
    done

    echo ""
    if [[ $success_count -eq 0 ]] && [[ $fail_count -eq 0 ]]; then
        log-info "No scripts were executed."
    elif [[ $fail_count -eq 0 ]]; then
        log-success "All $success_count script(s) completed successfully."
    else
        log-warn "$success_count passed, $fail_count failed."
    fi

    clear-execution-tracking
}

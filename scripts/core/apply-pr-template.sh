#!/usr/bin/env zsh
# @file apply-pr-template.sh
# @brief Applies PR template to all open pull requests
# @description
#   Fetches all open PRs and updates their body with the project template,
#   injecting title and commit information.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
readonly PROJECT_ROOT="${SCRIPT_DIR}/../../"
readonly TEMPLATE_FILE="${PROJECT_ROOT}/.github/pull_request_template.md"

# @description Validates that required commands are available.
check-dependencies() {
    for cmd in gh jq perl; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: '$cmd' is not installed."
            exit 1
        fi
    done
}

# @description Validates that the template file exists.
check-template() {
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        echo "Error: Template file not found at $TEMPLATE_FILE"
        exit 1
    fi
}

# @description Fetches open PRs and returns their numbers.
# @stdout PR numbers, one per line
get-open-prs() {
    gh pr list --state open --json number --jq '.[].number'
}

# @description Updates a single PR with the template.
# @arg $1 int PR number to update
update-pr() {
    local pr_number="$1"
    local pr_json title commits temp_body

    pr_json=$(gh pr view "$pr_number" --json title,commits)
    title=$(echo "$pr_json" | jq -r .title)
    commits=$(echo "$pr_json" | jq -r '.commits[].messageHeadline' | sed 's/^/- /')

    temp_body=$(mktemp)
    cp "$TEMPLATE_FILE" "$temp_body"

    export PR_TITLE="$title"
    export PR_COMMITS="$commits"

    perl -i -pe 's/<!-- Briefly describe the purpose of this PR. What problem does it solve\? -->/$ENV{PR_TITLE}/' "$temp_body"
    perl -i -0777 -pe 's/<!-- List the specific changes in bullet points -->\n-/$ENV{PR_COMMITS}/' "$temp_body"

    gh pr edit "$pr_number" --body-file "$temp_body"
    rm "$temp_body"

    echo "Updated PR #${pr_number} with context."
}

# @description Main entry point.
main() {
    check-dependencies
    check-template

    echo "Fetching open PRs..."
    local -a open_prs
    open_prs=("${(@f)$(get-open-prs)}")

    if [[ ${#open_prs[@]} -eq 0 ]]; then
        echo "No open PRs found."
        exit 0
    fi

    echo "Found ${#open_prs[@]} open PRs."

    for pr_number in "${open_prs[@]}"; do
        echo "Processing PR #${pr_number}..."
        update-pr "$pr_number"
    done

    echo "All PRs updated."
}

main "$@"

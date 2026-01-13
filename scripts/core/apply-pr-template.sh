#!/usr/bin/env zsh
# Apply PR Template to all open PRs with Context

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
readonly PROJECT_ROOT="${SCRIPT_DIR}/../../"
readonly TEMPLATE_FILE="${PROJECT_ROOT}/.github/pull_request_template.md"

# Check dependencies
for cmd in gh jq perl; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: '$cmd' is not installed."
        exit 1
    fi
done

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

echo "Fetching open PRs..."
# Get open PR numbers
open_prs=("${(@f)$(gh pr list --state open --json number --jq '.[].number')}")

if [[ ${#open_prs[@]} -eq 0 ]]; then
    echo "No open PRs found."
    exit 0
fi

echo "Found ${#open_prs[@]} open PRs."

for pr_number in "${open_prs[@]}"; do
    echo "Processing PR #${pr_number}..."

    # Fetch PR details
    pr_json=$(gh pr view "$pr_number" --json title,commits)
    title=$(echo "$pr_json" | jq -r .title)
    # Format commits as bullet points
    commits=$(echo "$pr_json" | jq -r '.commits[].messageHeadline' | sed 's/^/- /')

    # Create a temporary file for the new body
    temp_body=$(mktemp)
    cp "$TEMPLATE_FILE" "$temp_body"

    # Inject Context using Perl to avoid escaping issues with sed
    export PR_TITLE="$title"
    export PR_COMMITS="$commits"

    # Replace Summary placeholder
    perl -i -pe 's/<!-- Briefly describe the purpose of this PR. What problem does it solve\? -->/$ENV{PR_TITLE}/' "$temp_body"

    # Replace Key Changes placeholder (and the following hyphen)
    # We match the comment and the newline and the hyphen
    perl -i -0777 -pe 's/<!-- List the specific changes in bullet points -->\n-/$ENV{PR_COMMITS}/' "$temp_body"

    # Update the PR
    gh pr edit "$pr_number" --body-file "$temp_body"

    rm "$temp_body"
    echo "Updated PR #${pr_number} with context."
done

echo "All PRs updated."

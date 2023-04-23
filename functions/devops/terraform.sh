#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with Terraform
####################################################################################################

source "$(dirname "$(dirname "$0")")/shared.sh"
prevent_to_execute_directly

tfmt() {
    local top_level_git_repo_path
    top_level_git_repo_path=$(git rev-parse --show-toplevel)
    if [[ -z $top_level_git_repo_path ]]; then
        echo "${FUNCNAME[0]} Error: Not in a Git repository" >&2
        return 1
    fi

    terraform fmt "$top_level_git_repo_path" "${@:-.}"
}

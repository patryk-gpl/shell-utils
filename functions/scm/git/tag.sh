#!/usr/bin/env bash
# Functions to work with Git tag
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

# Helper functions
git_tag_create_and_push() {
    local tag=$1
    [ -z "$tag" ] && {
        echo "Syntax: git_tag_create_and_push <tag>"
        return 1
    }
    local remote
    remote=$(git remote)

    if git rev-parse --quiet --verify "refs/tags/$tag" >/dev/null; then
        echo "Local tag '$tag' already exists. Overwriting it."
        git tag -f "$tag"
    else
        echo "Creating local tag '$tag'."
        git tag "$tag"
    fi

    if git ls-remote --tags "$remote" "refs/tags/$tag" | grep -q "$tag"; then
        echo "Remote tag '$tag' already exists. Overwriting it."
        git push --force "$remote" "$tag"
    else
        echo "Pushing local tag '$tag' to remote '$remote'."
        git push "$remote" "$tag"
    fi
}

#!/usr/bin/env bash
# Functions to work with Git config
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

# shellcheck disable=SC2086
git_config_show_attribute() {
  local attribute="$1"
  if [[ -z "$attribute" ]]; then
    echo "config attribute is required."
    return 1
  fi

  local configs=("global" "local" "system")

  echo "== Checking attribute: $attribute =="
  for config in "${configs[@]}"; do
    echo -n "${config} Configuration: "
    if git config --${config} --get "$attribute" >/dev/null 2>&1; then
      git config --${config} --get "$attribute"
    else
      echo "Attribute not found."
    fi
  done
}

git_config_setup_dual_remote() {
  local private_repo="$1"

  if [ $# -ne 1 ]; then
    echo "Usage: git_config_setup_dual_remote <private_repo_url>"
    echo "This function sets up a dual-remote configuration for a git repository,"
    echo "allowing you to manage a private repository alongside your main one."
    echo "All branches will be pushed to the private repo, while only non-'priv/' branches"
    echo "will be pushed to the main repo."
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not in a git repository."
    echo "Please navigate to your main repository directory and try again."
    return 1
  fi

  local main_repo
  main_repo=$(git remote get-url origin 2>/dev/null) || true
  if [ "$main_repo" = "$private_repo" ]; then
    echo "Error: Main repository URL cannot be the same as the private repository URL."
    echo "Please provide a different private repository URL."
    return 1
  fi

  echo "Setting up dual-remote configuration..."

  echo "Checking 'origin' remote configuration..."
  if ! git remote | grep -q "^origin$"; then
    echo "➕ Adding 'origin' remote: $main_repo"
    git remote add origin "$main_repo"
  else
    local current_origin
    current_origin=$(git remote get-url origin)
    if [ "$current_origin" != "$main_repo" ]; then
      echo "❌ Error: Existing 'origin' remote ($current_origin) does not match the provided main repo URL ($main_repo)."
      echo "Please check your repository configuration and try again."
      return 1
    else
      echo "✅ 'origin' remote is correctly set to: $main_repo"
    fi
  fi

  echo "Configuring 'private' remote..."
  echo "➕ Adding/updating 'private' remote: $private_repo"
  git remote add private "$private_repo" 2>/dev/null || git remote set-url private "$private_repo"

  echo "⚙️  Configuring fetch settings..."
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git config remote.private.fetch "+refs/heads/*:refs/remotes/private/*"

  echo "⚙️  Configuring push behavior..."
  git config --unset-all remote.origin.push
  git config --unset-all remote.private.push

  echo "Configuring push for private remote (all branches)..."
  git config remote.private.push "refs/heads/*:refs/heads/*"

  echo "Configuring push for origin (non-priv/ branches only)..."
  git config remote.origin.push "refs/heads/*:refs/heads/*"
  git config --add remote.origin.push "^refs/heads/priv/*"

  echo "Setting up push to both remotes by default..."
  git config --unset-all push.default
  git config push.default current

  echo "🔗 Setting up tracking for existing branches..."
  git for-each-ref --format="%(refname:short)" refs/heads | while IFS= read -r branch; do
    echo "Setting up tracking for branch: $branch"
    git branch --set-upstream-to="private/$branch" "$branch"
    echo "  ✅ Set '$branch' to track 'private/$branch'"

    if [[ $branch != priv/* ]]; then
      git push -u origin "$branch"
      echo "  ✅ Pushed '$branch' to origin"
    fi
  done

  echo "🔄 Pushing all branches to private remote..."
  git push --all private

  echo "🔄 Fetching from both remotes..."
  git fetch --all

  printf "✅ Dual-remote setup complete. Current configuration:\n"
  git remote -v
  printf "\nBranch configuration:\n"
  git branch -vv

  cat <<EOF

📌 Important Notes:
   • All branches will be pushed to the private remote by default.
   • Only non-'priv/' branches will be pushed to the main (origin) remote.
   • To push all branches: git push --all
   • To push only to main repo: git push origin

🆕 Creating new branches:
   • For all new branches: git checkout -b <branch-name>
     Then push: git push -u

   Git will automatically push to both remotes (if applicable) and set up tracking.

🔄 Syncing with remotes: git fetch --all
📋 Listing all remote branches: git branch -a

Happy coding! 🚀
EOF
}

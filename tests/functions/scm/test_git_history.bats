#!/usr/bin/env bats

# shellcheck disable=SC2016 # Single-quoted scripts are intentionally evaluated by zsh.

repo_root=$(git rev-parse --show-toplevel)

load '../../test_helper/bats-support/load'
load '../../test_helper/bats-assert/load'

setup() {
  TEST_DIR=$(mktemp -d)
  TEST_REPO="$TEST_DIR/repo"
  git init -q "$TEST_REPO"
  git -C "$TEST_REPO" config user.name "Fake Author"
  git -C "$TEST_REPO" config user.email "fake.author@example.test"
  git -C "$TEST_REPO" remote add origin "https://example.com/repository.git"
  printf 'initial\n' >"$TEST_REPO/README.md"
  git -C "$TEST_REPO" add README.md
  git -C "$TEST_REPO" commit -qm "Initial commit"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "git_history_update_user_data updates a name when run from zsh" {
  run zsh -c '
    source "$1"
    cd "$2" || exit 1
    git_history_update_user_data --old-names "Fake Author" --new-name "Fake Renamed"
  ' _ "$repo_root/functions/scm/git/history.sh" "$TEST_REPO"

  assert_success
  refute_output --partial "bad option"
  refute_output --partial "SyntaxError"

  run git -C "$TEST_REPO" log -1 --format=%an
  assert_success
  assert_output "Fake Renamed"

  run git -C "$TEST_REPO" remote get-url origin
  assert_success
  assert_output "https://example.com/repository.git"
}

@test "git_history_update_user_data handles multiple names, emails, quotes, and Unicode" {
  git -C "$TEST_REPO" config user.name "Fake O'Author"
  git -C "$TEST_REPO" config user.email "fake.second@example.test"
  printf 'second\n' >>"$TEST_REPO/README.md"
  git -C "$TEST_REPO" add README.md
  git -C "$TEST_REPO" commit -qm "Second commit"

  git -C "$TEST_REPO" config user.name "Unchanged Author"
  git -C "$TEST_REPO" config user.email "unchanged@example.test"
  printf 'third\n' >>"$TEST_REPO/README.md"
  git -C "$TEST_REPO" add README.md
  git -C "$TEST_REPO" commit -qm "Third commit"

  run zsh -c '
    source "$1"
    cd "$2" || exit 1
    git_history_update_user_data \
      --old-names "Fake Author,Fake O'\''Author" \
      --new-name "Renamed ŁAuthor" \
      --old-emails "fake.author@example.test,fake.second@example.test" \
      --new-email "renamed@example.test"
  ' _ "$repo_root/functions/scm/git/history.sh" "$TEST_REPO"

  assert_success

  run git -C "$TEST_REPO" log --format='%an <%ae>'
  assert_success
  assert_output "Unchanged Author <unchanged@example.test>
Renamed ŁAuthor <renamed@example.test>
Renamed ŁAuthor <renamed@example.test>"
}

@test "git_history_update_user_data reports filter failures and restores origin" {
  mkdir "$TEST_DIR/bin"
  cat >"$TEST_DIR/bin/git" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "filter-repo" ]]; then
  exit 23
fi
exec "$REAL_GIT" "$@"
EOF
  chmod +x "$TEST_DIR/bin/git"

  run env REAL_GIT="$(command -v git)" PATH="$TEST_DIR/bin:$PATH" zsh -c '
    source "$1"
    cd "$2" || exit 1
    git_history_update_user_data --old-names "Fake Author" --new-name "Fake Renamed"
  ' _ "$repo_root/functions/scm/git/history.sh" "$TEST_REPO"

  assert_failure 23
  assert_output --partial "ERROR: git filter-repo failed"
  refute_output --partial "Git history has been updated"

  run git -C "$TEST_REPO" remote get-url origin
  assert_success
  assert_output "https://example.com/repository.git"
}

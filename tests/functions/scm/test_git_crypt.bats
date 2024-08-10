#!/usr/bin/env bats

repo_root=$(git rev-parse --show-toplevel)

load "$repo_root/functions/shared.sh"

load '../../test_helper/bats-support/load'
load '../../test_helper/bats-assert/load'

setup() {
    # Create a temporary directory for each test
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR" || exit 1

    source "$repo_root/functions/scm/git_crypt.sh"
}

teardown() {
    cd "$BATS_TEST_DIRNAME" || exit 1
    rm -rf "$TEST_DIR"
}

@test "git_crypt_enable shows help message with -h option" {
    run git_crypt_enable -h
    assert_success
    assert_output --partial "Usage: git_crypt_enable -r <path_to_repository>"
}

@test "git_crypt_enable fails without repository path" {
    run git_crypt_enable
    assert_failure
    assert_output --partial "Error: Repository path is required."
}

@test "git_crypt_enable initializes a new repository" {
    run git_crypt_enable -r new_repo
    assert_success
    assert_output --partial "The specified directory is not a git repository. Initializing..."
    assert_output --partial "Initialized git-crypt with a new key."
    assert [ -d new_repo/.git ]
    assert [ -f new_repo/.git/git-crypt/keys/default ]
}

@test "git_crypt_enable uses existing key" {
    # Create a dummy key file
    echo "dummy key" > existing_key

    run git_crypt_enable -r new_repo -k existing_key
    assert_success
    assert_output --partial "Initialized git-crypt with the provided key."
}

@test "git_crypt_enable adds custom paths to .gitattributes" {
    mkdir test_repo
    cd test_repo
    git init

    run git_crypt_enable -r . -p "*.txt,*.log"
    assert_success
    assert_output --partial "Added '*.txt' to .gitattributes for encryption."
    assert_output --partial "Added '*.log' to .gitattributes for encryption."

    run cat .gitattributes
    assert_output --partial "*.txt filter=git-crypt diff=git-crypt"
    assert_output --partial "*.log filter=git-crypt diff=git-crypt"
}

@test "git_crypt_enable uses default secrets directory" {
    run git_crypt_enable -r new_repo
    assert_success
    assert_output --partial "No custom paths specified. Using default 'secrets' directory."
    assert_output --partial "Added default 'secrets/**' to .gitattributes for encryption."
    assert [ -d new_repo/secrets ]
    assert [ -f new_repo/secrets/sample_secret.txt ]
}

@test "git_crypt_enable doesn't add duplicate entries to .gitattributes" {
    mkdir test_repo
    cd test_repo
    git init
    echo "*.txt filter=git-crypt diff=git-crypt" > .gitattributes

    run git_crypt_enable -r . -p "*.txt,*.log"
    assert_success
    assert_output --partial "'*.txt' is already in .gitattributes for encryption."
    assert_output --partial "Added '*.log' to .gitattributes for encryption."

    run cat .gitattributes
    assert_line --index 0 "*.txt filter=git-crypt diff=git-crypt"
    assert_line --index 1 "*.log filter=git-crypt diff=git-crypt"
}

@test "git_crypt_enable handles relative paths correctly" {
    mkdir -p some/nested/path
    run git_crypt_enable -r some/nested/path
    assert_success
    assert [ -d some/nested/path/.git ]
    assert [ -f some/nested/path/.git/git-crypt/keys/default ]
}

@test "git_crypt_enable fails with non-existent key file" {
    run git_crypt_enable -r new_repo -k non_existent_key
    assert_failure
    assert_output --partial "Error: The specified key file does not exist."
}

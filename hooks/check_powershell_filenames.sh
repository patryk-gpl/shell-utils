#!/usr/bin/env bash

set -euo pipefail

is_pascal_case() {
    [[ $1 =~ ^[A-Z][a-z0-9]+([A-Z][a-z0-9]+)*$ ]]
}

is_verb_noun() {
    [[ $1 =~ ^[A-Z][a-z]+-[A-Z][a-z]+\.ps1$ ]]
}

# List of approved PowerShell verbs
approved_verbs=(
    Add Approve Assert Backup Block Build Clear Close Compare Complete Compress Confirm Connect
    Convert ConvertFrom ConvertTo Copy Debug Deny Disable Disconnect Dismount Edit Enable Enter
    Exit Expand Export Find Format Get Grant Group Import Initialize Install Invoke Join Limit
    Lock Measure Merge Move New Open Optimize Out Ping Pop Protect Publish Push Read Receive Redo
    Register Remove Rename Repair Request Reset Resize Resolve Restart Restore Resume Revoke Save
    Search Select Send Set Show Skip Split Start Step Stop Submit Suspend Switch Sync Test Trace
    Unblock Undo Uninstall Unlock Unprotect Unpublish Unregister Update Use Wait Watch Write
)

is_approved_verb() {
    local verb=$1
    for approved_verb in "${approved_verbs[@]}"; do
        if [[ $verb == "$approved_verb" ]]; then
            return 0
        fi
    done
    return 1
}

# Check PowerShell module and function filenames
for file in "$@"; do
    dir=$(dirname "$file")
    filename=$(basename "$file")
    module=$(basename "$dir")

    # Check if the file is in the root directory
    if [ "$dir" = "." ]; then
        echo "Error: PowerShell file '$filename' is in the root directory. It should be in a module subdirectory."
        exit 1
    fi

    # Check if the module name is in PascalCase
    if ! is_pascal_case "$module"; then
        echo "Error: PowerShell module name is not in PascalCase: '$module' (File: $file)"
        exit 1
    fi

    # Check if the function filename is in Verb-Noun.ps1 format
    if ! is_verb_noun "$filename"; then
        echo "Error: PowerShell function filename is not in Verb-Noun.ps1 format: '$filename' (File: $file)"
        exit 1
    fi

    # Check if the verb is approved
    verb=${filename%%-*}
    if ! is_approved_verb "$verb"; then
        echo "Error: PowerShell function uses an unapproved verb: '$verb' (File: $file)"
        echo "Please use one of the approved verbs listed at: https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands"
        exit 1
    fi
done

exit 0

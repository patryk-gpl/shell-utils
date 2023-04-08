#!/bin/bash

# Upgrade all packages installed in Python virtualenv
function virtualenv_all_pkg_upgrade() {
    for pkg in $(pip list --outdated --format=freeze | awk -F"=" '/^[a-z]/ {print $1}')
    do
        pip install --upgrade "$pkg"
    done
}

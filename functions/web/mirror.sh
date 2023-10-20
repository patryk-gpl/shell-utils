#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with Web pages
####################################################################################################

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# Create a mirror of the web page locally
mirror_web_site() {
    if [ -z "$1" ]; then
        echo "Error: No URL provided. Please provide a URL as an argument."
        exit 1
    fi

    url=$1
    stripped_url="${url#*//}" # Remove protocol
    fqdn="${stripped_url%%/*}" # Remove context path
    url="https://$fqdn"

    logFile="download_${fqdn}.log"

    check_and_remove_empty_file() {
        local filename="$1"
        if [ -e "$filename" ]; then
            if [ -s "$filename" ]; then
                echo "File $filename is not empty."
            else
                rm "$filename"
            fi
        fi
    }

    show_stats() {
        local domain="$1"
        num_files=$(find "$domain" -type f -print | wc -l)
        num_dirs=$(find "$domain" -type d -print | wc -l)
        echo -e "Downloaded directories:\t$num_dirs"
        echo -e "Downloaded files:\t$num_files"
    }

    echo "Starting wget: $url"
    wget \
    --recursive \
    --level=1 \
    --convert-links \
    --timestamping \
    --page-requisites \
    --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3" \
    --tries 5 \
    --reject=avi,mp4,mov,flv,wmv,asf,mpg,mpeg \
    --show-progress \
    -q \
    -a "$logFile" \
    "$url"

    check_and_remove_empty_file "$logFile"
    show_stats "$fqdn"
}

#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: get_sjc_hosts.sh
# Author: Dmitry Troshenkov (troshenkov.d@gmail.com)
# Description:
#   This script retrieves host information from the LSF farm and updates an 
#   inventory file. Hosts are categorized into predefined groups based on their 
#   naming conventions, and their statuses are updated accordingly.
#
# Usage:
#   ./get_sjc_hosts.sh
#
# Configuration:
#   - INVENTORY: Path to the inventory file to be updated.
#
# Dependencies:
#   - bhosts: Command-line tool to fetch host information from the LSF farm.
#   - sed, awk, date: Standard Linux utilities used for text processing.
#
# Notes:
#   - Ensure the script has the necessary permissions to modify the inventory file.
#   - The script assumes the LSF farm is accessible and the `bhosts` command is 
#     available in the system's PATH.
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - No data loaded from the LSF farm
# ------------------------------------------------------------------------------

# Configuration
INVENTORY='hosts'

# Function to clean the inventory file
clean_inventory() {
    # Remove existing host entries
    sed -i -r "/^[a-z]{3}-[a-z]{2,3}-[0-9]{3,4}/d" "$INVENTORY"
    sed -i -r "/^[a-z]{3}-[a-z]{2}-master[0-9]/d" "$INVENTORY"

    # Update the date in the inventory file
    local date_pattern='[0-9]{2}/[0-9]{2}/[0-9]{2}?.[0-9]{2}:[0-9]{2}:[0-9]{2}?.[A-Z]{2}?.[A-Z]{3}'
    sed -i -r "s|$date_pattern|$(date +"%y/%m/%d&%I:%M:%S&%p&%Z")|g" "$INVENTORY"
}

# Function to add a host to the appropriate group
add_host_to_group() {
    local host="$1"
    local group="$2"
    sed -i -e "/\[$group\]/a"$'\\\n'"$host"$'\n' "$INVENTORY"
}

# Main script execution
main() {
    # Fetch hosts and their statuses from the LSF farm
    declare -a LSF_FARM=($(/auto/edatools/bin/bhosts --farm sjc-hw | grep -v HOST | awk '{ print $1 "&host_status=" $2 }'))

    # Exit if no data is loaded
    if [ ${#LSF_FARM[@]} -eq 0 ]; then
        echo "No data has been loaded."
        exit 2
    fi

    # Clean the inventory file
    clean_inventory

    # Add hosts to their respective groups
    for host_entry in "${LSF_FARM[@]}"; do
        if [[ $host_entry =~ ^sjc-hw-master[0-9]{1} ]]; then
            add_host_to_group "$host_entry" "sjc-hw-masters"
        elif [[ $host_entry =~ ^dsw-lnx-[0-9]{3,4} ]]; then
            add_host_to_group "$host_entry" "dsw-lnx"
        elif [[ $host_entry =~ ^eag-lnx-[0-9]{3,4} ]]; then
            add_host_to_group "$host_entry" "eag-lnx"
        elif [[ $host_entry =~ ^rtg-lnx-[0-9]{3,4} ]]; then
            add_host_to_group "$host_entry" "rtg-lnx"
        elif [[ $host_entry =~ ^rtp-hw-[0-9]{3,4} ]]; then
            add_host_to_group "$host_entry" "rtp-hw"
        elif [[ $host_entry =~ ^rtp-lnx-[0-9]{3,4} ]]; then
            add_host_to_group "$host_entry" "rtp-lnx"
        elif [[ $host_entry =~ ^sjc-hw-[0-9]{3,4} ]]; then
            add_host_to_group "$host_entry" "sjc-hw"
        else
            echo "No matching group found for host: $host_entry"
        fi
    done

    # Remove the separator '&' from the inventory file
    sed -i "s/\&/ /g" "$INVENTORY"
}

# Execute the main function
main

exit 0

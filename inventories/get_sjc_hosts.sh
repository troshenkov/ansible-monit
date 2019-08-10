#!/bin/bash
#
# Dmitry Troshenkov (troshenkov.d@gmail.com)

INVENTORY='hosts'

# Add the hosts and a host status: ok, closed, unavail
declare -a LSF_FARM=($(/auto/edatools/bin/bhosts --farm sjc-hw|grep -v HOST \
                                   | awk '{ print $1 "&host_status=" $2 }'))

if [ ${#LSF_FARM[@]} -gt 0 ]; then
    # Clean an inventory file
    sed -i -r "/^[a-z]{3}-[a-z]{2,3}-[0-9]{3,4}/d" "$INVENTORY"
    sed -i -r "/^[a-z]{3}-[a-z]{2}-master[0-9]/d" "$INVENTORY"
    # Make a new date yy/mm/dd hh:mm:ss AM/PM ZZZ
    _DATA='[0-9]{2}/[0-9]{2}/[0-9]{2}?.[0-9]{2}:[0-9]{2}:[0-9]{2}?.[A-Z]{2}?.[A-Z]{3}'
    sed -i -r "s|"$_DATA"|$(date +"%y\/%m\/%d\&%I:%M:%S\&%p\&%Z")|g" "$INVENTORY"
  else
      echo "No data has been loaded."; exit 2
fi

# Add the new hosts in to inventory file
for ((n=0; n < ${#LSF_FARM[*]}; n++)) ; do
# [sjc-hw-masters]
    if   [[ ${LSF_FARM[$n]} =~ ^sjc-hw-master[0-9]{1} ]]; then
        sed -i -e "/\[sjc\-hw\-masters\]/a"$'\\\n'"${LSF_FARM[$n]}"$'\n' "$INVENTORY"
# [dsw-lnx]
    elif [[ ${LSF_FARM[$n]} =~ ^dsw-lnx-[0-9]{3,4} ]]; then
        sed -i -e "/\[dsw\-lnx\]/a"$'\\\n'"${LSF_FARM[$n]}"$'\n' "$INVENTORY"
# [eag-lnx]
    elif [[ ${LSF_FARM[$n]} =~ ^eag-lnx-[0-9]{3,4} ]]; then
        sed -i -e "/\[eag\-lnx\]/a"$'\\\n'"${LSF_FARM[$n]}"$'\n' "$INVENTORY"
# [rtg-lnx]
    elif [[ ${LSF_FARM[$n]} =~ ^rtg-lnx-[0-9]{3,4} ]]; then
        sed -i -e "/\[rtg\-lnx\]/a"$'\\\n'"${LSF_FARM[$n]}"$'\n' "$INVENTORY"
# [rtp-hw]
    elif [[ ${LSF_FARM[$n]} =~ ^rtp-hw-[0-9]{3,4} ]]; then
        sed -i -e "/\[rtp\-hw\]/a"$'\\\n'"${LSF_FARM[$n]}"$'\n' "$INVENTORY"
# [rtp-lnx]
    elif [[ ${LSF_FARM[$n]} =~ ^rtp-lnx-[0-9]{3,4} ]]; then
        sed -i -e "/\[rtp\-lnx\]/a"$'\\\n'"${LSF_FARM[$n]}"$'\n' "$INVENTORY"
# [sjc-hw]
    elif [[ ${LSF_FARM[$n]} =~ ^sjc-hw-[0-9]{3,4} ]]; then
        sed -i -e "/\[sjc\-hw\]/a"$'\\\n'"${LSF_FARM[$n]}"$'\n' "$INVENTORY"
    else
        echo "No matching for the hosts group found: " ${LSF_FARM[$n]}
    fi
done

# Remove the separator '&'
sed -i "s/\&/ /g" "$INVENTORY"

exit 0


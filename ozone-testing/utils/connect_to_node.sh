#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

username=$1
node_name=$2

if [[ $username == "" ]]
then
    echo "A username must be provided, exting..."
    exit 1
fi

# Node name will be validated when converted to hostname, 
# so no need for that here.

sshToNodeBasedOnName "$username" "$node_name"

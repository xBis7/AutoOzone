#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

dir_num=$1
msg=$2
node_name=$3

createDescriptionFileIfNeeded "$dir_num" "$node_name"

addLineToDescriptionFile "$dir_num" "$msg" "$node_name"

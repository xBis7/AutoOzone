#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

backup_dir_num=$1
node_name=$2

# This script assumes that ozone is already stopped.
replaceFilesWithBackup "$backup_dir_num" "$node_name"

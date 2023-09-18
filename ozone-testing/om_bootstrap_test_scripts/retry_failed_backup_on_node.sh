#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

backup_dir_num=$1
node_name=$2

# Delete backup dir
doAnsibleWithNodeName "$node_name" "shell" "rm -rf /hadoop/testBackup/backup_$backup_dir_num/data/"

doAnsibleWithNodeName "$node_name" "shell" "ls -lah /hadoop/testBackup/backup_$backup_dir_num"

# Copy files
doAnsibleWithNodeName "$node_name" "shell" "cd /hadoop/ozone; tar cf - . | (cd /hadoop/testBackup/backup_$backup_dir_num; tar xvf -)"

doAnsibleWithNodeName "$node_name" "shell" "ls -lah /hadoop/testBackup/backup_$backup_dir_num"

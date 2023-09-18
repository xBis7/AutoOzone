#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"
source "/data/AutoOzone/variables.sh"

backup_dir_num=$1
boostrap_backup_dir_num=$2

# Stop ozone
ansible-playbook -i "$INV_FILE" playbook/ozone_stop.yml

replaceFilesWithBootstrapBackup "$backup_dir_num" "$boostrap_backup_dir_num"

# Start ozone
ansible-playbook -i "$INV_FILE" playbook/ozone_start.yml

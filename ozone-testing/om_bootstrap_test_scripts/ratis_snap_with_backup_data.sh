#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

volume=$1
bucket=$2
NUM_KEYS=$3
NUM_KEYS_PER_SNAPSHOT=$4
NUM_SNAPSHOTS=$5
backup_dir_num=$6

./unsecure_ha_fresh_install.sh

./replace_data_with_backup.sh "$backup_dir_num"

./om_load_test_ha.sh "$volume" "$bucket" "$NUM_KEYS" "$NUM_KEYS_PER_SNAPSHOT" "$NUM_SNAPSHOTS"



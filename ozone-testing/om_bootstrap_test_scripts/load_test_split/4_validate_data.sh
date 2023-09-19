#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

dataValidation() {
  om_node_name=$1
  volume=$2
  bucket=$3
  NUM_KEYS=$4
  # There is pagination on snap diff, we can't get more than 1000 keys at a time.
  # NUM_KEYS_PER_SNAPSHOT can't be more than 1000,
  # otherwise we can't reliably check the number of keys on the result.
  NUM_KEYS_PER_SNAPSHOT=$5
  NUM_SNAPSHOTS=$6
  backup_dir_num=$7

  # Print ozone version, so that we can keep track of the SHA used for the test run.
  doAnsibleWithNodeName om1 shell "/hadoop/app/ozone/bin/ozone version"

  om_hostname=$(getHostnameFromNodeName "$om_node_name")

  leader_om=$(getOMBasedOnRole $om_hostname "leader")

  # Check if the provided om is leader. If not, transfer leadership to it.
  if [ "$leader_om" != "$om_hostname" ]; then
    transferOMLeadership $om_hostname
  fi

  leader_om=$(getOMBasedOnRole $om_hostname "leader")
  follower_om1=$(getOMBasedOnRole $om_hostname "follower1")
  follower_om2=$(getOMBasedOnRole $om_hostname "follower2")

  echo "leader: $leader_om"
  echo "follower1: $follower_om1"
  echo "follower2: $follower_om2"

  # Check snaps and their keys on stopped_follower
  # The snap diff includes the parent directories as well, we will ignore them.

  checkSnapsAndKeysOnLeaderOM $om_hostname $volume $bucket $NUM_KEYS_PER_SNAPSHOT $NUM_SNAPSHOTS

  doAnsible $om_hostname shell "cat /hadoop/app/ozone/logs/ozone-ozone-om-$om_hostname.log | grep 'download the latest snapshot'"

  # Revisit this, maybe backup to new separate dir. Keep separate dir set for this test.
  # Because this is run after checking the ratis snapshot, it has stored a number of tarballs on 'om2'.
  # Do we want to keep track of that as well? If yes, then create a separate dir set.
  # dataBackup
}

om_node_name=$1
volume=$2
bucket=$3
NUM_KEYS=$4
NUM_KEYS_PER_SNAPSHOT=$5
NUM_SNAPSHOTS=$6
backup_dir_num=$7
bootstrap_backup_dir_num=$8

term_out_file="term_out_after_data_validation_$om_node_name.txt"

dataValidation $om_node_name $volume $bucket "$NUM_KEYS" "$NUM_KEYS_PER_SNAPSHOT" "$NUM_SNAPSHOTS" 2>&1 | tee "$term_out_file"

copyTermOutToAllNodesAndClearFile "$term_out_file" "$backup_dir_num" "$bootstrap_backup_dir_num"

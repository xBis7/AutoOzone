#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

loadTest() {
  volume=$1
  bucket=$2
  NUM_KEYS=$3
  # There is pagination on snap diff, we can't get more than 1000 keys at a time.
  # NUM_KEYS_PER_SNAPSHOT can't be more than 1000, 
  # otherwise we can't reliably check the number of keys on the result.
  NUM_KEYS_PER_SNAPSHOT=$4
  NUM_SNAPSHOTS=$5

  # Print ozone version, so that we can keep track of the SHA used for the test run.
  doAnsibleWithNodeName om1 shell "/hadoop/app/ozone/bin/ozone version"

  om_hostname=$(getHostnameFromNodeName "om1")
  datanode1=$(getHostnameFromNodeName "dn1")
  datanode2=$(getHostnameFromNodeName "dn2")
  datanode3=$(getHostnameFromNodeName "dn3")

  leader_om=$(getOMBasedOnRole $om_hostname "leader")

  leader_name=$(getNodeNameFromHostname $leader_om "om")
  echo "Current leader name: $leader_name"
  # Make sure that the leader is always, om1
  if [ $leader_name != "om1"  ]
  then
    # $om_hostname belongs to om1.
    transferOMLeadership $om_hostname
  fi

  leader_om=$(getOMBasedOnRole $om_hostname "leader")
  follower_om1=$(getOMBasedOnRole $om_hostname "follower1")
  follower_om2=$(getOMBasedOnRole $om_hostname "follower2")

  echo "leader: $leader_om"
  echo "follower1: $follower_om1"
  echo "follower2: $follower_om2"

  # Make sure that the stopped OM is always, om2
  # Check node name for follower1
  follower_name=$(getNodeNameFromHostname $follower_om1 "om")

  # Follower1 will be the stopped om.
  stopped_follower=$follower_om1

  # If follower1 isn't om2, then follower2 will be the stopped om.
  if [ $follower_name != "om2" ]
  then
    stopped_follower=$follower_om2
  fi

  # Stop the follower.
  stopOM $stopped_follower

  # If we are in a secure cluster, we can't delete OM's data, 
  # because the system will continue to recognise the OM but it will have 
  # no certificates stored under it and we won't be able to restart the OM.
  #
  # As long as the old data are still there, the OM doesn't need initialization.

  deleteOMData $stopped_follower "/hadoop/ozone/data/disk1"

  # Follower has no data and needs to be initialized.
  doAnsibleAsyncPoll $stopped_follower shell "/hadoop/app/ozone/bin/init_om.sh" 120 5

  startOM $stopped_follower

  checkRatisSnapshotIns $stopped_follower

  transferOMLeadership $stopped_follower

  # Check snaps and their keys on stopped_follower
  # The snap diff includes the parent directories as well, we will ignore them.

  # This function needs some improvements, checking more snap diffs, key values, etc.
  checkSnapsAndKeysOnLeaderOM $stopped_follower $volume $bucket $NUM_KEYS_PER_SNAPSHOT $NUM_SNAPSHOTS

  doAnsible $stopped_follower shell "cat /hadoop/app/ozone/logs/ozone-ozone-om-$stopped_follower.log | grep 'download the latest snapshot'"

  # Revisit this, maybe backup to new separate dir. Keep separate dir set for this test.
  # dataBackup
}

volume=$1
bucket=$2
NUM_KEYS=$3
NUM_KEYS_PER_SNAPSHOT=$4
NUM_SNAPSHOTS=$5

term_out_file="term_out_without_new_data.txt"

loadTest $volume $bucket "$NUM_KEYS" "$NUM_KEYS_PER_SNAPSHOT" "$NUM_SNAPSHOTS" 2>&1 | tee "$term_out_file"

copyTermOutToAllNodesAndClearFile "$term_out_file"

#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

testRatisSnap() {
  bootstrap_om_name=$1
  backup_dir_num=$2

  # Print ozone version, so that we can keep track of the SHA used for the test run.
  doAnsibleWithNodeName om1 shell "/hadoop/app/ozone/bin/ozone version"

  om_hostname=$(getHostnameFromNodeName "om1")

  date

  # Get current leader hostname.
  leader_om=$(getOMBasedOnRole $om_hostname "leader")

  date

  # Get leader name from hostname.
  leader_name=$(getNodeNameFromHostname $leader_om "om")
  echo "Current leader name: $leader_name"

  # Compare current leader name with the bootstrap OM name.
  # Make sure that the leader OM is different than the one to be used for bootstrap.
  if [ $leader_name == $bootstrap_om_name  ]
  then
    # Get the first follower.
    follower_om=$(getOMBasedOnRole $om_hostname "follower")
    transferOMLeadership $follower_om
  fi

  date

  stopped_follower=$(getHostnameFromNodeName "$bootstrap_om_name")

  # Stop the follower.
  stopOM $stopped_follower

  date

  # If we are in a secure cluster, we can't delete OM's data, 
  # because the system will continue to recognise the OM but it will have 
  # no certificates stored under it and we won't be able to restart the OM.
  #
  # As long as the old data are still there, the OM doesn't need initialization.

  deleteOMData $stopped_follower "/hadoop/ozone/data/disk1"

  date

  # Follower has no data and needs to be initialized.
  doAnsibleAsyncPoll $stopped_follower shell "/hadoop/app/ozone/bin/init_om.sh" 120 5

  date

  startOM $stopped_follower

  date

  checkRatisSnapshotIns $stopped_follower

  date

  bootstrappedOmDataBackup $backup_dir_num > backup_out_tmp.txt

  date
}

bootstrap_om_name=$1
backup_dir_num=$2

term_out_file="term_out_ratis_snap_installation.txt"

testRatisSnap "$bootstrap_om_name" "$backup_dir_num" 2>&1 | tee "$term_out_file"

copyTermOutToAllNodesAndClearFile "$term_out_file" "$backup_dir_num"

date

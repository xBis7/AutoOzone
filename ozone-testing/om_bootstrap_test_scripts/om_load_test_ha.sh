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

  # Data init.
  # If volume and bucket don't exist, freon creates them.
  # Create them to specify bucket layout.
  #createVolBucketKeys $leader_om $volume $bucket "OBJECT_STORE" $NUM_KEYS


  # We need NUM_KEYS to become an odd number in order 
  # to able to divide it evenly in 3 pieces.
  while [[  $(expr $NUM_KEYS % 3) != 0 ]]
  do
    echo "NUM_KEYS=$NUM_KEYS isn't an odd num, decr..."
    NUM_KEYS=$(($NUM_KEYS-1))
  done

  keys_per_client=$(($NUM_KEYS/3))

  doAnsibleFreonKeyCreation $datanode1 $datanode2 $datanode3 "omkg" $volume $bucket "init" "$((1 + $RANDOM % 100))" "$keys_per_client" 1000

  echo "Successful key creation"

  # while [[  $(expr $NUM_KEYS_PER_SNAPSHOT % 3) != 0 ]]
  # do
  # 	echo "NUM_KEYS_PER_SNAPSHOT=$NUM_KEYS_PER_SNAPSHOT isn't an odd num, decr..."
  # 	NUM_KEYS_PER_SNAPSHOT=$(($NUM_KEYS_PER_SNAPSHOT-1))
  # done

  # snap_keys_per_client=$(($NUM_KEYS_PER_SNAPSHOT/3))

  # clear the file
  > ./snaps.txt

  #snap_inc=$((1 + $RANDOM % 10))
  counter=0

  keys_snaps_start_time=$(date +%s)
  
  while [ $counter -lt $NUM_SNAPSHOTS ]
  do
    # Create a user-provided number keys and take a snapshot.
    # Repeat until NUM_SNAPSHOTS is reached.
  #  	doAnsibleFreonKeyCreation $datanode1 $datanode2 $datanode3 "omkg" $volume $bucket "sn$snap_inc" "$((1 + $RANDOM % 100))" "$snap_keys_per_client" 1000 "$key_size" ""

    # threads=$(($NUM_KEYS_PER_SNAPSHOT/2))
    # doAnsibleFreonKeyCreationOneNode $datanode1 "ockg" $volume $bucket "sn$counter" "$((1 + $RANDOM % 100))" "$NUM_KEYS_PER_SNAPSHOT" $threads "$key_size" ""

    # 0 || (100, 200, 300, ..., 900) || (101, 201, 301, ..., 901)
    if [[ $counter == 0 || $(expr $counter % 100) == 0 || $(expr $counter % 100) == 1 ]]
    then
      manualKeyWriting "$leader_om" "$volume" "$bucket" "sn$counter" 10
    else 
      doAnsibleFreonKeyCreationOneNode $datanode1 "omkg" $volume $bucket "sn$counter" "$NUM_KEYS_PER_SNAPSHOT" 5 "" ""
    fi

    doAnsible $leader_om shell "/hadoop/app/ozone/bin/ozone sh snapshot create /$volume/$bucket snap-$counter"
      
    # Write snap names to file.
    echo "snap-$counter" >> ./snaps.txt

    # Prefix number and snapshot number
  #snap_inc=$(($snap_inc+1))

    echo "Finished iteration '$counter'."
    # Current snapshot counter
    counter=$(($counter+1))
  done

  keys_snaps_end_time=$(date +%s)
  echo "Successful key and snapshot creation. Elapsed time: $(($keys_snaps_end_time - $keys_snaps_start_time)) seconds"

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

  dataBackup
}

volume=$1
bucket=$2
NUM_KEYS=$3
NUM_KEYS_PER_SNAPSHOT=$4
NUM_SNAPSHOTS=$5

term_out_file="term_out.txt"

loadTest $volume $bucket "$NUM_KEYS" "$NUM_KEYS_PER_SNAPSHOT" "$NUM_SNAPSHOTS" 2>&1 | tee "$term_out_file"

copyTermOutToAllNodesAndClearFile "$term_out_file"

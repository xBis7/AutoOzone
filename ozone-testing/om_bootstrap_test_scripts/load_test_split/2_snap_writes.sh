#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

volume=$1
bucket=$2
NUM_KEYS_PER_SNAPSHOT=$3
NUM_SNAPSHOTS=$4
counter=$5

# Print ozone version, so that we can keep track of the SHA used for the test run.
doAnsibleWithNodeName om1 shell "/hadoop/app/ozone/bin/ozone version"

om_hostname=$(getHostnameFromNodeName "om1")
datanode1=$(getHostnameFromNodeName "dn1")
datanode2=$(getHostnameFromNodeName "dn2")
datanode3=$(getHostnameFromNodeName "dn3")

leader_om=$(getOMBasedOnRole $om_hostname "leader")
follower_om1=$(getOMBasedOnRole $om_hostname "follower1")
follower_om2=$(getOMBasedOnRole $om_hostname "follower2")

echo "leader: $leader_om"
echo "follower1: $follower_om1"
echo "follower2: $follower_om2"

if [[ $counter == 0 ]]; then
  # clear the file
  >./snaps.txt
fi

keys_snaps_start_time=$(date +%s)

while [ $counter -lt $NUM_SNAPSHOTS ]; do
  # Create a user-provided number keys and take a snapshot.
  # Repeat until NUM_SNAPSHOTS is reached.
  #  	doAnsibleFreonKeyCreation $datanode1 $datanode2 $datanode3 "omkg" $volume $bucket "sn$snap_inc" "$((1 + $RANDOM % 100))" "$snap_keys_per_client" 1000 "$key_size" ""

  # threads=$(($NUM_KEYS_PER_SNAPSHOT/2))
  # doAnsibleFreonKeyCreationOneNode $datanode1 "ockg" $volume $bucket "sn$counter" "$((1 + $RANDOM % 100))" "$NUM_KEYS_PER_SNAPSHOT" $threads "$key_size" ""

  # 0 || (100, 200, 300, ..., 900) || (101, 201, 301, ..., 901)
  if [[ $counter == 0 || $(expr $counter % 100) == 0 || $(expr $counter % 100) == 1 ]]; then
    manualKeyWriting "$leader_om" "$volume" "$bucket" "sn$counter" 10
  else
    doAnsibleFreonKeyCreationOneNode $datanode1 "omkg" $volume $bucket "sn$counter" "$NUM_KEYS_PER_SNAPSHOT" 5 "" ""
  fi

  doAnsible $leader_om shell "/hadoop/app/ozone/bin/ozone sh snapshot create /$volume/$bucket snap-$counter"

  # Write snap names to file.
  echo "snap-$counter" >>./snaps.txt

  # Prefix number and snapshot number
  #snap_inc=$(($snap_inc+1))

  echo "Finished iteration '$counter'."
  # Current snapshot counter
  counter=$(($counter + 1))
done

keys_snaps_end_time=$(date +%s)
echo "Successful key and snapshot creation. Elapsed time: $(($keys_snaps_end_time - $keys_snaps_start_time)) seconds"

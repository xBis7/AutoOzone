#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

volume=$1
bucket=$2
NUM_KEYS=$3
ITERATION_NUM=$4
freon_cmd=$5
key_size=$6
buffer_size=$7
one_node=$8
# NUM_KEYS_PER_SNAPSHOT=$2
# NUM_SNAPSHOTS=$3

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

if [[ $one_node == "true" ]]
then
  i=0
  while [[ $i -lt $ITERATION_NUM ]]
  do
    doAnsibleFreonKeyCreationOneNode $datanode1 "$freon_cmd" $volume $bucket "sn$i" "$((1 + $RANDOM % 100))" "$NUM_KEYS" 1000 "$key_size" "$buffer_size"
    i=$(($i+1))
    echo "finished $i iteration"
  done
else
  while [[  $(expr $NUM_KEYS % 3) != 0 ]]
  do
    echo "NUM_KEYS=$NUM_KEYS isn't an odd num, decr..."
    NUM_KEYS=$(($NUM_KEYS-1))
  done

  keys_per_client=$(($NUM_KEYS/3))

  i=0
  while [[ $i -lt $ITERATION_NUM ]]
  do
    doAnsibleFreonKeyCreation $datanode1 $datanode2 $datanode3 "$freon_cmd" $volume $bucket "sn$i" "$((1 + $RANDOM % 100))" "$keys_per_client" 1000 "$key_size" "$buffer_size"
    i=$(($i+1))
    echo "finished $i iteration"
  done
fi


#!/bin/bash

om=$1
volume=$2
bucket=$3
NUM_KEYS_PER_SNAPSHOT=$4
NUM_SNAPSHOTS=$5

#om2=$(getHostnameFromNodeName "om2")

# checkRatisSnapshotIns $stopped_follower

# transferOMLeadership $stopped_follower

# Check snaps and their keys on stopped_follower
# The snap diff includes the parent directories as well, we will ignore them.

# This function needs some improvements, checking more snap diffs, key values, etc.
checkSnapsAndKeysOnLeaderOM $om $volume $bucket $NUM_KEYS_PER_SNAPSHOT $NUM_SNAPSHOTS

#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

dir=$1
init=$2

volume="vol1"
fso_bucket="fsob"
node_name="dn1"

echo "kinit"
kinitHostWithNodeName "$node_name"

if [[ $init == "true" ]]; then
  echo "Volume - bucket setup"
  doAnsibleWithNodeName $node_name "shell" "/hadoop/app/ozone/bin/ozone sh volume create /$volume"
  doAnsibleWithNodeName $node_name "shell" "/hadoop/app/ozone/bin/ozone sh bucket create /$volume/$fso_bucket -l FILE_SYSTEM_OPTIMIZED"
else
  echo "Skipping volume - bucket creation."
fi

echo "Creating keys for /$volume/$fso_bucket"
doAnsibleWithNodeName $node_name "shell" "/hadoop/app/ozone/bin/ozone sh key put /$volume/$fso_bucket/$dir/key1 /etc/hosts"
doAnsibleWithNodeName $node_name "shell" "/hadoop/app/ozone/bin/ozone sh key put /$volume/$fso_bucket/$dir/dir2/key2 /etc/hosts"
doAnsibleWithNodeName $node_name "shell" "/hadoop/app/ozone/bin/ozone sh key put /$volume/$fso_bucket/$dir/dir2/key3 /etc/hosts"
doAnsibleWithNodeName $node_name "shell" "/hadoop/app/ozone/bin/ozone sh key put /$volume/$fso_bucket/$dir/dir2/dir3/key4 /etc/hosts"
doAnsibleWithNodeName $node_name "shell" "/hadoop/app/ozone/bin/ozone sh key put /$volume/$fso_bucket/$dir/dir2/dir3/key5 /etc/hosts"

echo "Key structure looks like this"
echo "/$volume/$fso_bucket/$dir/key1"
echo "/$volume/$fso_bucket/$dir/dir2/key2"
echo "/$volume/$fso_bucket/$dir/dir2/key3"
echo "/$volume/$fso_bucket/$dir/dir2/dir3/key4"
echo "/$volume/$fso_bucket/$dir/dir2/dir3/key5"

echo "*** Directory rename ***"
echo ""

echo "Renaming $dir/ for FSO"
fso_dir_start_time=$(date +%s%N)
time doAnsibleWithNodeName $node_name "shell" "/hadoop/app/ozone/bin/ozone sh key rename /$volume/$fso_bucket $dir/ renamed$dir/"
fso_dir_end_time=$(date +%s%N)
echo "Finished rename for '/$volume/$fso_bucket/dir1/'. Elapsed time: $(($(($fso_dir_end_time-$fso_dir_start_time))/1000000)) ms"

echo "*** Key rename ***"
echo ""

echo "Renaming renamed$dir/dir2/dir3/key4 for FSO"
fso_key_start_time=$(date +%s%N)
time doAnsibleWithNodeName $node_name "shell" "/hadoop/app/ozone/bin/ozone sh key rename /$volume/$fso_bucket renamed$dir/dir2/dir3/key4 renamed$dir/dir2/dir3/renamedkey4"
fso_key_end_time=$(date +%s%N)
echo "Finished rename for '/$volume/$fso_bucket/renamed$dir/dir2/dir3/key4'. Elapsed time: $(($(($fso_key_end_time-$fso_key_start_time))/1000000)) ms"


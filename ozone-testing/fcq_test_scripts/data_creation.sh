#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

node_name=$1
oz_user=$2
threads=$3
keys=$4
key_prefix=$5

# Check if 'bucket1' exists.
bucket_res=$(doAnsibleWithNodeNameAsOzUser "om1" "oz1" shell "/hadoop/app/ozone/bin/ozone sh bucket info /s3v/bucket1")

if [[ $bucket_res == *"BUCKET_NOT_FOUND"* ]]
then
  doAnsibleWithNodeNameAsOzUser "om1" "oz1" shell "/hadoop/app/ozone/bin/ozone sh bucket create /s3v/bucket1"
fi

doAnsibleWithNodeNameAsOzUser "$node_name" "$oz_user" shell "/hadoop/app/ozone/bin/ozone freon omkg -t $threads -n $keys -b bucket1 -p $key_prefix"


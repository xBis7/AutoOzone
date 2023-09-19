#!/bin/bash

threads=$1
keys=$2
key_prefix=$3

# Check if 'bucket1' exists.
bucket_res=$(/hadoop/app/ozone/bin/ozone sh bucket info /s3v/bucket1)

if [[ $bucket_res == *"BUCKET_NOT_FOUND"* ]]
then
  /hadoop/app/ozone/bin/ozone sh bucket create /s3v/bucket1
fi

/hadoop/app/ozone/bin/ozone freon omkg -t $threads -n $keys -b bucket1 -p $key_prefix


#!/bin/bash

source "/data/AutoOzone/ozone-testing/fcq_test_scripts/variables.sh"
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

doAnsibleWithNodeNameAsOzUser "$node_name" "$oz_user" shell "export AWS_ACCESS_KEY=$oz_user AWS_SECRET_KEY=pass"

doAnsibleWithNodeNameAsOzUser "$node_name" "$oz_user" shell "/hadoop/app/ozone/bin/ozone freon s3kg -e http://$S3G1_HOSTNAME:9878 -t $threads -n $keys -b bucket1 -p $key_prefix"


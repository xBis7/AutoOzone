#!/bin/bash

source "/data/AutoOzone/ozone-testing/fcq_test_scripts/variables.sh"
source "/data/AutoOzone/ozone-testing/testlib.sh"

node_name=$1
oz_user=$2

# Check if 'bucket1' exists.
bucket_res=$(doAnsibleWithNodeNameAsOzUser "om1" "oz1" shell "/hadoop/app/ozone/bin/ozone sh bucket info /s3v/bucket1")

if [[ $bucket_res == *"BUCKET_NOT_FOUND"* ]]
then
    doAnsibleWithNodeNameAsOzUser "om1" "oz1" shell "/hadoop/app/ozone/bin/ozone sh bucket create /s3v/bucket1"
fi

doAnsibleWithNodeNameAsOzUser "$node_name" "$oz_user" shell "export AWS_ACCESS_KEY=$oz_user AWS_SECRET_KEY=pass"

for i in {0..99} 
do
    sleep 2
    doAnsibleWithNodeNameAsOzUser "$node_name" "$oz_user" shell "/hadoop/app/ozone/bin/ozone freon s3kg -e http://$S3G1_HOSTNAME:9878 -t 10 -n 1000 -b bucket1 -p s3high$i"
done


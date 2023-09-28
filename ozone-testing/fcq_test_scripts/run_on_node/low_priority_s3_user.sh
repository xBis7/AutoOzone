#!/bin/bash

source "/hadoop/fcq_scripts/variables.sh"

oz_user=$1

# Check if 'bucket1' exists.
/hadoop/app/ozone/bin/ozone sh bucket create /s3v/bucket1 || true

export AWS_ACCESS_KEY=$oz_user AWS_SECRET_KEY=pass

/hadoop/app/ozone/bin/ozone freon s3kg -e http://$S3G1_HOSTNAME:9878 -t 100 -n 1000000 -b bucket1 -p s3low


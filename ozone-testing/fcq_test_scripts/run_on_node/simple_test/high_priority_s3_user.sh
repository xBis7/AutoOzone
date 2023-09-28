#!/bin/bash

source "/hadoop/fcq_scripts/variables.sh"

/hadoop/app/ozone/bin/ozone sh bucket create /s3v/bucket1 || true

export AWS_ACCESS_KEY="high/oz1" AWS_SECRET_KEY=pass

for i in {0..99} 
do
  /hadoop/app/ozone/bin/ozone freon s3kg -e http://$S3G1_HOSTNAME:9878 -t 3 -n 10 -b bucket1
  sleep 60

  echo "Finished iteration '$i'"
done

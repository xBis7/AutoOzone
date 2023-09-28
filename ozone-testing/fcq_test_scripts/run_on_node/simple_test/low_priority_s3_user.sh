#!/bin/bash

source "/hadoop/fcq_scripts/variables.sh"

/hadoop/app/ozone/bin/ozone sh bucket create /s3v/bucket1 || true

export AWS_ACCESS_KEY="low/oz2" AWS_SECRET_KEY=pass

for i in {0..2} 
do
  /hadoop/app/ozone/bin/ozone freon s3kg -e http://$S3G1_HOSTNAME:9878 -t 3 -n 10 -b bucket1
  sleep 60
done

for i in {0..2} 
do
  /hadoop/app/ozone/bin/ozone freon s3kg -e http://$S3G1_HOSTNAME:9878 -t 10 -n 100 -b bucket1
  sleep 60
done

for i in {0..2} 
do
  /hadoop/app/ozone/bin/ozone freon s3kg -e http://$S3G1_HOSTNAME:9878 -t 10 -n 1000 -b bucket1
  sleep 60
done

for i in {0..2} 
do
  /hadoop/app/ozone/bin/ozone freon s3kg -e http://$S3G1_HOSTNAME:9878 -t 10 -n 10000 -b bucket1
  sleep 60
done

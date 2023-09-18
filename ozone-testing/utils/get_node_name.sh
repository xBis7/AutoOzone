#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

hostname=$1
service=$2

getNodeNameFromHostname $hostname $service

#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

node_name=$1
module=$2
command=$3

doAnsibleWithNodeName "$node_name" "$module" "$command"

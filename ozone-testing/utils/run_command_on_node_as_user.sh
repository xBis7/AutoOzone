#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

node_name=$1
user=$2
module=$3
command=$4

doAnsibleWithNodeNameAsAnotherUser "$node_name" "$user" "$module" "$command"

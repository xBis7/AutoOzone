#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

node_name=$1
oz_user=$2

doAnsibleWithNodeNameAsRoot "$node_name" copy "src=/data/AutoOzone/ozone-testing/fcq_test_scripts/run_on_node/ dest=/hadoop/fcq_scripts/ owner=$oz_user group=hadoop mode=0755"

#!/bin/bash

source "/data/AutoOzone/ozone-testing/testlib.sh"

echo "hi" >> "term_out.txt"

copyTermOutToAllNodesAndClearFile "term_out.txt" 3

doAnsibleWithNodeName om1 shell "ls -lah /hadoop/testBackup/backup_3/om_bootstrap_backup"

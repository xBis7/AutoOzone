#!/bin/bash

source "/data/AutoOzone/variables.sh"

ansible-playbook -i "$INV_FILE" playbook/ozone_stop.yml

ansible -i "$INV_FILE" all -m copy -a "src=/data/hadoop-common-3.3.6.jar dest=/hadoop/app/ozone/share/ozone/lib owner=tigadmin group=hadoop mode=0755"

ansible-playbook -i "$INV_FILE" playbook/ozone_start.yml

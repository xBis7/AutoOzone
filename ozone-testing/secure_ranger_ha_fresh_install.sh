#!/bin/bash

source "/data/AutoOzone/variables.sh"

ansible-playbook -i "$INV_FILE" playbook/ozone_stop.yml
ansible-playbook -i "$INV_FILE" playbook/ozone_reset_node.yml
ansible-playbook -i "$INV_FILE" playbook/install_ozone_secure_ranger_ha.yml

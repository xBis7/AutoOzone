#!/bin/bash

rm -rf /data/AutoOzone/ozone-testing/._*
rm -rf /data/AutoOzone/ozone-testing/om_bootstrap_test_scripts/._*
rm -rf /data/AutoOzone/ozone-testing/om_bootstrap_test_scripts/load_test_split/._*
rm -rf /data/AutoOzone/ozone-testing/om_bootstrap_test_scripts/memory_perf_checks/._*
rm -rf /data/AutoOzone/ozone-testing/utils/._*

# Make all scripts executable
sudo chmod u+x /data/AutoOzone/ozone-testing/*.sh
sudo chmod u+x /data/AutoOzone/ozone-testing/utils/*.sh
sudo chmod u+x /data/AutoOzone/ozone-testing/om_bootstrap_test_scripts/*.sh
sudo chmod u+x /data/AutoOzone/ozone-testing/om_bootstrap_test_scripts/load_test_split/*.sh
sudo chmod u+x /data/AutoOzone/ozone-testing/om_bootstrap_test_scripts/memory_perf_checks/*.sh

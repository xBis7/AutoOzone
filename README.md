# AutoOzone
This repo contains script to deploy a version of Apache Ozone on n servers.

Pre-requisite:
In order to work it need the following:
- The servers where ozone will be running need to be up and running
- The OS should be centos 7 or centos 8 (recommand centos 7 for the moment)
- User "centos" with full privilege need to exist on all the servers
- Possible to ssh with public/private ssh key on hte all the server for the "centos" account
- Network connectivity between all the servers
- Network connectivity betweens hte servers and the server running the ansible playbook
- The server where the ansible playbook (this git) will be started from need to have ansible installed

Before starting the installation:
- Modify the inv file by changing all the "setme" with the right value. This means set the name of the pem file for the centos user and write the FQDN for each type of servers. you can mention the same server in multiple type (OM/SCM/S3G/etc...)
- Put the centos pem file in the root directory of this repo or modify the inv file with the right location of hte pem file
- Modify the playbook/ozone/config/ozone-site.xml with the right configuration. Which mean at least replcate all the hostname with the right value. the config expect to have a FQDN

How to install and start your cluster:
There are 2 playbook to run: installbasic.yml and install_ozone.yum. 
Here there example assume that the git have been clone under: /data/teamcluster/autoozone
```bash
ansible-playbook -i inv /data/teamcluster/autoozone/playbook/installbasic.yml
```
```bash
ansible-playbook -i inv /data/teamcluster/autoozone/playbook/install_ozone.yml
```
For a secure and HA cluster used instead the following playbook:
```bash
ansible-playbook -i inv /data/teamcluster/autoozone/playbook/install_ozone_secure_ha.yml
```
If you want to stop your cluster:
```bash
ansible-playbook -i inv /data/teamcluster/autoozone/playbook/ozone_stop.yml
```
If you want to start your cluster:
```bash
ansible-playbook -i inv /data/teamcluster/autoozone/playbook/ozone_start.yml
```
If you want to update the ozone-site.xml file and restart the ozone cluster, update the file on your ansible server and then run this playbook:
```bash
ansible-playbook -i inv /data/teamcluster/autoozone/playbook/ozone_update_config_restart_all.yml
```
If you want to redeploy all the configwithout restarting any service use:
```bash
ansible-playbook -i inv /data/teamcluster/autoozone/playbook/ozone_update_config.yml
```

If you want to "reset" all the node which mean, delete all data, db and logs use the following playbook
```bash
ansible-playbook -i inv /data/teamcluster/autoozone/playbook/ozone_reset_node.yml
```
Keep in mind that before a reset you need to stop all the service with a playbook and after the reset you will need to init the OM/SCM. they are specific playbook for this
There are few other script/playbook to perform specific actions like restart specific servers type and not the all cluster.

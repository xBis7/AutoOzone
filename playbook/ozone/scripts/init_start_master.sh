#!/usr/bin/env bash
source /etc/profile
ozone scm --init
ozone --daemon start scm
ozone om --init
ozone --daemon start om
ozone --daemon start recon


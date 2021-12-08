#!/usr/bin/env bash
source /etc/profile
ozone --daemon start scm
ozone --daemon start om
ozone --daemon start recon


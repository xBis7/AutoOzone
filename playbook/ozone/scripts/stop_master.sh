#!/usr/bin/env bash
source /etc/profile
ozone --daemon stop scm
ozone --daemon stop om
ozone --daemon stop recon


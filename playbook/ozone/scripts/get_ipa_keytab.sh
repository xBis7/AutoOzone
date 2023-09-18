#!/usr/bin/env bash

source "/data/AutoOzone/variables.sh"

kinit -kt /etc/krb5.keytab
h=$(hostname)
ipa service-add "ozone/$h@$HOSTNAME_SUFFIX"

ipa-getkeytab -s $OM1_HOSTNAME -p "ozone/$h@$HOSTNAME_SUFFIX" -k /etc/security/keytabs/ozone.keytab
kdestroy
chown ozone:hadoop /etc/security/keytabs/ozone.keytab

#!/usr/bin/env bash

source "/hadoop/app/ozone/bin/variables.sh"

kinit -kt /etc/krb5.keytab
h=$(hostname)
ipa service-add "ozone/$h@$HOSTNAME_SUFFIX"

ipa-getkeytab -s $FREEIPA_HOSTNAME -p "ozone/$h@$HOSTNAME_SUFFIX" -k /etc/security/keytabs/ozone.keytab
kdestroy
chown ozone:hadoop /etc/security/keytabs/ozone.keytab

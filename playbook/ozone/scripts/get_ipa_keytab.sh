#!/usr/bin/env bash
kinit -kt /etc/krb5.keytab
h=$(hostname)
ipa service-add "ozone/$h@EU-WEST-1.COMPUTE.INTERNAL"

ipa-getkeytab -s ip-10-0-88-182.eu-west-1.compute.internal -p "ozone/$h@EU-WEST-1.COMPUTE.INTERNAL" -k /etc/security/keytabs/ozone.keytab
kdestroy
chown ozone:hadoop /etc/security/keytabs/ozone.keytab

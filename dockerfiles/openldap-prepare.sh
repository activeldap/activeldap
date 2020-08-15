#!/bin/bash

set -exu

retry() {
  local retry_limit=10
  local n_tries=0
  while ! "$@"; do
    n_tries=$[ n_tries + 1 ]
    if [ ${n_tries} -ge ${retry_limit} ]; then
      exit 1
    fi
    sleep 1
  done
}

retry \
  ldapmodify \
    -ZZ \
    -H ldap://openldap \
    -D cn=admin,dc=example,dc=org \
    -w admin \
    -f add-test-example-org-dc.ldif

retry \
  ldapmodify \
    -ZZ \
    -H ldap://openldap \
    -D cn=admin,cn=config \
    -w config \
    -f add-phonetic-attribute-options-to-slapd.ldif

retry \
  ldapmodify \
    -ZZ \
    -H ldap://openldap \
    -D cn=admin,cn=config \
    -w config \
    -f olc-access-readable-by-all.ldif

retry \
  ldapadd \
    -ZZ \
    -H ldap://openldap \
    -D cn=admin,cn=config \
    -w config \
    -f /etc/ldap/schema/dyngroup.ldif

retry \
  ldapmodify \
    -ZZ \
    -H ldap://openldap \
    -D cn=admin,cn=config \
    -w config \
    -f enable-dynamic-groups.ldif

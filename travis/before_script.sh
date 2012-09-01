#!/bin/sh

password="secret"
crypted_password=`slappasswd -s $password`
cat <<EOF | sudo ldapmodify -Y EXTERNAL -H ldapi:///
version: 1
dn: olcDatabase={1}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: ${crypted_password}
-
EOF

base="dc=`echo get slapd/domain | sudo debconf-communicate slapd | sed -e 's/^0 //' | sed -e 's/^\.//; s/\./,dc=/g'`"
cat <<EOF > test/config.yaml
test:
  host: 127.0.0.1
  base: dc=test,${base}
  bind_dn: cn=admin,${base}
  password: ${password}
EOF

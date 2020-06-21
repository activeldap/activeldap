FROM debian:10

RUN \
  echo "debconf debconf/frontend select Noninteractive" | \
    debconf-set-selections

RUN \
  echo 'APT::Install-Recommends "false";' > \
    /etc/apt/apt.conf.d/disable-install-recommends

RUN \
  apt update && \
  apt install -y -V \
    ldap-utils && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

RUN echo "TLS_REQCERT never" > /etc/ldap/ldap.conf

COPY test/add-phonetic-attribute-options-to-slapd.ldif /
COPY dockerfiles/add-test-example-org-dc.ldif /
COPY dockerfiles/olc-access-readable-by-all.ldif /
COPY dockerfiles/enable-dynamic-groups.ldif /
COPY dockerfiles/openldap-prepare.sh /

ENTRYPOINT ["/openldap-prepare.sh"]

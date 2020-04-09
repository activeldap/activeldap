ARG FROM
FROM ${FROM}

RUN \
  echo "debconf debconf/frontend select Noninteractive" | \
    debconf-set-selections

RUN \
  echo 'APT::Install-Recommends "false";' > \
    /etc/apt/apt.conf.d/disable-install-recommends

RUN \
  apt update && \
  apt install -y -V \
    libldap-dev \
    libsasl2-dev && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

RUN echo "TLS_REQCERT never" > /etc/ldap/ldap.conf

RUN mkdir -p /build
COPY dockerfiles/config.yaml /build/
COPY *.gemspec /build/
COPY Gemfile /build/

ARG GEMFILE
COPY ${GEMFILE} /build/

ENV BUNDLE_GEMFILE=${GEMFILE}
WORKDIR /build/
RUN mkdir -p lib/active_ldap
COPY lib/active_ldap/version.rb lib/active_ldap/
RUN bundle install

CMD \
  /source/test/run-test.rb \
    -v

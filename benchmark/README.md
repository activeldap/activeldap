# README

This document describes how to run benchmarks under
benchmark/ directory.

## Configure your LDAP server

You need a LDAP server to run benchmarks. This is dependes
on your environment.

In this document, we assume that you configure your LDAP
server by the following configuration:

* host: 127.0.0.1
* base DN: dc=bench,dc=local
* encryption: startTLS
* bind DN: cn=admin,dc=local
* password: secret

## Configure ActiveLdap to connect to your LDAP server

You need an ActiveLdap configuration in
benchmark/config.yaml to connect to your LDAP server. There
is a sample configuration in
benchmark/config.yaml.sample. It's good to start from it.

    % cp benchmark/config.yaml.sample benchmark/config.yaml
    % editor benchmark/config.yaml

The configuration uses the same format of ldap.yaml.

## Run benchmarks

You just run a bencmark script. It loads
benchmark/config.yaml and populate benchmark data automatically.

    % ruby benchmark/bench-backend.rb
	Populating...

	Rehearsal ---------------------------------------------------------------
	  1x: AL(LDAP)                0.220000   0.000000   0.220000 (  0.234775)
	  1x: AL(Net::LDAP)           0.280000   0.000000   0.280000 (  0.273048)
	  1x: AL(LDAP: No Obj)        0.000000   0.000000   0.000000 (  0.009217)
	  1x: AL(Net::LDAP: No Obj)   0.060000   0.000000   0.060000 (  0.056727)
	  1x: LDAP                    0.000000   0.000000   0.000000 (  0.003261)
	  1x: Net::LDAP               0.040000   0.000000   0.040000 (  0.029862)
	------------------------------------------------------ total: 0.600000sec

									  user     system      total        real
	  1x: AL(LDAP)                0.200000   0.000000   0.200000 (  0.195660)
	  1x: AL(Net::LDAP)           0.220000   0.000000   0.220000 (  0.213444)
	  1x: AL(LDAP: No Obj)        0.010000   0.000000   0.010000 (  0.009000)
	  1x: AL(Net::LDAP: No Obj)   0.030000   0.000000   0.030000 (  0.026847)
	  1x: LDAP                    0.000000   0.000000   0.000000 (  0.003377)
	  1x: Net::LDAP               0.020000   0.000000   0.020000 (  0.022662)

	Entries processed by Ruby/ActiveLdap + LDAP: 100
	Entries processed by Ruby/ActiveLdap + Net::LDAP: 100
	Entries processed by Ruby/ActiveLdap + LDAP: (without object creation): 100
	Entries processed by Ruby/ActiveLdap + Net::LDAP: (without object creation): 100
	Entries processed by Ruby/LDAP: 100
	Entries processed by Net::LDAP: 100

	Cleaning...

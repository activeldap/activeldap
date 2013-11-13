#!/bin/sh

set -e

sudo apt-get update -qq
sudo apt-get install -y ldap-utils slapd

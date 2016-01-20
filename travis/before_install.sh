#!/bin/sh

set -e

gem update bundler

sudo apt-get update -qq
sudo apt-get install -y ldap-utils slapd

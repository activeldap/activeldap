#!/usr/bin/ruby -w

class ALUser < ActiveLDAP::Base
 ldap_mapping :dnattr => 'uid', :prefix => 'ou=People', :classes => ['posixAccount']
end # -- ALUser


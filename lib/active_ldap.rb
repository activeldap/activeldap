#!/usr/bin/ruby
# = Ruby/ActiveLdap
#
# "Ruby/ActiveLdap" Copyright (C) 2004,2005 Will Drewry mailto:will@alum.bu.edu
#
# == Introduction
#
# Ruby/ActiveLdap is a novel way of interacting with LDAP.  Most interaction with
# LDAP is done using clunky LDIFs, web interfaces, or with painful APIs that
# required a thick reference manual nearby. Ruby/ActiveLdap aims to fix that.
# Inspired by ActiveRecord[http://activerecord.rubyonrails.org], Ruby/ActiveLdap provides an
# object oriented interface to LDAP entries.
#
# The target audience is system administrators and LDAP users everywhere that
# need quick, clean access to LDAP in Ruby.
#
# === What's LDAP?
#
# LDAP stands for "Lightweight Directory Access Protocol." Basically this means
# that it is the protocol used for accessing LDAP servers.  LDAP servers
# lightweight directories.  An LDAP server can contain anything from a simple
# digital phonebook to user accounts for computer systems.  More and more
# frequently, it is being used for the latter.  My examples in this text will
# assume some familiarity with using LDAP as a centralized authentication and
# authorization server for Unix systems. (Unfortunately, I've yet to try this
# against Microsoft's ActiveDirectory, despite what the name implies.)
#
# Further reading:
# * RFC1777[http://www.faqs.org/rfcs/rfc1777.html] - Lightweight Directory Access Protocol
# * OpenLDAP[http://www.openldap.org]
#
# === So why use Ruby/ActiveLdap?
#
# Well if you like to fumble around in the dark, dank innards of LDAP, you can
# quit reading now.  However, if you'd like a cleaner way to integrate LDAP in to
# your existing code, hopefully that's why you'll want to use Ruby/ActiveLdap.
#
# Using LDAP directly (even with the excellent Ruby/LDAP), leaves you bound to
# the world of the predefined LDAP API.  While this API is important for many
# reasons, having to extract code out of LDAP search blocks and create huge
# arrays of LDAP.mod entries make code harder to read, less intuitive, and just
# less fun to write.  Hopefully, Ruby/ActiveLdap will remedy all of these
# problems!
#
# == Getting Started
#
# Ruby/ActiveLdap does have some overhead when you get started.  You must not
# only install the package and all of it's requirements, but you must also make
# customizations that will let it work in your environment.
#
# === Requirements
#
# * Ruby[http://www.ruby-lang.org] 1.8.x
# * Ruby/LDAP[http://ruby-ldap.sourceforge.net]
# * (Optional) Ruby/LDAP+GSSAPI[http://caliban.org/files/redhat/RPMS/i386/ruby-ldap-0.8.2-4.i386.rpm]
# * An LDAP server compatible with Ruby/LDAP: OpenLDAP[http://www.openldap.org], etc
#   - Your LDAP server must allow root_dse queries to allow for schema queries
# * Examples also require: Ruby/Password[http://raa.ruby-lang.org/project/ruby-password/]
#
# === Installation
#
# Assuming all the requirements are installed, you can install by grabbing the latest tgz file from
# the download site[http://rubyforge.org/frs/?group_id=381].
#
# The following steps will get the Ruby/ActiveLdap installed in no time!
#
#   $ tar -xzvf ruby-activeldap-current.tgz
#   $ cd ruby-activeldap-VERSION
#
# Edit lib/active_ldap/configuration.rb replacing values to match what will work
# with your LDAP servers. Please note that those variables are required, but can
# be overridden in any program  as detailed later in this document. Also make
# sure that "ROOT" stays all upcase.
#
# Now run:
#
#   $ (as root) rake install
#
# Now as a quick test, you can run:
#
#   $ irb
#   irb> require 'active_ldap'
#   => true
#   irb> exit
#
# If the require returns false or an exception is raised, there has been a
# problem with the installation.  You may need to customize what setup.rb does on
# install.
#
#
# === Customizations
#
# Now that Ruby/ActiveLdap is installed and working, we still have a few more
# steps to make it useful for programming.
#
# Let's say that you are writing a Ruby program for managing user and group
# accounts in LDAP. I will use this as the running example throughout the
# document.
#
# You will want to make a directory called 'ldapadmin' wherever is convenient. Under this directory,
# you'll want to make sure you have a 'lib' directory.
#
#   $ cd ~
#   $ mkdir ldapadmin
#   $ cd ldapadmin
#   $ mkdir lib
#   $ cd lib
#
# The lib directory is where we'll be making customizations. You can, of course,
# make this changes somewhere in Ruby's default search path to make this
# accessible to every Ruby scripts. Enough of my babbling, I'm sure you'd like to
# know what we're going to put in lib/.
#
# We're going to put extension classes in there. What are extension classes you say . . .
#
#
# == Usage
#
# This section covers using Ruby/ActiveLdap from writing extension classes to
# writing applications that use them.
#
# Just to give a taste of what's to come, here is a quick example using irb:
#
#   irb> require 'active_ldap'
#
# Here's an extension class that maps to the LDAP Group objects:
#
#   irb> class Group < ActiveLdap::Base
#   irb* ldap_mapping
#   irb* end
#
# Here is the Group class in use:
#
#   irb> all_groups = Group.find(:all, '*').collect {|group| group.cn}
#   => ["root", "daemon", "bin", "sys", "adm", "tty", ..., "develop"]
#
#   irb> group = Group.find("develop")
#   => #<Group:0x..........>
#
#   irb> group.members.collect {|member| member.uid}
#   => ["drewry"]
#
#   irb> group.cn
#   => "develop"
#
#   irb> group.gid_number
#   => "1003"
#
# That's it! No let's get back in to it.
#
# === Extension Classes
#
# Extension classes are classes that are subclassed from ActiveLdap::Base.  They
# are used to represent objects in your LDAP server abstractly.
#
# ==== Why do I need them?
#
# Extension classes are what make Ruby/ActiveLdap "active"! They do all the
# background work to make easy-to-use objects by mapping the LDAP object's
# attributes on to a Ruby class.
#
#
# ==== Special Methods
#
# I will briefly talk about each of the methods you can use when defining an
# extension class.  In the above example, I only made one special method call
# inside the Group class. More than likely, you will want to more than that.
#
# ===== ldap_mapping
#
# ldap_mapping is the only required method to setup an extension class for use
# with Ruby/ActiveLdap. It must be called inside of a subclass as shown above.
#
# Below is a much more realistic Group class:
#
#   class Group < ActiveLdap::Base
#     ldap_mapping :dn_attribute => 'cn',
#                  :prefix => 'ou=Groups', :classes => ['top', 'posixGroup']
#                  :scope => :one
#   end
#
# As you can see, this method is used for defining how this class maps in to LDAP.  Let's say that
# my LDAP tree looks something like this:
#
#   * dc=dataspill,dc=org
#   |- ou=People,dc=dataspill,dc=org
#   |+ ou=Groups,dc=dataspill,dc=org
#     \
#      |- cn=develop,ou=Groups,dc=dataspill,dc=org
#      |- cn=root,ou=Groups,dc=dataspill,dc=org
#      |- ...
#
# Under ou=People I store user objects, and under ou=Groups, I store group
# objects.  What |ldap_mapping| has done is mapped the class in to the LDAP tree
# abstractly. With the given :dnattr and :prefix, it will only work for entries
# under ou=Groups,dc=dataspill,dc=org using the primary attribute 'cn' as the
# beginning of the distinguished name.
#
# Just for clarity, here's how the arguments map out:
#
#   cn=develop,ou=Groups,dc=dataspill,dc=org
#   ^^         ^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^
#  :dn_attribute |         |
#              :prefix     |
#                :base from configuration.rb
#
# :scope tells ActiveLdap to only search under ou=Groups, and not to look deeper
# for dnattr matches. (e.g. cn=develop,ou=DevGroups,ou=Groups,dc=dataspill,dc=org)
#
# Something's missing: :classes.  :classes is used to tell Ruby/ActiveLdap what
# the minimum requirement is when creating a new object. LDAP uses objectClasses
# to define what attributes a LDAP object may have. Ruby/ActiveLdap needs to know
# what classes are required when creating a new object.  Of course, you can leave
# that field out to default to ['top'] only.  Then you can let each application
# choose what objectClasses their objects should have by calling the method e.g.
# Group#add_class(*values).
#
# Note that is can be very important to define the default :classes value. Due to
# implementation choices with most LDAP servers, once an object is created, its
# structural objectclasses may not be removed (or replaced).  Setting a sane default
# may help avoid programmer error later.
#
# :classes isn't the only optional argument.  If :dn_attribute is left off,
# it defaults to underscored class name or 'cn'.  If :prefix is left off,
# it will default to 'ou=PLURALIZED_CLASSNAME'. In this
# case, it would be 'ou=Groups'.
#
# :classes should be an Array. :dn_attribute should be a String and so should
# :prefix.
#
#
# ===== belongs_to
#
# This method allows an extension class to make use of other extension classes
# tying objects together across the LDAP tree. Often, user objects will be
# members of, or belong_to, Group objects.
#
#   * dc=dataspill,dc=org
#   |+ ou=People,dc=dataspill,dc=org
#    \
#    |- uid=drewry,ou=People,dc=dataspill,dc=org
#   |- ou=Groups,dc=dataspill,dc=org
#
#
# In the above tree, one such example would be user 'drewry' who is a part of the
# group 'develop'. You can see this by looking at the 'memberUid' field of 'develop'.
#
#   irb> develop = Group.find('develop')
#   => ...
#   irb> develop.memberUid
#   => ['drewry', 'builder']
#
# If we look at the LDAP entry for 'drewry', we do not see any references to
# group 'develop'. In order to remedy that, we can use belongs_to
#
#   irb> class User < ActiveLdap::Base
#   irb*   ldap_mapping :dn_attribute => 'uid', :prefix => 'People', :classes => ['top','account']
#   irb*   belongs_to :groups, :class => 'Group', :many => 'memberUid', :foreign_key => 'uid'
#   irb* end
#
# Now, class User will have a method called 'groups' which will retrieve all
# Group objects that a user is in.
#
#   irb> me = User.find('drewry')
#   irb> me.groups
#   => [#<Group:0x000001 ...>, #<Group:0x000002 ...>, ...]
#   irb> me.groups.each { |group| p group.cn };nil
#   "cdrom"
#   "audio"
#   "develop"
#   => nil
#   (Note: nil is just there to make the output cleaner...)
#
# TIP: If you weren't sure what the distinguished name attribute was for Group,
# you could also do the following:
#
#   irb> me.groups.each { |group| p group.id };nil
#   "cdrom"
#   "audio"
#   "develop"
#   => nil
#
# Now let's talk about the arguments.  The first argument is the name of the
# method you wish to create. In this case, we created a method called groups
# using the symbol :groups. The next collection of arguments are actually a Hash
# (as with ldap_mapping). :class should be a string that has the name of a
# class you've already included. If you class is inside of a module, be sure to
# put the whole name, e.g. :class => "MyLdapModule::Group". :primary_key
# tells belongs_to what attribute Group objects have that match the
# :many. :many is the name of the local attribute whose value
# should be looked up in Group under the primary key. If :foreign_key is left
# off of the argument list, it is assumed to be the dn_attribute. With this in
# mind, the above definition could become:
#
#   irb> class User < ActiveLdap::Base
#   irb*   ldap_mapping :dnattr => 'uid', :prefix => 'People', :classes => ['top','account']
#   irb*   belongs_to :groups, :class => 'Group', :many => 'memberUid'
#   irb* end
#
# In addition, you can do simple membership tests by doing the following:
#
#   irb> me.groups.member? 'root'
#   => false
#   irb> me.groups.member? 'develop'
#   => true
#
# ===== has_many
#
# This method is the opposite of belongs_to. Instead of checking other objects in
# other parts of the LDAP tree to see if you belong to them, you have multiple
# objects from other trees listed in your object. To show this, we can just
# invert the example from above:
#
#   class Group < ActiveLdap::Base
#     ldap_mapping :dn_attribute => 'cn', :prefix => 'ou=Groups', :classes => ['top', 'posixGroup']
#     has_many :members, :class => "User", :wrap => "memberUid", :primary_key => 'uid'
#   end
#
# Now we can see that group develop has user 'drewry' as a member, and it can
# even return all responses in object form just like belongs_to methods.
#
#   irb> develop = Group.find('develop')
#   => ...
#   irb> develop.members
#   => [#<User:0x000001 ...>, #<User:...>]
#
#
# The arguments for has_many follow the exact same idea that belongs_to's
# arguments followed. :wrap's contents are used to search for matching
# :primary_key content.  If :primary_key is not specified, it defaults to the
# dn_attribute of the specified :class.
#
# === Using these new classes
#
# These new classes have many method calls. Many of them are automatically
# generated to provide access to the LDAP object's attributes. Other were defined
# during class creation by special methods like belongs_to. There are a few other
# methods that do not fall in to these categories.
#
#
# ==== .find
#
# .find is a class method that is accessible from any subclass of Base that has
# 'ldap_mapping' called. When called it returns the first match of the given
# class.
#
#   irb> Group.find('*').cn
#   => "root"
#
# In this simple example, Group.find took the search string of 'deve*' and
# searched for the first match in Group where the dnattr matched the query. This
# is the simplest example of .find.
#
#   irb> Group.find(:all, '*').collect {|group| group.cn}
#   => ["root", "daemon", "bin", "sys", "adm", "tty", ..., "develop"]
#
# Here .find(:all) returns all matches to the same query.  Both .find and
# .find(:all) also can take more expressive arguments:
#
#   irb> Group.find(:all, :attribute => 'gidNumber', :value => '1003').collect {|group| group.cn}
#   => ["develop"]
#
# So it is pretty clear what :attribute and :value do - they are used to query as
# :attribute=:value.
#
# If :attribute is unspecified, it defaults to the dn_attribute.
#
# It is also possible to override :attribute and :value by specifying :filter. This
# argument allows the direct specification of a LDAP filter to retrieve objects by.
#
# ==== .search
# .search is a class method that is accessible from any subclass of Base, and Base.
# It lets the user perform an arbitrary search against the current LDAP connection
# irrespetive of LDAP mapping data.  This is meant to be useful as a utility method
# to cover 80% of the cases where a user would want to use Base.connection directly.
#
#   irb> Base.search(:base => 'dc=example,dc=com', :filter => '(uid=roo*)',
#                    :scope => :sub, :attributes => ['uid', 'cn'])
#   =>  [["uid=root,ou=People,dc=dataspill,dc=org",{"cn"=>["root"], "uidNumber"=>["0"]}]
# You can specify the :filter, :base, :scope, and :attributes, but they all have defaults --
#  * :filter defaults to objectClass=* - usually this isn't what you want
#  * :base defaults to the base of the class this is executed from (as set in ldap_mapping)
#  * :scope defaults to :sub. Usually you won't need to change it
#  * :attributes defaults to [] and is the list of attributes you want back. Empty means all of them.
#
# ==== #valid?
#
# valid? is a method that verifies that all attributes that are required by the
# objects current objectClasses are populated.
#
# ==== #save
#
# save is a method that writes any changes to an object back to the LDAP server.
# It automatically handles the addition of new objects, and the modification of
# existing ones.
#
# ==== .exists?
#
# exists? is a simple method which returns true is the current object exists in
# LDAP, or false if it does not.
#
#  irb> User.exists?("dshadsadsa")
#  => false
#
#
# === ActiveLdap::Base
#
# ActiveLdap::Base has come up a number of times in the examples above.  Every
# time, it was being used as the super class for the wrapper objects. While this
# is it's main purpose, it also handles quite a bit more in the background.
#
# ==== What is it?
#
# ActiveLdap::Base is the heart of Ruby/ActiveLdap.  It does all the schema
# parsing for validation and attribute-to-method mangling as well as manage the
# connection to LDAP.
#
# ===== establish_connection
#
# Base.establish_connection takes many (optional) arguments and is used to
# connect to the LDAP server. Sometimes you will want to connect anonymously
# and other times over TLS with user credentials. Base.establish_connection is
# here to do all of that for you.
#
#
# By default, if you call any subclass of Base, such as Group, it will call
# Base.establish_connection() if these is no active LDAP connection. If your
# server allows anonymous binding, and you only want to access data in a
# read-only fashion, you won't need to call Base.establish_connection. Here
# is a fully parameterized call:
#
#   Base.establish_connection(
#     :host => 'ldap.dataspill.org',
#     :port => 389,
#     :base => 'dc=dataspill,dc=org',
#     :logger => logger_object,
#     :bind_dn => "uid=drewry,ou=People,dc=dataspill,dc=org",
#     :password_block => Proc.new { 'password12345' },
#     :allow_anonymous => false,
#     :try_sasl => false
#   )
#
# There are quite a few arguments, but luckily many of them have safe defaults:
# * :host defaults to @@host from configuration.rb waaay back at the setup.rb stage.@
# * :port defaults to @@port from configuration.rb as well
# * :base defaults to Base.base() from configuration.rb
# * :bind_dn defaults @@bind_format from configuration.rb
# * :logger defaults to a Log4r object that prints fatal messages to stderr
# * :password_block defaults to nil
# * :allow_anonymous defaults to true
# * :try_sasl defaults to false - see Advanced Topics for more on this one.
#
#
# Most of these are obvious, but I'll step through them for completeness:
# * :host defines the LDAP server hostname to connect to.
# * :port defines the LDAP server port to connect to.
# * :method defines the type of connection - :tls, :ssl, :plain
# * :base specifies the LDAP search base to use with the prefixes defined in all
#   subclasses.
# * :bind_dn specifies what your server expects when attempting to bind with
#   credentials.
# * :logger accepts a custom logger object to integrate with any other logging
#   your application uses.
# * :password_block, if defined, give the Proc block for acquiring the password
# * :password, if defined, give the user's password as a String
# * :store_password indicates whether the password should be stored, or if used
#   whether the :password_block should be called on each reconnect.
# * :allow_anonymous determines whether anonymous binding is allowed if other
#   bind methods fail
# * :try_sasl, when true, tells ActiveLdap to attempt a SASL-GSSAPI bind
# * :sasl_quiet, when true, tells the SASL libraries to not spew messages to STDOUT
# * :method indicates whether to use :ssl, :tls, or :plain
# * :retries - indicates the number of attempts to reconnect that will be undertaken when a stale connection occurs. -1 means infinite.
# * :retry_wait - seconds to wait before retrying a connection
# * :scope - dictates how to find objects. (Default: :one)
# * :timeout - time in seconds - defaults to disabled. This CAN interrupt search() requests. Be warned.
# * :retry_on_timeout - whether to reconnect when timeouts occur. Defaults to true
# See lib/configuration.rb for defaults for each option
#
# Base.establish_connection both connects and binds in one step. It follows
# roughly the following approach:
#
# * Connect to host:port using :method
#
# * If bind_dn and password_block/password, attempt to bind with credentials.
# * If that fails or no password_block and anonymous allowed, attempt to bind
#   anonymously.
# * If that fails, error out.
#
# On connect, the configuration options passed in are stored in an internal class variable
# @configuration which is used to cache the information without ditching the defaults passed in
# from configuration.rb
#
# ===== connection
#
# Base.connection returns the ActiveLdap::Connection object.
#
# === Exceptions
#
# There are a few custom exceptions used in Ruby/ActiveLdap. They are detailed below.
#
# ==== DeleteError
#
# This exception is raised when #delete fails. It will include LDAP error
# information that was passed up during the error.
#
# ==== SaveError
#
# This exception is raised when there is a problem in #save updating or creating
# an LDAP entry.  Often the error messages are cryptic. Looking at the server
# logs or doing an Ethereal[http://www.ethereal.com] dump of the connection will
# often provide better insight.
#
# ==== AuthenticationError
#
# This exception is raised during Base.establish_connection if no valid authentication methods
# succeeded.
#
# ==== ConnectionError
#
# This exception is raised during Base.establish_connection if no valid
# connection to the LDAP server could be created. Check you configuration.rb,
# Base.establish_connection arguments, and network connectivity! Also check
# your LDAP server logs to see if it ever saw the request.
#
# ==== ObjectClassError
#
# This exception is raised when an object class is used that is not defined
# in the schema.
#
# === Others
#
# Other exceptions may be raised by the Ruby/LDAP module, or by other subsystems.
# If you get one of these exceptions and think it should be wrapped, write me an
# email and let me know where it is and what you expected. For faster results,
# email a patch!
#
# === Putting it all together
#
# Now that all of the components of Ruby/ActiveLdap have been covered, it's time
# to put it all together! The rest of this section will show the steps to setup
# example user and group management scripts for use with the LDAP tree described
# above.
#
# All of the scripts here are in the package's examples/ directory.
#
# ==== Setting up lib/
#
# In ldapadmin/lib/ create the file user.rb:
#   cat <<EOF
#   class User < ActiveLdap::Base
#     ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People', :classes => ['top', 'account', 'posixAccount']
#     belongs_to :groups, :class => 'Group', :wrap => 'memberUid'
#   end
#   EOF
#
# In ldapadmin/lib/ create the file group.rb:
#   cat <<EOF
#   class Group < ActiveLdap::Base
#     ldap_mapping :classes => ['top', 'posixGroup'], :prefix => 'ou=Group'
#     has_many :members, :class => "User", :many => "memberUid"
#     has_many :primary_members, :class => 'User', :foreign_key => 'gidNumber', :primary_key => 'gidNumber'
#   end # Group
#   EOF
#
# Now, we can write some small scripts to do simple management tasks.
#
# ==== Creating LDAP entries
#
# Now let's create a really dumb script for adding users - ldapadmin/useradd:
#
#   #!/usr/bin/ruby -W0
#
#   require 'active_ldap'
#   require 'lib/user'
#   require 'lib/group'
#   require 'password'
#
#   argv, opts, options = ActiveLdap::Command.parse_options do |opts, options|
#     opts.banner += " USER_NAME CN UID"
#   end
#
#   if argv.size == 3
#     name, cn, uid = argv
#   else
#     $stderr.puts opts
#     exit 1
#   end
#
#   pwb = Proc.new do |user|
#     ActiveLdap::Command.read_password("[#{user}] Password: ")
#   end
#
#   ActiveLdap::Base.establish_connection(:password_block => pwb,
#                                         :allow_anonymous => false)
#
#   if User.exists?(name)
#     $stderr.puts("User #{name} already exists.")
#     exit 1
#   end
#
#   user = User.new(name)
#   user.add_class('shadowAccount')
#   user.cn = cn
#   user.uid_number = uid
#   user.gid_number = uid
#   user.home_directory = "/home/#{name}"
#   user.sn = "somesn"
#   unless user.save
#     puts "failed"
#     puts user.errors.full_messages
#     exit 1
#   end
#
# ==== Managing LDAP entries
#
# Now let's create another dumb script for modifying users - ldapadmin/usermod:
#
#   #!/usr/bin/ruby -W0
#
#   require 'active_ldap'
#   require 'lib/user'
#   require 'lib/group'
#
#   argv, opts, options = ActiveLdap::Command.parse_options do |opts, options|
#     opts.banner += " USER_NAME CN UID"
#   end
#
#   if argv.size == 3
#     name, cn, uid = argv
#   else
#     $stderr.puts opts
#     exit 1
#   end
#
#   pwb = Proc.new do |user|
#     ActiveLdap::Command.read_password("[#{user}] Password: ")
#   end
#
#   ActiveLdap::Base.establish_connection(:password_block => pwb,
#                                         :allow_anonymous => false)
#
#   unless User.exists?(name)
#     $stderr.puts("User #{name} doesn't exist.")
#     exit 1
#   end
#
#   user = User.find(name)
#   user.cn = cn
#   user.uid_number = uid
#   user.gid_number = uid
#   unless user.save
#     puts "failed"
#     puts user.errors.full_messages
#     exit 1
#   end
#
# ==== Removing LDAP entries
#
# And finally, a dumb script for removing user - ldapadmin/userdel:
#
#
#   #!/usr/bin/ruby -W0
#
#   require 'active_ldap'
#   require 'lib/user'
#   require 'lib/group'
#
#   argv, opts, options = ActiveLdap::Command.parse_options do |opts, options|
#     opts.banner += " USER_NAME"
#   end
#
#   if argv.size == 1
#     name = argv.shift
#   else
#     $stderr.puts opts
#     exit 1
#   end
#
#   pwb = Proc.new do |user|
#     ActiveLdap::Command.read_password("[#{user}] Password: ")
#   end
#
#   ActiveLdap::Base.establish_connection(:password_block => pwb,
#                                         :allow_anonymous => false)
#
#   unless User.exists?(name)
#     $stderr.puts("User #{name} doesn't exist.")
#     exit 1
#   end
#
#   User.destroy(name)
#
# === Advanced Topics
#
# Below are some situation tips and tricks to get the most out of Ruby/ActiveLdap.
#
#
# ==== Binary data and other subtypes
#
# Sometimes, you may want to store attributes with language specifiers, or
# perhaps in binary form.  This is (finally!) fully supported.  To do so,
# follow the examples below:
#
#   irb> user = User.new('drewry')
#   => ...
#   # This adds a cn entry in lang-en and whatever the server default is.
#   irb> user.cn = [ 'wad', {'lang-en' => ['wad', 'foo']} ]
#   => ...
#   irb> user.cn
#   => ["wad", {"lang-en-us" => ["wad", "Will Drewry"]}]
#   # Now let's add a binary X.509 certificate (assume objectClass is correct)
#   irb> user.user_certificate = File.read('example.der')
#   => ...
#   irb> user.save
#
# So that's a lot to take in. Here's what is going on. I just set the LDAP
# object's cn to "wad" and cn:lang-en-us to ["wad", "Will Drewry"].
# Anytime a LDAP subtype is required, you must encapsulate the data in a Hash.
#
# But wait a minute, I just read in a binary certificate without wrapping it up.
# So any binary attribute _that requires ;binary subtyping_ will automagically
# get wrapped in {'binary' => value} if you don't do it. This keeps your #writes
# from breaking, and my code from crying.  For correctness, I could have easily
# done the following:
#
#   irb>  user.user_certificate = {'binary' => File.read('example.der')}
#
# You should note that some binary data does not use the binary subtype all the time.
# One example is jpegPhoto. You can use it as jpegPhoto;binary or just as jpegPhoto.
# Since the schema dictates that it is a binary value, Ruby/ActiveLdap will write
# it as binary, but the subtype will not be automatically appended as above. The
# use of the subtype on attributes like jpegPhoto is ultimately decided by the
# LDAP site policy and not by any programmatic means.
#
# The only subtypes defined in LDAPv3 are lang-* and binary.  These can be nested
# though:
#
#  irb> user.cn = [{'lang-JP-jp' => {'binary' => 'somejp'}}]
#
# As I understand it, OpenLDAP does not support nested subtypes, but some
# documentation I've read suggests that Netscape's LDAP server does. I only
# have access to OpenLDAP. If anyone tests this out, please let me know how it
# goes!
#
#
# And that pretty much wraps up this section.
#
# ==== Further integration with your environment aka namespacing
#
# If you want this to cleanly integrate into your system-wide Ruby include path,
# you should put your extension classes inside a custom module.
#
#
# Example:
#
#   ./myldap.rb:
#   require 'active_ldap'
#   require 'myldap/user'
#   require 'myldap/group'
#   module MyLDAP
#   end
#
#   ./myldap/user.rb:
#   module MyLDAP
#   class User < ActiveLdap::Base
#     ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People', :classes => ['top', 'account', 'posixAccount']
#     belongs_to :groups, :class => 'MyLDAP::Group', :many => 'memberUid'
#   end
#   end
#
#   ./myldap/group.rb:
#   module MyLDAP
#   class Group < ActiveLdap::Base
#     ldap_mapping :classes => ['top', 'posixGroup'], :prefix => 'ou=Group'
#     has_many :members, :class => 'MyLDAP::User', :wrap => 'memberUid'
#     has_many :primary_members, :class => 'MyLDAP::User', :foreign_key => 'gidNumber', :primary_key => 'gidNumber'
#   end
#   end
#
# Now in your local applications, you can call
#
#   require 'myldap'
#
#   MyLDAP::Group.new('foo')
#   ...
#
# and everything should work well.
#
#
# ==== force array results for single values
#
# Even though Ruby/ActiveLdap attempts to maintain programmatic ease by
# returning Array values only. By specifying 'true' as an argument to
# any attribute method you will get back a Array if it is single value.
# Here's an example:
#
#   irb> user = User.new('drewry')
#   => ...
#   irb> user.cn(true)
#   => ["Will Drewry"]
#
# ==== Dynamic attribute crawling
#
# If you use tab completion in irb, you'll notice that you /can/ tab complete the dynamic
# attribute methods. You can still see which methods are for attributes using
# Base#attribute_names:
#
#   irb> d = Group.new('develop')
#   => ...
#   irb> d.attribute_names
#   => ["gidNumber", "cn", "memberUid", "commonName", "description", "userPassword", "objectClass"]
#
#
# ==== Juggling multiple LDAP connections
#
# In the same vein as the last tip, you can use multiple LDAP connections by
# per class as follows:
#
#   irb> anon_class = Class.new(Base)
#   => ...
#   irb> anon_class.establish_connection
#   => ...
#   irb> auth_class = Class.new(Base)
#   => ...
#   irb> auth_class.establish_connection(:password_block => {'mypass'})
#   => ...
#
# This can be useful for doing authentication tests and other such tricks.
#
# ==== :try_sasl
#
# If you have the Ruby/LDAP package with the SASL/GSSAPI patch from Ian
# MacDonald's web site, you can use Kerberos to bind to your LDAP server. By
# default, :try_sasl is false.
#
# Also note that you must be using OpenLDAP 2.1.29 or higher to use SASL/GSSAPI
# due to some bugs in older versions of OpenLDAP.
#
# ==== Don't be afraid! [Internals]
#
# Don't be afraid to add more methods to the extensions classes and to
# experiment. That's exactly how I ended up with this package. If you come up
# with something cool, please share it!
#
# The internal structure of ActiveLdap::Base, and thus all its subclasses, is
# still in flux. I've tried to minimize the changes to the overall API, but
# the internals are still rough around the edges.
#
# ===== Where's ldap_mapping data stored? How can I get to it?
#
# When you call ldap_mapping, it overwrites several class methods inherited
# from Base:
#   * Base.base()
#   * Base.required_classes()
#   * Base.dn_attribute()
# You can access these from custom class methods by calling MyClass.base(),
# or whatever. There are predefined instance methods for getting to these
# from any new instance methods you define:
#  * Base#base()
#  * Base#required_classes()
#  * Base#dn_attribute()
#
# ===== What else?
#
# Well if you want to use the LDAP connection for anything, I'd suggest still
# calling Base.connection to get it. There really aren't many other internals
# that need to be worried about.  You could get the LDAP schema with
# Base.schema.
#
# The only other useful tricks are dereferencing and accessing the stored
# data. Since LDAP attributes can have multiple names, e.g. cn or commonName,
# any methods you write might need to figure it out. I'd suggest just
# calling self[attribname] to get the value, but if that's not good enough,
# you can call look up the stored name by #to_real_attribute_name as follows:
#    irb> to_real_attribute_name('commonName')
#    => 'cn'
#
# This tells you the name the attribute is stored in behind the scenes (@data).
# Again, self[attribname] should be enough for most extensions, but if not,
# it's probably safe to dabble here.
#
# Also, if you like to look up all aliases for an attribute, you can call the
# following:
#
#  irb> schema.attribute_aliases('cn')
#  => ['cn','commonName']
#
# This is discovered automagically from the LDAP server's schema.
#
# == Limitations
#
# === Speed
#
# Currently, Ruby/ActiveLdap could be faster.  I have some recursive type
# checking going on which slows object creation down, and I'm sure there
# are many, many other places optimizations can be done.  Feel free
# to send patches, or just hang in there until I can optimize away the
# slowness.
#
# == Feedback
#
# Any and all feedback and patches are welcome. I am very excited about this
# package, and I'd like to see it prove helpful to more people than just myself.
#

require_gem_if_need = Proc.new do |library_name, gem_name|
  begin
    require library_name
  rescue LoadError
    require 'rubygems'
    gem gem_name
    require library_name
  end
end

require_gem_if_need.call("active_support", "activesupport")

if Dependencies.respond_to?(:load_paths)
  Dependencies.load_paths << File.expand_path(File.dirname(__FILE__))
end

module ActiveLdap
  VERSION = "0.9.0"
end

if RUBY_PLATFORM.match('linux')
  require 'active_ldap/timeout'
else
  require 'active_ldap/timeout_stub'
end

require_gem_if_need.call("active_record", "activerecord")
begin
  require_gem_if_need.call("gettext/active_record", "gettext")
rescue LoadError
end
require 'active_ldap/get_text'

require 'active_ldap/base'

require 'active_ldap/associations'
require 'active_ldap/attributes'
require 'active_ldap/configuration'
require 'active_ldap/connection'
require 'active_ldap/operations'
require 'active_ldap/object_class'
require 'active_ldap/human_readable'

require 'active_ldap/acts/tree'

require 'active_ldap/distinguished_name'
require 'active_ldap/populate'
require 'active_ldap/escape'
require 'active_ldap/helper'

require 'active_ldap/validations'
require 'active_ldap/callbacks'


ActiveLdap::Base.class_eval do
  include ActiveLdap::Associations
  include ActiveLdap::Attributes
  include ActiveLdap::Configuration
  include ActiveLdap::Connection
  include ActiveLdap::Operations
  include ActiveLdap::ObjectClass
  include ActiveLdap::HumanReadable

  include ActiveLdap::Acts::Tree

  include ActiveLdap::Validations
  include ActiveLdap::Callbacks
end

unless defined?(ACTIVE_LDAP_CONNECTION_ADAPTERS)
  ACTIVE_LDAP_CONNECTION_ADAPTERS = %w(ldap net_ldap)
end

ACTIVE_LDAP_CONNECTION_ADAPTERS.each do |adapter|
  require "active_ldap/adapter/#{adapter}"
end

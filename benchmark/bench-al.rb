base = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.expand_path(base))
$LOAD_PATH.unshift(File.expand_path(File.join(base, "..", "lib")))

require "active_ldap"
require "benchmark"

include ActiveLdap::GetTextSupport

argv, opts, options = ActiveLdap::Command.parse_options do |opts, options|
  options.prefix = "ou=People"

  opts.on("--prefix=PREFIX",
          _("Specify prefix for benchmarking"),
          _("(default: %s)") % options.prefix) do |prefix|
    options.prefix = prefix
  end
end

ActiveLdap::Base.setup_connection
config = ActiveLdap::Base.configuration

LDAP_HOST = config[:host]
LDAP_METHOD = config[:method]
if LDAP_METHOD == :ssl
  LDAP_PORT = config[:port] || URI::LDAPS::DEFAULT_PORT
else
  LDAP_PORT = config[:port] || URI::LDAP::DEFAULT_PORT
end
LDAP_BASE = config[:base]
LDAP_PREFIX = options.prefix
LDAP_USER = config[:bind_dn]
LDAP_PASSWORD = config[:password]

class ALUser < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => LDAP_PREFIX,
               :classes => ['posixAccount', 'person']
end

class ALUserLdap < ALUser
end
ALUserLdap.setup_connection(config.merge(:adapter => "ldap"))

class ALUserNetLdap < ALUser
end
ALUserNetLdap.setup_connection(config.merge(:adapter => "net-ldap"))

def search_al_ldap
  count = 0
  ALUserLdap.find(:all).each do |e|
    count += 1
  end
  count
end

def search_al_net_ldap
  count = 0
  ALUserNetLdap.find(:all).each do |e|
    count += 1
  end
  count
end

def search_al_ldap_without_object_creation
  count = 0
  ALUserLdap.search.each do |e|
    count += 1
  end
  count
end

def search_al_net_ldap_without_object_creation
  count = 0
  ALUserNetLdap.search.each do |e|
    count += 1
  end
  count
end

# === search_ldap
#
def search_ldap(conn)
  count = 0
  conn.search("#{LDAP_PREFIX},#{LDAP_BASE}",
              LDAP::LDAP_SCOPE_SUBTREE,
              "(uid=*)") do |e|
    count += 1
  end
  count
end # -- search_ldap

def search_net_ldap(conn)
  count = 0
  conn.search(:base => "#{LDAP_PREFIX},#{LDAP_BASE}",
              :scope => Net::LDAP::SearchScope_WholeSubtree,
              :filter => "(uid=*)") do |e|
    count += 1
  end
  count
end

def ldap_connection
  require 'ldap'
  if LDAP_METHOD == :tls
    conn = LDAP::SSLConn.new(LDAP_HOST, LDAP_PORT, true)
  else
    conn = LDAP::Conn.new(LDAP_HOST, LDAP_PORT)
  end
  conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
  conn.bind(LDAP_USER, LDAP_PASSWORD) if LDAP_USER and LDAP_PASSWORD
  conn
rescue LoadError
  nil
end

def net_ldap_connection
  require 'net/ldap'
  net_ldap_conn = Net::LDAP::Connection.new(:host => LDAP_HOST,
                                            :port => LDAP_PORT)
  if LDAP_USER and LDAP_PASSWORD
    net_ldap_conn.setup_encryption(:method => :start_tls) if LDAP_METHOD == :tls
    net_ldap_conn.bind(:method => :simple,
                       :username => LDAP_USER,
                       :password => LDAP_PASSWORD)
  end
  net_ldap_conn
rescue LoadError
  nil
end

def populate_base
  suffixes = []
  ActiveLdap::Base.base.split(/,/).reverse_each do |suffix|
    prefix = suffixes.join(",")
    suffixes.unshift(suffix)
    name, value = suffix.split(/=/, 2)
    next unless name == "dc"
    dc_class = Class.new(ActiveLdap::Base)
    dc_class.ldap_mapping :dn_attribute => "dc",
                          :prefix => "",
                          :scope => :base,
                          :classes => ["top", "dcObject", "organization"]
    dc_class.instance_variable_set("@base", prefix)
    next if dc_class.exists?(value, :prefix => "dc=#{value}")
    dc = dc_class.new(value)
    dc.o = dc.dc
    begin
      dc.save
    rescue ActiveLdap::OperationNotPermitted
    end
  end

  if ActiveLdap::Base.search.empty?
    raise "Can't populate #{ActiveLdap::Base.base}"
  end
end

def populate_users
  ou_class = Class.new(ActiveLdap::Base)
  ou_class.ldap_mapping :dn_attribute => "ou",
                        :prefix => "",
                        :classes => ["top", "organizationalUnit"]
  ou_class.new(LDAP_PREFIX.split(/=/)[1]).save!

  100.times do |i|
    name = i.to_s
    user = ALUser.new(name)
    user.uid_number = 100000 + i
    user.gid_number = 100000 + i
    user.cn = name
    user.sn = name
    user.home_directory = "/nonexistent"
    user.save!
  end
end

def populate
  populate_base
  populate_users
end

# === main
#
def main(do_populate)
  if do_populate
    puts(_("Populating..."))
    dumped_data = ActiveLdap::Base.dump(:scope => :sub)
    ActiveLdap::Base.delete_all(nil, :scope => :sub)
    populate
    puts
  end

  # Standard connection
  #
  ldap_conn = ldap_connection
  net_ldap_conn = net_ldap_connection

  al_ldap_count = 0
  al_net_ldap_count = 0
  al_ldap_count_without_object_creation = 0
  al_net_ldap_count_without_object_creation = 0
  ldap_count = 0
  net_ldap_count = 0
  Benchmark.bmbm(20) do |x|
    [1].each do |n|
      GC.start
      x.report("%3dx: AL(LDAP)" % n) do
        n.times {al_ldap_count = search_al_ldap}
      end
      GC.start
      x.report("%3dx: AL(Net::LDAP)" % n) do
        n.times {al_net_ldap_count = search_al_net_ldap}
      end
      GC.start
      x.report("%3dx: AL(LDAP: No Obj)" % n) do
        n.times do
          al_ldap_count_without_object_creation =
            search_al_ldap_without_object_creation
        end
      end
      x.report("%3dx: AL(Net::LDAP: No Obj)" % n) do
        n.times do
          al_net_ldap_count_without_object_creation =
            search_al_net_ldap_without_object_creation
        end
      end
      GC.start
      if ldap_conn
        x.report("%3dx: LDAP" % n) do
          n.times {ldap_count = search_ldap(ldap_conn)}
        end
      end
      GC.start
      if net_ldap_conn
        x.report("%3dx: Net::LDAP" % n) do
          n.times {net_ldap_count = search_net_ldap(net_ldap_conn)}
        end
      end
    end
  end

  puts
  puts(_("Entries processed by Ruby/ActiveLdap + LDAP: %d") % al_ldap_count)
  puts(_("Entries processed by Ruby/ActiveLdap + Net::LDAP: %d") % \
       al_net_ldap_count)
  puts(_("Entries processed by Ruby/ActiveLdap + LDAP: " \
         "(without object creation): %d") % \
       al_ldap_count_without_object_creation)
  puts(_("Entries processed by Ruby/ActiveLdap + Net::LDAP: " \
         "(without object creation): %d") % \
       al_net_ldap_count_without_object_creation)
  puts(_("Entries processed by Ruby/LDAP: %d") % ldap_count)
  puts(_("Entries processed by Net::LDAP: %d") % net_ldap_count)
ensure
  if do_populate
    puts
    puts(_("Cleaning..."))
    ActiveLdap::Base.delete_all(nil, :scope => :sub)
    ActiveLdap::Base.load(dumped_data)
  end
end

main(LDAP_USER && LDAP_PASSWORD)

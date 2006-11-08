base = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.expand_path(base))
$LOAD_PATH.unshift(File.expand_path(File.join(base, "..", "..", "lib")))

require "activeldap"
require "benchmark"

LDAP_SERVER = "127.0.0.1"
LDAP_PORT = 389
LDAP_BASE = "dc=localdomain"
LDAP_PREFIX = "ou=People"
LDAP_USER = nil
LDAP_PASSWORD = nil

class ALUser < ActiveLDAP::Base
  ldap_mapping :dnattr => 'uid', :prefix => LDAP_PREFIX,
               :classes => ['posixAccount', 'person']
end

# === search_al
#
def search_al
  count = 0
  ALUser.find_all.each do |e|
    count += 1
  end
  return count
end # -- search_al

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

def populate_base
  suffixes = []
  ActiveLDAP::Base.base.split(/,/).reverse_each do |suffix|
    prefix = suffixes.join(",")
    suffixes.unshift(suffix)
    name, value = suffix.split(/=/, 2)
    next unless name == "dc"
    dc_class = Class.new(ActiveLDAP::Base)
    dc_class.ldap_mapping :dnattr => "dc",
                          :prefix => "",
                          :scope => :base,
                          :classes => ["top", "dcObject", "organization"]
    dc_class.instance_variable_set("@base", prefix)
    next if dc_class.exists?(value, :prefix => "dc=#{value}")
    dc = dc_class.new(value)
    dc.o = dc.dc
    dc.save
  end

  if ActiveLDAP::Base.search.empty?
    raise "Can't populate #{ActiveLDAP::Base.base}"
  end
end

def populate_users
  ou_class = Class.new(ActiveLDAP::Base)
  ou_class.ldap_mapping :dnattr => "ou",
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

# === main(argv)
#
def main(argv)
  # Connect with AL
  #
  config = {
    :host => LDAP_SERVER,
    :port => LDAP_PORT,
    :base => LDAP_BASE,
  }

  do_populate = LDAP_USER && LDAP_PASSWORD

  if do_populate
    config[:bind_format] = LDAP_USER
    config[:password] = LDAP_PASSWORD
  end
  ActiveLDAP::Base.establish_connection(config)

  if do_populate
    puts "populating..."
    dumped_data = ActiveLDAP::Base.dump(:scope => :sub)
    ActiveLDAP::Base.delete_all(nil, :scope => :sub)
    populate
  end

  # Standard connection
  #
  conn = LDAP::Conn.new(LDAP_SERVER, LDAP_PORT)
  al_count = 0
  ldap_count = 0
  Benchmark.bm(10) do |x|
    x.report("AL") { al_count = search_al }
    x.report("LDAP") { ldap_count = search_ldap(conn) }
  end
  print "Entries processed by Ruby/ActiveLDAP: #{al_count}\n"
  print "Entries processed by Ruby/LDAP: #{ldap_count}\n"

  0
ensure
  if do_populate
    ActiveLDAP::Base.delete_all(nil, :scope => :sub)
    ActiveLDAP::Base.load(dumped_data)
  end
end

if $0 == __FILE__ then
 exit(main(ARGV) || 1)
end

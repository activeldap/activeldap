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

ActiveLdap::Base.establish_connection
config = ActiveLdap::Base.configuration

LDAP_SERVER = config[:host]
LDAP_PORT = config[:port]
LDAP_BASE = config[:base]
LDAP_PREFIX = options.prefix
LDAP_USER = config[:bind_dn]
LDAP_PASSWORD = config[:password]

class ALUser < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => LDAP_PREFIX,
               :classes => ['posixAccount', 'person']
end

# === search_al
#
def search_al
  count = 0
  ALUser.find(:all).each do |e|
    count += 1
  end
  count
end # -- search_al

def search_al_without_object_creation
  count = 0
  ALUser.search.each do |e|
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
  end

  # Standard connection
  #
  conn = LDAP::Conn.new(LDAP_SERVER, LDAP_PORT)
  al_count = 0
  al_count_without_object_creation = 0
  ldap_count = 0
  Benchmark.bm(10) do |x|
    x.report(_("AL")) {al_count = search_al}
    x.report(_("AL(No Obj)")) do
      al_count_without_object_creation = search_al_without_object_creation
    end
    x.report(_("LDAP")) {ldap_count = search_ldap(conn)}
  end
  puts(_("Entries processed by Ruby/ActiveLdap: %d") % al_count)
  puts(_("Entries processed by Ruby/ActiveLdap (without object creation): " \
         "%d") % al_count_without_object_creation)
  puts(_("Entries processed by Ruby/LDAP: %d") % ldap_count)
ensure
  if do_populate
    puts(_("Cleaning..."))
    ActiveLdap::Base.delete_all(nil, :scope => :sub)
    ActiveLdap::Base.load(dumped_data)
  end
end

main(LDAP_USER && LDAP_PASSWORD)

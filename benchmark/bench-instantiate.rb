base = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.expand_path(base))
$LOAD_PATH.unshift(File.expand_path(File.join(base, "..", "lib")))

require "active_ldap"
require "benchmark"

include ActiveLdap::GetTextSupport

argv = ARGV.dup
unless argv.include?("--config")
  argv.unshift("--config", File.join(base, "config.yaml"))
end
argv, opts, options = ActiveLdap::Command.parse_options(argv) do |opts, options|
  options.prefix = "ou=People"

  opts.on("--prefix=PREFIX",
          _("Specify prefix for benchmarking"),
          _("(default: %s)") % options.prefix) do |prefix|
    options.prefix = prefix
  end
end

ActiveLdap::Base.setup_connection
config = ActiveLdap::Base.configuration

LDAP_PREFIX = options.prefix
LDAP_USER = config[:bind_dn]
LDAP_PASSWORD = config[:password]

N_USERS = 100

class ALUser < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => LDAP_PREFIX,
               :classes => ['posixAccount', 'person']
end

def populate_base
  ActiveLdap::Populate.ensure_base
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

  N_USERS.times do |i|
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

def main(do_populate)
  if do_populate
    puts(_("Populating..."))
    dumped_data = ActiveLdap::Base.dump(:scope => :sub)
    ActiveLdap::Base.delete_all(nil, :scope => :sub)
    populate
    puts
  end

  Benchmark.bmbm(20) do |x|
    n = 100
    GC.start
    x.report("search 100 entries") do
      n.times {ALUser.search}
    end
    GC.start
    x.report("instantiate 1 entry") do
      n.times {ALUser.first}
    end
  end
ensure
  if do_populate
    puts
    puts(_("Cleaning..."))
    ActiveLdap::Base.delete_all(nil, :scope => :sub)
    ActiveLdap::Base.load(dumped_data)
  end
end

main(LDAP_USER && LDAP_PASSWORD)

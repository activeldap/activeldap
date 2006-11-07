$:<<"../../lib"

require "activeldap"
require "benchmark"
require "alusers"

LDAP_SERVER = "127.0.0.1"
LDAP_PORT = 389
LDAP_BASE = "dc=localdomain"

# === search_al
#
def search_al
 count = 0
 ALUser.find_all(:attribute => "uid",
                 :value => "*",
                 :objects => true).each do |e|
   count += 1
 end
 return count
end # -- search_al

# === search_ldap
#
def search_ldap(conn)
 count = 0
 conn.search("ou=People,#{LDAP_BASE}",
             LDAP::LDAP_SCOPE_SUBTREE,
             "(uid=*)") do |e|
   count += 1
 end
 return count 
end # -- search_ldap

# === main(argv)
#
def main(argv)

 # Connect with AL
 #
 ActiveLDAP::Base.connect(
                          :host => LDAP_SERVER,
                          :port => LDAP_PORT,
                          :base => LDAP_BASE
                         )

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
 return 0
end

if $0 == __FILE__ then
 exit(main(ARGV) || 1)
end



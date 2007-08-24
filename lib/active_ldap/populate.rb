module ActiveLdap
  module Populate
    module_function
    def ensure_base(base_class=nil)
      base_class ||= Base
      return unless base_class.search(:scope => :base).empty?

      base_dn = DN.parse(base_class.base)
      suffixes = []

      base_dn.rdns.reverse_each do |rdn|
        name, value = rdn.to_a[0]
        prefix = suffixes.join(",")
        suffixes.unshift("#{name}=#{value}")
        next unless name == "dc"
        dc_class = Class.new(base_class)
        dc_class.ldap_mapping :dn_attribute => "dc",
                              :prefix => "",
                              :scope => :base,
                              :classes => ["top", "dcObject", "organization"]
        dc_class.base = prefix
        next if dc_class.exists?(value, :prefix => "#{name}=#{value}")
        dc = dc_class.new(value)
        dc.o = dc.dc
        begin
          dc.save
        rescue ActiveLdap::OperationNotPermitted
        end
      end
    end

    def ensure_ou(name, base_class=nil)
      base_class ||= Base
      unless base_class.search(:prefix => "ou=#{name}", :scope => :base).empty?
        return
      end

      ou_class = Class.new(base_class)
      ou_class.ldap_mapping(:dn_attribute => "ou",
                            :prefix => "",
                            :classes => ["top", "organizationalUnit"])
      ou_class.new(name).save
    end
  end
end

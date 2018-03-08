module ActiveLdap
  module Populate
    module_function
    def ensure_base(base_class=nil, options={})
      base_class ||= Base
      return unless base_class.search(:scope => :base).empty?
      dc_base_class = options[:dc_base_class] || base_class
      ou_base_class = options[:ou_base_class] || base_class

      base_dn = DN.parse(base_class.base)
      suffixes = []

      base_dn.rdns.reverse_each do |rdn|
        name, value = rdn.to_a[0]
        prefix = suffixes.join(",")
        suffixes.unshift("#{name}=#{value}")
        begin
          case name.downcase
          when "dc"
            ensure_dc(value, prefix, dc_base_class)
          when "ou"
            ensure_ou(value,
                      :base => prefix,
                      :base_class => ou_base_class)
          end
        rescue ActiveLdap::OperationNotPermitted
        end
      end
    end

    def ensure_ou(name, options={})
      if options.is_a?(Class)
        base_class = options
        options = {}
      else
        base_class = options[:base_class] || Base
      end
      name = name.to_s if name.is_a?(DN)
      name = name.gsub(/\Aou\s*=\s*/i, '')

      ou_class = Class.new(base_class)
      ou_class.ldap_mapping(:dn_attribute => "ou",
                            :prefix => "",
                            :classes => ["top", "organizationalUnit"])
      ou_class.base = options[:base]
      return if ou_class.exist?(name)
      ou_class.new(name).save!
    end

    def ensure_dc(name, prefix, base_class=nil)
      base_class ||= Base
      name = name.to_s if name.is_a?(DN)
      name = name.gsub(/\Adc\s*=\s*/i, '')

      dc_class = Class.new(base_class)
      dc_class.ldap_mapping(:dn_attribute => "dc",
                            :prefix => "",
                            :scope => :base,
                            :classes => ["top", "dcObject", "organization"])
      dc_class.base = prefix
      return if dc_class.exist?(name)
      dc = dc_class.new(name)
      dc.o = dc.dc
      dc.save!
    end
  end
end

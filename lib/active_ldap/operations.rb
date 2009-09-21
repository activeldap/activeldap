module ActiveLdap
  module Operations
    class << self
      def included(base)
        super
        base.class_eval do
          extend(Common)
          extend(Find)
          extend(LDIF)
          extend(Delete)
          extend(Update)

          include(Common)
          include(Find)
          include(LDIF)
          include(Delete)
          include(Update)
        end
      end
    end

    module Common
      VALID_SEARCH_OPTIONS = [:attribute, :value, :filter, :prefix,
                              :classes, :scope, :limit, :attributes,
                              :sort_by, :order, :connection, :base]

      def search(options={}, &block)
        validate_search_options(options)
        attr = options[:attribute]
        value = options[:value] || '*'
        filter = options[:filter]
        prefix = options[:prefix]
        classes = options[:classes]

        value = value.first if value.is_a?(Array) and value.first.size == 1

        _attr = nil
        _prefix = nil
        if attr.nil? or attr == dn_attribute
          _attr, value, _prefix = split_search_value(value)
        end
        attr ||= _attr || ensure_search_attribute
        prefix ||= _prefix
        filter ||= [attr, value]
        filter = [:and, filter, *object_class_filters(classes)]
        _base = options[:base] ? [options[:base]] : [prefix, base]
        _base = prepare_search_base(_base)
        if options.has_key?(:ldap_scope)
          message = _(":ldap_scope search option is deprecated. " \
                      "Use :scope instead.")
          ActiveSupport::Deprecation.warn(message)
          options[:scope] ||= options[:ldap_scope]
        end
        search_options = {
          :base => _base,
          :scope => options[:scope] || scope,
          :filter => filter,
          :limit => options[:limit],
          :attributes => options[:attributes],
          :sort_by => options[:sort_by] || sort_by,
          :order => options[:order] || order,
        }

        options[:connection] ||= connection
        values = options[:connection].search(search_options) do |dn, attrs|
          attributes = {}
          attrs.each do |key, _value|
            normalized_attr, normalized_value =
              normalize_attribute_options(key, _value)
            attributes[normalized_attr] ||= []
            attributes[normalized_attr].concat(normalized_value)
          end
          [dn, attributes]
        end
        values = values.collect {|_value| yield(_value)} if block_given?
        values
      end

      def exist?(dn, options={})
        attr, value, prefix = split_search_value(dn)

        options_for_leaf = {
          :attribute => attr,
          :value => value,
          :prefix => prefix,
        }

        attribute = attr || ensure_search_attribute
        options_for_non_leaf = {
          :attribute => attr,
          :value => value,
          :prefix => ["#{attribute}=#{value}", prefix].compact.join(","),
          :scope => :base,
        }

        !search(options_for_leaf.merge(options)).empty? or
          !search(options_for_non_leaf.merge(options)).empty?
      end
      alias_method :exists?, :exist?

      def count(options={})
        search(options).size
      end

      private
      def validate_search_options(options)
        options.assert_valid_keys(VALID_SEARCH_OPTIONS)
      end

      def extract_options_from_args!(args)
        args.last.is_a?(Hash) ? args.pop : {}
      end

      def ensure_search_attribute(*candidates)
        default_search_attribute || "objectClass"
      end

      def ensure_dn_attribute(target)
        "#{dn_attribute}=" +
          target.gsub(/^\s*#{Regexp.escape(dn_attribute)}\s*=\s*/i, '')
      end

      def ensure_base(target)
        [truncate_base(target), base.to_s].reject do |component|
          component.blank?
        end.join(',')
      end

      def truncate_base(target)
        return nil if target.blank?
        return target if base.nil?
        if /,/ =~ target
          begin
            parsed_target = DN.parse(target)
            begin
              (parsed_target - base).to_s
            rescue ArgumentError
              target
            end
          rescue DistinguishedNameInvalid
            target
          end
        else
          target
        end
      end

      def prepare_search_base(components)
        components.compact.collect do |component|
          case component
          when String
            component
          when DN
            component.to_s
          else
            DN.new(*component).to_s
          end
        end.reject{|x| x.empty?}.join(",")
      end

      def object_class_filters(classes=nil)
        expected_classes = (classes || required_classes).collect do |name|
          Escape.ldap_filter_escape(name)
        end
        unexpected_classes = excluded_classes.collect do |name|
          Escape.ldap_filter_escape(name)
        end
        filters = []
        unless expected_classes.empty?
          filters << ["objectClass", "=", *expected_classes]
        end
        unless unexpected_classes.empty?
          filters << [:not, [:or, ["objectClass", "=", *unexpected_classes]]]
        end
        filters
      end

      def split_search_value(value)
        attr = prefix = nil

        begin
          dn = DN.parse(value)
          attr, value = dn.rdns.first.to_a.first
          rest = dn.rdns[1..-1]
          prefix = DN.new(*rest).to_s unless rest.empty?
        rescue DistinguishedNameInputInvalid
          return [attr, value, prefix]
        rescue DistinguishedNameInvalid
          begin
            dn = DN.parse("DUMMY=#{value}")
            _, value = dn.rdns.first.to_a.first
            rest = dn.rdns[1..-1]
            prefix = DN.new(*rest).to_s unless rest.empty?
          rescue DistinguishedNameInvalid
          end
        end

        prefix = nil if prefix == base
        prefix = truncate_base(prefix) if prefix
        [attr, value, prefix]
      end
    end

    module Find
      # find
      #
      # Finds the first match for value where |value| is the value of some
      # |field|, or the wildcard match. This is only useful for derived classes.
      # usage: Subclass.find(:all, :attribute => "cn", :value => "some*val")
      #        Subclass.find(:all, 'some*val')
      def find(*args)
        options = extract_options_from_args!(args)
        args = [:first] if args.empty? and !options.empty?
        case args.first
        when :first
          options[:value] ||= args[1]
          find_initial(options)
        when :last
          options[:value] ||= args[1]
          find_last(options)
        when :all
          options[:value] ||= args[1]
          find_every(options)
        else
          find_from_dns(args, options)
        end
      end

      # A convenience wrapper for <tt>find(:first,
      # *args)</tt>. You can pass in all the same arguments
      # to this method as you can to <tt>find(:first)</tt>.
      def first(*args)
        find(:first, *args)
      end

      # A convenience wrapper for <tt>find(:last,
      # *args)</tt>. You can pass in all the same arguments
      # to this method as you can to <tt>find(:last)</tt>.
      def last(*args)
        find(:last, *args)
      end

      # This is an alias for find(:all).  You can pass in
      # all the same arguments to this method as you can
      # to find(:all)
      def all(*args)
        find(:all, *args)
      end

      private
      def find_initial(options)
        find_every(options.merge(:limit => 1)).first
      end

      def find_last(options)
        order = options[:order] || self.order || 'ascend'
        order = normalize_sort_order(order) == :ascend ? :descend : :ascend
        find_initial(options.merge(:order => order))
      end

      def normalize_sort_order(value)
        case value.to_s
        when /\Aasc(?:end)?\z/i
          :ascend
        when /\Adesc(?:end)?\z/i
          :descend
        else
          raise ArgumentError, _("Invalid order: %s") % value.inspect
        end
      end

      def find_every(options)
        options = options.dup
        sort_by = options.delete(:sort_by) || self.sort_by
        order = options.delete(:order) || self.order
        limit = options.delete(:limit) if sort_by or order
        options[:attributes] |= ["objectClass"] if options[:attributes]

        results = search(options).collect do |dn, attrs|
          instantiate([dn, attrs, {:connection => options[:connection]}])
        end
        return results if sort_by.nil? and order.nil?

        sort_by ||= "dn"
        if sort_by.downcase == "dn"
          results = results.sort_by {|result| DN.parse(result.dn)}
        else
          results = results.sort_by {|result| result.send(sort_by)}
        end

        results.reverse! if normalize_sort_order(order || "ascend") == :descend
        results = results[0, limit] if limit
        results
      end

      def find_from_dns(dns, options)
        expects_array = dns.first.is_a?(Array)
        return [] if expects_array and dns.first.empty?

        dns = dns.flatten.compact.uniq

        case dns.size
        when 0
          raise EntryNotFound, _("Couldn't find %s without a DN") % name
        when 1
          result = find_one(dns.first, options)
          expects_array ? [result] : result
        else
          find_some(dns, options)
        end
      end

      def find_one(dn, options)
        attr, value, prefix = split_search_value(dn)
        filter = [attr || ensure_search_attribute,
                  Escape.ldap_filter_escape(value)]
        filter = [:and, filter, options[:filter]] if options[:filter]
        options = {:prefix => prefix}.merge(options.merge(:filter => filter))
        result = find_initial(options)
        if result
          result
        else
          args = [self.is_a?(Class) ? name : self.class.name,
                  dn]
          if options[:filter]
            format = _("Couldn't find %s: DN: %s: filter: %s")
            args << options[:filter].inspect
          else
            format = _("Couldn't find %s: DN: %s")
          end
          raise EntryNotFound, format % args
        end
      end

      def find_some(dns, options)
        dn_filters = dns.collect do |dn|
          attr, value, prefix = split_search_value(dn)
          attr ||= ensure_search_attribute
          filter = [attr, value]
          if prefix
            filter = [:and,
                      filter,
                      [dn, "*,#{Escape.ldap_filter_escape(prefix)},#{base}"]]
          end
          filter
        end
        filter = [:or, *dn_filters]
        filter = [:and, filter, options[:filter]] if options[:filter]
        result = find_every(options.merge(:filter => filter))
        if result.size == dns.size
          result
        else
          args = [self.is_a?(Class) ? name : self.class.name,
                  dns.join(", ")]
          if options[:filter]
            format = _("Couldn't find all %s: DNs (%s): filter: %s")
            args << options[:filter].inspect
          else
            format = _("Couldn't find all %s: DNs (%s)")
          end
          raise EntryNotFound, format % args
        end
      end

      def ensure_dn(target)
        attr, value, prefix = split_search_value(target)
        "#{attr || dn_attribute}=#{value},#{prefix || base}"
      end
    end

    module LDIF
      def dump(options={})
        ldif = Ldif.new
        options = {:base => base, :scope => scope}.merge(options)
        options[:connection] ||= connection
        options[:connection].search(options) do |dn, attributes|
          ldif << Ldif::Record.new(dn, attributes)
        end
        return "" if ldif.records.empty?
        ldif.to_s
      end

      def to_ldif_record(dn, attributes)
        Ldif::Record.new(dn, attributes)
      end

      def to_ldif(dn, attributes)
        Ldif.new([to_ldif_record(dn, attributes)]).to_s
      end

      def load(ldif, options={})
        return if ldif.blank?
        Ldif.parse(ldif).each do |record|
          record.load(self, options)
        end
      end

      module ContentRecordLoadable
        def load(operator, options)
          operator.add_entry(dn, attributes, options)
        end
      end
      Ldif::ContentRecord.send(:include, ContentRecordLoadable)

      module AddRecordLoadable
        def load(operator, options)
          entries = attributes.collect do |key, value|
            [:add, key, value]
          end
          options = {:controls => controls}.merge(options)
          operator.modify_entry(dn, entries, options)
        end
      end
      Ldif::AddRecord.send(:include, AddRecordLoadable)

      module DeleteRecordLoadable
        def load(operator, options)
          operator.delete_entry(dn, {:controls => controls}.merge(options))
        end
      end
      Ldif::DeleteRecord.send(:include, DeleteRecordLoadable)

      module ModifyNameRecordLoadable
        def load(operator, options)
          operator.modify_rdn_entry(dn, new_rdn, delete_old_rdn?, new_superior,
                                    {:controls => controls}.merge(options))
        end
      end
      Ldif::ModifyNameRecord.send(:include, ModifyNameRecordLoadable)

      module ModifyRecordLoadable
        def load(operator, options)
          modify_entries = operations.inject([]) do |result, operation|
            result + operation.to_modify_entries
          end
          return if modify_entries.empty?
          operator.modify_entry(dn, modify_entries,
                                {:controls => controls}.merge(options))
        end

        module AddOperationModifiable
          def to_modify_entries
            attributes.collect do |key, value|
              [:add, key, value]
            end
          end
        end
        Ldif::ModifyRecord::AddOperation.send(:include, AddOperationModifiable)

        module DeleteOperationModifiable
          def to_modify_entries
            return [[:delete, full_attribute_name, []]] if attributes.empty?
            attributes.collect do |key, value|
              [:delete, key, value]
            end
          end
        end
        Ldif::ModifyRecord::DeleteOperation.send(:include,
                                                 DeleteOperationModifiable)

        module ReplaceOperationModifiable
          def to_modify_entries
            return [[:replace, full_attribute_name, []]] if attributes.empty?
            attributes.collect do |key, value|
              [:replace, key, value]
            end
          end
        end
        Ldif::ModifyRecord::ReplaceOperation.send(:include,
                                                  ReplaceOperationModifiable)
      end
      Ldif::ModifyRecord.send(:include, ModifyRecordLoadable)
    end

    module Delete
      def destroy(targets, options={})
        targets = [targets] unless targets.is_a?(Array)
        targets.each do |target|
          find(target, options).destroy
        end
      end

      def destroy_all(options_or_filter=nil, deprecated_options=nil)
        if deprecated_options.nil?
          if options_or_filter.is_a?(String)
            options = {:filter => options_or_filter}
          else
            options = (options_or_filter || {}).dup
          end
        else
          options = deprecated_options.merge(:filter => options_or_filter)
        end

        find(:all, options).sort_by do |target|
          target.dn
        end.each do |target|
          target.destroy
        end
      end

      def delete(targets, options={})
        targets = [targets] unless targets.is_a?(Array)
        targets = targets.collect do |target|
          ensure_dn_attribute(ensure_base(target))
        end
        delete_entry(targets, options)
      end

      def delete_entry(dn, options={})
        options[:connection] ||= connection
        begin
          options[:connection].delete(dn, options)
        rescue Error
          format = _("Failed to delete LDAP entry: <%s>: %s")
          raise DeleteError.new(format % [dn.inspect, $!.message])
        end
      end

      def delete_all(options_or_filter=nil, deprecated_options=nil)
        if deprecated_options.nil?
          if options_or_filter.is_a?(String)
            options = {:filter => options_or_filter}
          else
            options = (options_or_filter || {}).dup
          end
        else
          options = deprecated_options.merge(:filter => options_or_filter)
        end
        targets = search(options).collect do |dn, attributes|
          dn
        end.sort_by do |dn|
          dn.upcase.reverse
        end.reverse

        delete_entry(targets, options)
      end
    end

    module Update
      def add_entry(dn, attributes, options={})
        unnormalized_attributes = attributes.collect do |key, value|
          [:add, key, unnormalize_attribute(key, value)]
        end
        options[:connection] ||= connection
        options[:connection].add(dn, unnormalized_attributes, options)
      end

      def modify_entry(dn, attributes, options={})
        return if attributes.empty?
        unnormalized_attributes = attributes.collect do |type, key, value|
          [type, key, unnormalize_attribute(key, value)]
        end
        options[:connection] ||= connection
        options[:connection].modify(dn, unnormalized_attributes, options)
      end

      def modify_rdn_entry(dn, new_rdn, delete_old_rdn, new_superior, options={})
        options[:connection] ||= connection
        options[:connection].modify_rdn(dn, new_rdn, delete_old_rdn,
                                        new_superior, options)
      end

      def update(dn, attributes, options={})
        if dn.is_a?(Array)
          i = -1
          dns = dn
          dns.collect do |_dn|
            i += 1
            update(_dn, attributes[i], options)
          end
        else
          object = find(dn, options)
          object.update_attributes(attributes)
          object
        end
      end

      def update_all(attributes, filter=nil, options={})
        search_options = options.dup
        if filter
          if filter.is_a?(String) and /[=\(\)&\|]/ !~ filter
            search_options = search_options.merge(:value => filter)
          else
            search_options = search_options.merge(:filter => filter)
          end
        end
        targets = search(search_options).collect do |dn, attrs|
          dn
        end

        unnormalized_attributes = attributes.collect do |name, value|
          normalized_name, normalized_value = normalize_attribute(name, value)
          [:replace, normalized_name,
           unnormalize_attribute(normalized_name, normalized_value)]
        end
        options[:connection] ||= connection
        conn = options[:connection]
        targets.each do |dn|
          conn.modify(dn, unnormalized_attributes, options)
        end
      end
    end
  end
end

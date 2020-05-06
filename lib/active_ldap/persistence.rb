module ActiveLdap
  module Persistence
    # new_entry?
    #
    # Return whether the entry is new entry in LDAP or not
    def new_entry?
      @new_entry
    end

    # Return whether the entry is saved entry or not.
    def persisted?
      not new_entry?
    end

    # destroy
    #
    # Delete this entry from LDAP
    def destroy
      # TODO: support deleting relations
      delete
    end

    def delete(options={})
      if persisted?
        default_options = {
          :connection => connection,
        }
        self.class.delete_entry(dn, default_options.merge(options))
      end
      @new_entry = true
      freeze
    end

    # save
    #
    # Save and validate this object into LDAP
    # either adding or replacing attributes
    # TODO: Relative DN support
    def save(*)
      create_or_update
    end

    def save!(*)
      unless create_or_update
        raise EntryNotSaved, _("entry %s can't be saved") % dn
      end
      true
    end

    def create_or_update
      new_entry? ? create : update
    end

    def create
      prepare_data_for_saving do |data, ldap_data|
        attributes = collect_all_attributes(data)
        add_entry(dn, attributes)
        @new_entry = false
        true
      end
    end

    def update
      prepare_data_for_saving do |data, ldap_data|
        new_dn_value, attributes = collect_modified_attributes(ldap_data, data)
        modify_entry(@original_dn, attributes)
        if new_dn_value
          old_dn_base = DN.parse(@original_dn).parent
          new_dn_base = dn.clone.parent
          if old_dn_base == new_dn_base
            new_superior = nil
          else
            new_superior = new_dn_base.to_s
          end
          modify_rdn_entry(@original_dn,
                           "#{dn_attribute}=#{DN.escape_value(new_dn_value)}",
                           true,
                           new_superior)
        end
        true
      end
    end

    def reload(options={})
      clear_association_cache
      search_options = options.merge(value: id)
      _, attributes = search(search_options).find do |_dn, _attributes|
        dn == _dn
      end
      if attributes.nil?
        raise EntryNotFound, _("Can't find DN '%s' to reload") % dn
      end

      @ldap_data.update(attributes)
      classes = extract_object_class!(attributes)
      self.classes = classes
      self.attributes = attributes
      @new_entry = false
      self
    end
  end # Persistence
end # ActiveLdap

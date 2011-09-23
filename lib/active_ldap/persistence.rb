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
      self.class.delete(dn)
      @new_entry = true
    end

    def delete(options={})
      super(dn, options)
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
            new_superior = new_dn_base
          end
          modify_rdn_entry(@original_dn,
                           "#{dn_attribute}=#{DN.escape_value(new_dn_value)}",
                           true,
                           new_superior)
        end
        true
      end
    end
  end # Persistence
end # ActiveLdap

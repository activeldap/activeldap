require_library_or_gem 'net/ldap'

module Net
  class LDAP
    class Entry
      alias initialize_without_original_attribute_names initialize
      def initialize(*args)
        @original_attribute_names = []
        initialize_without_original_attribute_names(*args)
      end

      alias aset_without_original_attribute_names []=
      def []=(name, value)
        @original_attribute_names << name
        aset_without_original_attribute_names(name, value)
      end

      def original_attribute_names
        @original_attribute_names.compact.uniq
      end
    end
  end
end

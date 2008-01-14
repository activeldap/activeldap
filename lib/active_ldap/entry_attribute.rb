require "active_ldap/attributes"

module ActiveLdap
  class EntryAttribute
    include Attributes::Normalize

    attr_reader :must, :may, :object_classes, :attribute_schemata
    def initialize(schema, object_classes)
      @attribute_schemata = {}
      @attribute_names = {}
      @normalized_attribute_names = {}
      @attribute_aliases = {}
      @must = []
      @may = []
      @object_classes = []
      define_attribute_methods(schema.attribute('objectClass'))
      object_classes.each do |objc|
        # get all attributes for the class
        object_class = schema.object_class(objc)
        @object_classes << object_class
        @must.concat(object_class.must)
        @may.concat(object_class.may)
      end
      @must.uniq!
      @may.uniq!
      (@must + @may).each do |attr|
        # Update attr_method with appropriate
        define_attribute_methods(attr)
      end
    end

    def attribute_names(normalize=false)
      names = @attribute_names.keys
      if normalize
        names.collect do |name|
          normalize(name)
        end.uniq
      else
        names
      end
    end

    def normalize(name, allow_normalized_name=false)
      return name if name.nil?
      name = name.to_s
      real_name = @attribute_names[name]
      real_name ||= @attribute_aliases[Inflector.underscore(name)]
      if real_name
        real_name
      elsif allow_normalized_name
        @normalized_attribute_names[normalize_attribute_name(name)]
      else
        nil
      end
    end

    def all_names
      @attribute_names.keys + @attribute_aliases.keys
    end

    private
    # define_attribute_methods
    #
    # Make a method entry for _every_ alias of a valid attribute and map it
    # onto the first attribute passed in.
    def define_attribute_methods(attribute)
      real_name = attribute.name
      return if @attribute_schemata.has_key?(real_name)
      @attribute_schemata[real_name] = attribute
      ([real_name] + attribute.aliases).each do |name|
        @attribute_names[name] = real_name
        @attribute_aliases[Inflector.underscore(name)] = real_name
        @normalized_attribute_names[normalize_attribute_name(name)] = real_name
      end
    end
  end
end

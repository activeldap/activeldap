require "active_ldap/attributes"

module ActiveLdap
  class EntryAttribute
    include Attributes::Normalizable

    attr_reader :must, :may, :object_classes, :schemata
    def initialize(schema, object_classes)
      @schemata = {}
      @names = {}
      @normalized_names = {}
      @aliases = {}
      @must = []
      @may = []
      @object_classes = []
      register(schema.attribute('objectClass'))
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
        register(attr)
      end
    end

    def names(normalize=false)
      names = @names.keys
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
      return nil if @names.empty? and @aliases.empty?
      name = name.to_s
      real_name = @names[name]
      real_name ||= @aliases[name.underscore]
      if real_name
        real_name
      elsif allow_normalized_name
        return nil if @normalized_names.empty?
        @normalized_names[normalize_attribute_name(name)]
      else
        nil
      end
    end

    def all_names
      @names.keys + @aliases.keys
    end

    # register
    #
    # Make a method entry for _every_ alias of a valid attribute and map it
    # onto the first attribute passed in.
    def register(attribute)
      real_name = attribute.name
      return if @schemata.has_key?(real_name)
      @schemata[real_name] = attribute
      ([real_name] + attribute.aliases).each do |name|
        @names[name] = real_name
        @aliases[name.underscore] = real_name
        @normalized_names[normalize_attribute_name(name)] = real_name
      end
    end
  end
end

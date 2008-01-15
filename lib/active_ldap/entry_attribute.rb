require "active_ldap/attributes"

module ActiveLdap
  class EntryAttribute
    include Attributes::Normalizable

    attr_reader :must, :may, :object_classes, :schemata
    def initialize(schema, object_classes)
      @schemata = {}
      @names = {}
      @normalized_names = {}
      @cached_names = {}
      @cached_normalized_names = {}
      @aliases = {}
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
      name = name.to_s
      if allow_normalized_name
        cache = @cached_names
      else
        cache = @cached_normalized_names
      end

      return cache[name] if cache.has_key?(name)
      cache[name] = compute_normalized_name(name, allow_normalized_name)
    end

    def all_names
      @names.keys + @aliases.keys
    end

    private
    # define_attribute_methods
    #
    # Make a method entry for _every_ alias of a valid attribute and map it
    # onto the first attribute passed in.
    def define_attribute_methods(attribute)
      real_name = attribute.name
      return if @schemata.has_key?(real_name)
      @schemata[real_name] = attribute
      ([real_name] + attribute.aliases).each do |name|
        @names[name] = real_name
        @aliases[Inflector.underscore(name)] = real_name
        @normalized_names[normalize_attribute_name(name)] = real_name
      end
    end

    def compute_normalized_name(name, allow_normalized_name=false)
      real_name = @names[name]
      real_name ||= @aliases[Inflector.underscore(name)]
      if real_name
        real_name
      elsif allow_normalized_name
        @normalized_names[normalize_attribute_name(name)]
      else
        nil
      end
    end
  end
end

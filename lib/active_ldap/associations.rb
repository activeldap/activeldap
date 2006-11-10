require 'active_ldap/association/belongs_to'
require 'active_ldap/association/belongs_to_many'
require 'active_ldap/association/has_many'
require 'active_ldap/association/has_many_wrap'

module ActiveLdap
  # Associations
  #
  # Associations provides the class methods needed for
  # the extension classes to create methods using
  # belongs_to and has_many
  module Associations
    def self.append_features(base)
      super
      base.extend(ClassMethods)
    end

    module ClassMethods
      def set_associated_class(name, klass)
        @associated_classes ||= {}
        @associated_classes[name.to_s] = klass
      end

      def associated_class(name)
        @associated_classes[name.to_s]
      end

      # belongs_to
      #
      # This defines a method for an extension class map its DN key
      # attribute value on to multiple items which reference it by
      # |:foreign_key| in the other LDAP entry covered by class |:class_name|.
      #
      # Example:
      #  belongs_to :groups, :class_name => "Group",
      #             :many => "memberUid" # Group#memberUid
      #             # :foreign_key => "uid" # User#uid
      #             # dn attribute value is used by default
      #  belongs_to :primary_group, :class_name => "Group",
      #             :foreign_key => "gidNumber", # User#gidNumber
      #             :primary_key => "gidNumber"  # Group#gidNumber
      #
      def belongs_to(association_id, options={})
        validate_belongs_to_options(options)
        klass = options[:class] || Inflector.classify(association_id)
        foreign_key = options[:foreign_key]
        primary_key = options[:primary_key]
        many = options[:many]
        set_associated_class(association_id, klass)

        opts = {
          :association_id => association_id,
          :foreign_key_name => foreign_key,
          :primary_key_name => primary_key,
          :many => many,
        }
        if opts[:many]
          association_class = Association::BelongsToMany
          opts[:foreign_key_name] ||= dn_attribute
        else
          association_class = Association::BelongsTo
          opts[:foreign_key_name] ||= "#{association_id}_id"
        end

        association_accessor(association_id) do |target|
          association_class.new(target, opts)
        end
      end


      # has_many
      #
      # This defines a method for an extension class expand an 
      # existing multi-element attribute into ActiveLdap objects.
      # This discards any calls which result in entries that
      # don't exist in LDAP!
      #
      # Example:
      #   has_many :primary_members, :class_name => "User",
      #            :primary_key => "gidNumber", # User#gidNumber
      #            :foreign_key => "gidNumber"  # Group#gidNumber
      #   has_many :members, :class_name => "User",
      #            :wrap => "memberUid" # Group#memberUid
      def has_many(association_id, options = {})
        validate_has_many_options(options)
        klass = options[:class] || Inflector.classify(association_id)
        foreign_key = options[:foreign_key] || association_id.to_s + "_id"
        primary_key = options[:primary_key]
        set_associated_class(association_id, klass)

        opts = {
          :association_id => association_id,
          :foreign_key_name => foreign_key,
          :primary_key_name => primary_key,
          :wrap => options[:wrap],
        }
        if opts[:wrap]
          association_class = Association::HasManyWrap
        else
          association_class = Association::HasMany
        end

        association_accessor(association_id) do |target|
          association_class.new(target, opts)
        end
      end

      private
      def association_accessor(name, &make_association)
        association_reader(name, &make_association)
        association_writer(name, &make_association)
      end

      def association_reader(name, &make_association)
        define_method(name) do
          association = instance_variable_get("@#{name}")
          unless association
            association = make_association.call(self)
            instance_variable_set("@#{name}", association)
          end
          association
        end
      end

      def association_writer(name, &make_association)
        define_method("#{name}=") do |new_value|
          association = instance_variable_get("@#{name}")
          association ||= make_association.call(self)

          association.replace(new_value)

          if new_value.nil?
            instance_variable_set("@#{name}", nil)
          else
            instance_variable_set("@#{name}", association)
          end

          instance_variable_get("@#{name}")
        end
      end

      VALID_BELONGS_TO_OPTIONS = [:class, :foreign_key, :primary_key, :many]
      def validate_belongs_to_options(options)
        options.assert_valid_keys(VALID_BELONGS_TO_OPTIONS)
      end

      VALID_HAS_MANY_OPTIONS = [:class, :foreign_key, :primary_key, :wrap]
      def validate_has_many_options(options)
        options.assert_valid_keys(VALID_HAS_MANY_OPTIONS)
      end
    end
  end
end

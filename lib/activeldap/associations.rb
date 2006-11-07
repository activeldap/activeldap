require 'activeldap/association/belongs_to'
require 'activeldap/association/belongs_to_many'
require 'activeldap/association/has_many'
require 'activeldap/association/has_many_wrap'

module ActiveLDAP
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
        klass = options[:class_name] || association_id.to_s
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

        make_association = Proc.new do |target|
          association_class.new(target, opts)
        end

        define_method(association_id) do
          association = instance_variable_get("@#{association_id}")
          unless association
            association = make_association.call(self)
            instance_variable_set("@#{association_id}", association)
          end
          association
        end

        define_method("#{association_id}=") do |new_value|
          association = instance_variable_get("@#{association_id}")
          association ||= make_association.call(self)

          association.replace(new_value)

          if new_value.nil?
            instance_variable_set("@#{association_id}", nil)
          else
            instance_variable_set("@#{association_id}", association)
          end

          instance_variable_get("@#{association_id}")
        end
      end


      # has_many
      #
      # This defines a method for an extension class expand an 
      # existing multi-element attribute into ActiveLDAP objects.
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
        klass = options[:class_name] || association_id.to_s
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

        make_association = Proc.new do |target|
          association_class.new(target, opts)
        end

        define_method(association_id) do
          association = instance_variable_get("@#{association_id}")
          unless association
            association = make_association.call(self)
            instance_variable_set("@#{association_id}", association)
          end
          association
        end

        define_method("#{association_id}=") do |new_value|
          association = instance_variable_get("@#{association_id}")
          association ||= make_association.call(self)

          association.replace(new_value)

          if new_value.nil?
            instance_variable_set("@#{association_id}", nil)
          else
            instance_variable_set("@#{association_id}", association)
          end

          instance_variable_get("@#{association_id}")
        end
      end
    end
  end
end

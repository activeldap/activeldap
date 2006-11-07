require 'activeldap/association/belongs_to'
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
     #  belongs_to :groups, :class_name => Group, :foreign_key => memberUid,
     #             :local_key => 'uid'
     #
     def belongs_to(association_id, options={})
       klass = options[:class_name] || association_id.to_s
       foreign_key = options[:foreign_key] || association_id.to_s + "_id"
       primary_key = options[:primary_key]
       set_associated_class(association_id, klass)

       make_association = Proc.new do |target|
         opts = {
           :association_id => association_id,
           :foreign_key_name => foreign_key,
           :primary_key_name => primary_key,
         }
         association = Association::BelongsTo.new(target, opts)
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
     #   has_many :primary_members, :class_name => User,
     #            :primary_key => "gidNumber", # User#gidNumber
     #            :foreign_key => 'gidNumber'  # Group#gidNumber
     #   has_many :members, :class_name => User,
     #            :wrap => "memberUid" # Group#memberUid
     #
     # TODO[ENH]: def #{...}=(val) to redefine group membership
     def has_many(association_id, options = {})
       klass = options[:class_name] || association_id.to_s
       foreign_key = options[:foreign_key] || association_id.to_s + "_id"
       primary_key = options[:primary_key]
       set_associated_class(association_id, klass)

       define_method(association_id) do
         association = instance_variable_get("@#{association_id}")
         unless association
           opts = {
             :association_id => association_id,
             :foreign_key_name => foreign_key,
             :primary_key_name => primary_key,
             :wrap => options[:wrap],
           }
           if opts[:wrap]
             association = Association::HasManyWrap.new(self, opts)
           else
             association = Association::HasMany.new(self, opts)
           end
           instance_variable_set("@#{association_id}", association)
         end
         association
       end
      end
    end
  end
end

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
     def insert_belongs_to_association(name, klass)
       @belongs_to_associations ||= {}
       @belongs_to_associations[name.to_s] = klass
     end

     def insert_has_many_association(name, klass)
       @has_many_associations ||= {}
       @has_many_associations[name.to_s] = klass
     end

     def has_many_association(name)
       @has_many_associations[name.to_s]
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
     def belongs_to(association_id, options = {})
       klass = options[:class_name] || association_id.to_s
       key = options[:foreign_key]  || association_id.to_s + "_id"
       local_key = options[:local_key] || ''
       class_eval <<-"end_eval"
         def #{association_id}(objects = nil)
           objects = @@config[:return_objects] if objects.nil?
           local_key = "#{local_key}"
           local_key = dnattr() if local_key.empty?
           results = []
           #{klass}.find_all(:attribute => "#{key}", :value => send(local_key.to_sym), :objects => objects).each do |o|
             results << o
           end
           return results
         end
       end_eval
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
       insert_has_many_association(association_id, klass)

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

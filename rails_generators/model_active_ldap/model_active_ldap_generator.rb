require 'active_ldap'

class ModelActiveLdapGenerator < Rails::Generator::NamedBase
  include ActiveLdap::GetTextSupport

  default_options :dn_attribute => "cn", :classes => nil

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions class_path, class_name, "#{class_name}Test"

      # Model, test, and fixture directories.
      m.directory File.join('app/models', class_path)
      m.directory File.join('test/unit', class_path)
      m.directory File.join('test/fixtures', class_path)

      # Model class, unit test, and fixtures.
      m.template('model_active_ldap.rb',
                 File.join('app/models', class_path, "#{file_name}.rb"),
                 :assigns => {:ldap_mapping => ldap_mapping})
      m.template('unit_test.rb',
                 File.join('test/unit', class_path, "#{file_name}_test.rb"))
      m.template('fixtures.yml',
                 File.join('test/fixtures', class_path, "#{table_name}.yml"))
    end
  end

  private
  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--dn-attribute=ATTRIBUTE",
           _("Use ATTRIBUTE as default DN attribute for " \
             "instances of this model"),
           _("(default: %s)") % options[:dn_attribute]) do |attribute|
      options[:dn_attribute] = attribute
    end

    opt.on("--prefix=PREFIX",
           _("Use PREFIX as prefix for this model"),
           _("(default: %s)") % default_prefix) do |prefix|
      options[:prefix] = prefix
    end

    opt.on("--classes=CLASS,CLASS,...",
           Array,
           "Use CLASSES as required objectClass for instances of this model",
           "(default: %s)" % options[:classes]) do |classes|
      options[:classes] = classes
    end
  end

  def prefix
    options[:prefix] || default_prefix
  end

  def default_prefix
    "ou=#{name.demodulize.pluralize}"
  end

  def ldap_mapping(indent='  ')
    mapping = "ldap_mapping "
    mapping_options = [":dn_attribute => #{options[:dn_attribute].dump}"]
    mapping_options << ":prefix => #{prefix.dump}"
    if options[:classes]
      mapping_options << ":classes => #{options[:classes].inspect}"
    end
    mapping_options = mapping_options.join(",\n#{indent}#{' ' * mapping.size}")
    "#{indent}#{mapping}#{mapping_options}"
  end
end

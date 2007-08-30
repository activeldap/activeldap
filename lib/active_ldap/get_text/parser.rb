require 'active_ldap'
require 'gettext/parser/ruby'

module ActiveLdap
  module GetText
    class Parser
      include GetText

      def initialize(configuration=nil)
        configuration = ensure_configuration(configuration)
        configuration = default_configuration.merge(configuration)

        configuration = extract_options(configuration)
        ActiveLdap::Base.establish_connection(configuration)
      end

      def parse(file, targets=[])
        targets = RubyParser.parse(file, targets) if RubyParser.target?(file)
        extract(targets) do
          load_constants(file).each do |name|
            klass = name.constantize
            next unless klass.is_a?(Class)
            next unless klass < ActiveLdap::Base
            register(klass.name.singularize.underscore.gsub(/_/, " "), file)
            next unless @extract_schema
            klass.classes.each do |object_class|
              register_object_class(object_class, file)
            end
          end
        end
      end

      def target?(file)
        @classes_re.match(File.read(file))
      end

      def extract_all_in_schema(targets=[])
        extract(targets) do
          schema = ActiveLdap::Base.schema
          schema.object_classes.each do |object_class|
            register_object_class(object_class, "-")
          end
          schema.attributes.each do |attribute|
            register_attribute(attribute, "-")
          end
          schema.ldap_syntaxes.each do |syntax|
            register_syntax(syntax, "-")
          end
        end
      end

      private
      def extract_options(configuration)
        configuration = configuration.dup
        classes = configuration.delete(:classes) || ["ActiveLdap::Base"]
        @classes_re = /class.*#{Regexp.union(*classes)}/ #
        @extract_schema = configuration.delete(:extract_schema)
        configuration
      end

      def default_configuration
        {
          :host => "127.0.0.1",
          :allow_anonymous => true,
          :extract_schema => false,
        }
      end

      def ensure_configuration(configuration)
        configuration ||= ENV["RAILS_ENV"] || {}
        if configuration.is_a?(String)
          if File.exists?(configuration)
            require 'erb'
            require 'yaml'
            configuration = YAML.load(ERB.new(File.read(configuration)).result)
          else
            ENV["RAILS_ENV"] = configuration
            require 'config/environment'
            configuration = ActiveLdap::Base.configurations[configuration]
          end
        end
        if Object.const_defined?(:RAILS_ENV)
          rails_configuration = ActiveLdap::Base.configurations[RAILS_ENV]
          configuration = rails_configuration.merge(configuration)
        end
        configuration = configuration.symbolize_keys
      end

      def load_constants(file)
        old_constants = Object.constants
        begin
          eval(File.read(file), TOPLEVEL_BINDING, file)
        rescue
          format = _("Ignored '%{file}'. Solve dependencies first.")
          $stderr.puts(format % {:file => file})
          $stderr.puts($!)
        end
        Object.constants - old_constants
      end

      def extract(targets)
        @targets = {}
        targets.each do |id, *file_infos|
          @targets[id] = file_infos
        end
        yield
        @targets.collect do |id, file_infos|
          [id, *file_infos.uniq]
        end.sort_by do |id,|
          id
        end
      end

      def register(id, file)
        file_info = "#{file}:-"
        @targets[id] ||= []
        @targets[id] << file_info
      end

      def register_object_class(object_class, file)
        [object_class.name, *object_class.aliases].each do |name|
          register(ActiveLdap::Base.human_object_class_name_msgid(name), file)
        end
        if object_class.description
          msgid =
            ActiveLdap::Base.human_object_class_description_msgid(object_class)
          register(msgid, file)
        end
        (object_class.must(false) + object_class.may(false)).each do |attribute|
          register_attribute(attribute, file)
        end
        object_class.super_classes.each do |super_class|
          register_object_class(super_class, file)
        end
      end

      def register_attribute(attribute, file)
        [attribute.name, *attribute.aliases].each do |name|
          msgid = ActiveLdap::Base.human_attribute_name_msgid(name)
          register(msgid, file) if msgid
        end
        if attribute.description
          msgid = ActiveLdap::Base.human_attribute_description_msgid(attribute)
          register(msgid, file)
        end
      end

      def register_syntax(syntax, file)
        msgid = ActiveLdap::Base.human_syntax_name_msgid(syntax)
        register(msgid, file)

        if syntax.description
          msgid = ActiveLdap::Base.human_syntax_description_msgid(syntax)
          register(msgid, file)
        end
      end
    end
  end
end

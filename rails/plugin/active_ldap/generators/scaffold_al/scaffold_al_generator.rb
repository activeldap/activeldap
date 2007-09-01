class ScaffoldAlGenerator < Rails::Generator::Base
  include ActiveLdap::GetTextSupport

  def initialize(*args)
    duped_args = args.collect {|arg| arg.dup}
    super
    logger.warning(_("scaffold_al is deprecated. " \
                     "Use scaffold_active_ldap instead."))
    generator_class = self.class.lookup("scaffold_active_ldap").klass
    @generator = generator_class.new(duped_args)
  end

  def manifest
    @generator.manifest
  end

  def source_path(*args)
    @generator.source_path(*args)
  end
end

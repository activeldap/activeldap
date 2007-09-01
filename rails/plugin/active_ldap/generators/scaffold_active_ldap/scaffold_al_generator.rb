class ScaffoldAlGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.template("ldap.yml", File.join("config", "ldap.yml"))
    end
  end
end

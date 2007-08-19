# -*- ruby -*-

desc "Update *.po/*.pot files and create *.mo from *.po files"
task :gettext => ["gettext:po:update", "gettext:mo:create"]

namespace :gettext do
  namespace :environment do
    desc "Setup environment for GetText"
    task :setup => :environment do
      require "gettext/utils"
    end
  end

  namespace :po do
    desc "Update po/pot files (GetText)"
    task :update => "gettext:environment:setup" do
      require 'active_ldap/get_text/parser'
      options = {
        # :extract_schema => true, # use this if you have any extra schema.
      }
      GetText::RGetText.add_parser(ActiveLdap::GetText::Parser.new(options))

      files = Dir.glob("{app,lib,components}/**/*.{rb,rhtml,rxml}")
      GetText.update_pofiles("al-admin", files,
                             "AL Admin #{ActiveLdap::VERSION}")
    end
  end

  namespace :mo do
    desc "Create *.mo from *.po (GetText)"
    task :create => "gettext:environment:setup" do
      GetText.create_mofiles(false, 'po', 'locale')
    end
  end
end

class DirectoryController < ApplicationController
  before_filter :login_required, :except => [:populate]
  before_filter :empty_entries_required, :only => [:populate]

  def index
    @entries = Entry.search(:limit => 10)
  end

  def populate
    ActiveLdap::Populate.ensure_base
    ActiveLdap::Populate.ensure_ou(LdapUser.prefix)
  end

  private
  def empty_entries_required
    return true if Entry.empty?

    flash.now[:notice] = _("Populating is only for initialization")
    redirect_to(top_url)
    false
  end
end

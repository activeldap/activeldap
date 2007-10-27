class DirectoryController < ApplicationController
  before_filter :login_required, :except => [:populate]
  before_filter :empty_entries_required, :only => [:populate]

  verify :xhr => true, :only => [:entry],
         :render => {:text => "Bad Request", :status => 400}

  def index
    @root = Entry.root(find_options)
  end

  def entry
    dn = params[:dn]
    if Entry.base == dn
      @entry = Entry.root(find_options)
    else
      @entry = Entry.find(dn, find_options)
    end
    render(:partial => "entry", :object => @entry)
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

  def find_options
    {:connection => current_user.ldap_connection}
  end

  def access_denied
    if action_name == "entry"
      render(:text => "Unauthorized", :status => 401)
    else
      super
    end
  end
end

module UsersHelper
  include ObjectClassesHelper

  def user_link(user, with_edit=false)
    user_link_if(true, user, with_edit)
  end

  def user_link_if(condition, user, with_edit=false)
    result = link_to_if(condition, h(user.short_dn),
                        :action => "show", :id => user)
    if with_edit and current_user and current_user.ldap_user == user
      edit_link = link_to(_('Edit'), :action => 'edit', :id => user)
      result << "\n(#{edit_link})"
    end
    result
  end
end

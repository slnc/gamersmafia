class AdministrationController < ApplicationController
  before_filter :require_auth_admin_permissions
  
  def submenu_items
    [] # admin_menu_items
  end
  
  def wmenu_pos
    'hq'
  end
end

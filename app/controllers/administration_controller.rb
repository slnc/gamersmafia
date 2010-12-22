class AdministrationController < ApplicationController
  before_filter :require_auth_admin_permissions
  
  def wmenu_pos
    'hq'
  end
end

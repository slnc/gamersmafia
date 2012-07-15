# -*- encoding : utf-8 -*-
class AdministrationController < ApplicationController
  before_filter :require_auth_admin_permissions

  def submenu_items
    []
  end
end

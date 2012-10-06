# -*- encoding : utf-8 -*-
class AdministrationController < ApplicationController

  before_filter do |c|
    raise AccessDenied if !(c.user && c.user.is_staff?)
  end

  def submenu_items
    []
  end
end

class Admin::MotorController < ApplicationController
  require_admin_permission :hq

  def wmenu_pos
    'hq'
  end

  def index
    navpath2<< ['Admin', '/admin']
  end
end

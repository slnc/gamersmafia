class Admin::MotorController < ApplicationController
  require_admin_permission :hq

  def index
    navpath2<< ['Admin', '/admin']
  end
end

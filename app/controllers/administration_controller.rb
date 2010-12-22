class AdministrationController < ApplicationController
  before_filter :require_auth_admin_permissions
end

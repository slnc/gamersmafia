# Load the rails application
require File.expand_path('../application', __FILE__)
Gamersmafia::Application.configure do
  # TODO(slnc): rails3 find the right way to do this and re-enable
  # config.action_controller.ip_spoofing_check = false
end

# Initialize the rails application
Gamersmafia::Application.initialize!


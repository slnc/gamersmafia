# -*- encoding : utf-8 -*-
def assert_script_exit_status(script_name, exit_status=0)
  load "#{Rails.root}/script/#{script_name}.rb"
end

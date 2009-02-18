def assert_script_exit_status(script_name, exit_status=0)
  load "#{RAILS_ROOT}/script/#{script_name}.rb"
end

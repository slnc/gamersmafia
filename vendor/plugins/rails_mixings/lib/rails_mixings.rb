if File.exists?("#{RAILS_ROOT}/config/initializers/pre_plugins.rb")
  require "#{RAILS_ROOT}/config/initializers/pre_plugins.rb"
end

require 'active_record_mixings.rb'
ActiveRecord::Base.send :include, ActiveRecordMixings

require 'action_view_mixings.rb'
ActionView::Base.send :include, ActionViewMixings

require 'action_controller_mixings.rb'
ActionController::Base.send :include, ActionControllerMixings

begin
  User
rescue Exception
else
  require 'user_mixings.rb'
  User.send :include, UserMixings
  
%w(
ab_test  
action_mailer
friendship
geolocation
notification_mixings
silenced_email
stats_mixings  
).each do |f|
    require "#{File.dirname(__FILE__)}/#{f}.rb"
  end
  
  # $:.unshift "#{File.dirname(__FILE__)}/lib"
end

begin
  Notification
rescue Exception
else
  Notification.send :include, NotificationMixings
end

begin 
  Stats
rescue Exception
else
    Stats::Goals.send :include, StatsMixings::GoalsMixings
end

# require 'test_unit_mixings'

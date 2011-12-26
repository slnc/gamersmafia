Rails.env='production' unless defined?(Rails.env)
namespace :gm do
  desc "Spawn a delayed job worker"
  task :spawn_worker => :environment do
    ActiveRecord::Base.establish_connection
    Process.fork { Delayed::Worker.new(:quiet => !App.debug).start }
  end
end

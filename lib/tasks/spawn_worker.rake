RAILS_ENV='production' unless defined?(RAILS_ENV)
namespace :gm do
  desc "Spawn a delayed job worker"
  task :spawn_worker => :environment do
    ActiveRecord::Base.establish_connection
    Process.fork { Delayed::Worker.new.start }
  end
end

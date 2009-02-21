namespace :gm do
  desc "Spawn a delayed job worker"
  task :spawn_worker => :environment do
    Process.fork { Delayed::Worker.new.start }
  end
end

namespace :gm do
  desc "Launch iRC bot"
  task :alariko do
    Rake::Task['gm:alariko:stop']
    Rails.env='production' unless defined?(Rails.env)
    # system("#{Rails.root}/script/alariko.py")
  end

  namespace :alariko do
    task :stop do
      pidfile = "#{Rails.root}/tmp/pids/alariko.pid"
      if File.exists?(pidfile)
      	pid = File.open(pidfile).read()
      	`kill -9 #{pid}`
      	File.unlink(pidfile)
      else
        `pkill -9 -f "python alariko.py"` # just in case
      end
    end
  end
end

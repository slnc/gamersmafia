RAILS_ENV='production' unless defined?(RAILS_ENV)
namespace :gm do
  desc "Launch iRC bot"
  task :alariko do
    Rake::Task['gm:alariko:stop']
    # system("#{RAILS_ROOT}/script/alariko.py")
  end

  namespace :alariko do
    task :stop do
      pidfile = "#{RAILS_ROOT}/tmp/pids/alariko.pid"
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

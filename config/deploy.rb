set :application, "Gamersmafia"
set :repository,  "ssh://git@balrog.slnc.net:62331/gamersmafia"
set :user, 'slnc'
set :use_sudo, false

set :deploy_to, "/home/httpd/websites/gamersmafia"
set :deploy_via, :remote_cache
set :scm, :git
set :scm_username, 'git'
set :scm_command, '/usr/local/hosting/bin/git'
set :git_enable_submodules, 1
set :branch, 'production'

role :app, "httpd@kenpachi.gamersmafia.com:62331"
role :web, "httpd@kenpachi.gamersmafia.com:62331"
role :db,  "httpd@kenpachi.gamersmafia.com:62331", :primary => true

default_environment['PATH'] = '/bin:/usr/bin:/usr/local/bin:/usr/local/hosting/bin'
default_environment['RAILS_ENV'] = 'production'

SHARED_DIRS = [
['public/storage', 'system/storage'],
['public/cache', 'system/cache'],
['tmp/fragment_cache', 'system/fragment_cache'],
['tmp/sessions', 'sessions'],
]

namespace(:customs) do
  task :symlink, :roles => :app do
    SHARED_DIRS.each do |dinfo|
      run <<-CMD
       rm -rf #{release_path}/#{dinfo[0]} &&
       ln -s #{shared_path}/#{dinfo[1]} #{release_path}/#{dinfo[0]}
     CMD
    end
  end
  
  task :updated_app, :roles => :app do
    run "cd #{release_path} && echo 'production' > config/mode && ./script/update.py"
    run "cd #{release_path} && nohup rake gm:alariko & "
  end
  
  task :setup, :roles => :app do
    SHARED_DIRS.each do |dinfo|
      run "mkdir #{shared_path}/#{dinfo[1]}"
    end
  end
  
  task :check_clean_wc, :roles => :app do
    begin
      current_path
    rescue # first deployment
    else
      begin
        run "if [ -d #{current_path} ]; then cd #{current_path} && ./script/check_clean_wc.sh; fi"
      rescue
        puts "\n\tERROR: production has dirty wc!\n\n"
        raise
      end
    end    
  end
end

before "deploy:update","customs:check_clean_wc"
after "deploy:update","customs:updated_app"
after "deploy:setup","customs:setup"
after "deploy:symlink","customs:symlink"
#after "deploy:migrations","customs:updated_app"
# Hasta que no esté seguro de que funciona bien el nuevo sistema de 
# comprobación de wc antes de updatear no activo esto:
#after "deploy", "deploy:cleanup"

# monkey patch para no hacer un touch a los assets ya que no hacemos uso de ello
namespace :deploy do
  task :finalize_update, :except => { :no_release => true } do 
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    
    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    run <<-CMD
       rm -rf #{latest_release}/log #{latest_release}/tmp/pids &&
       mkdir -p #{latest_release}/public &&
       mkdir -p #{latest_release}/tmp &&
       ln -s #{shared_path}/log #{latest_release}/log &&
       ln -s #{shared_path}/pids #{latest_release}/tmp/pids
     CMD
  end 
end

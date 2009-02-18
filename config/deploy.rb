set :application, "gamersmafia.com"
set :repository,  "svn+ssh://slnc@hq.gamersmafia.com/home/slnc/svn/gamersmafia/trunk"
set :deploy_to, "/home/httpd/websites/#{application}"
set :shared_dir, "#{deploy_to}/shared"
set :use_sudo, false



role :app, "httpd@gamersmafia.com:62331"
role :web, "httpd@gamersmafia.com:62331"
role :db,  "httpd@gamersmafia.com:62331", :primary => true

default_environment['PATH'] = '/bin:/usr/bin:/usr/local/bin:/usr/local/hosting/bin'
default_environment['SVN_SSH'] = 'ssh -p 62331 -l slnc'
default_environment['RAILS_ENV'] = 'production'
#default_environment['RAILS_ROOT'] = "#{current_path}"

after "deploy:setup" do
  run "mkdir -m 777 #{shared_dir}/system/cache"
  run "mkdir -m 777 #{shared_dir}/system/storage"
  run "mkdir -m 777 #{shared_dir}/system/fragment_cache"
  run "mkdir -m 777 #{shared_dir}/system/sessions"
end

# symlink, shared
SHARED_DIRS = [
['log', 'log'],
['public/storage', 'system/storage'],
['public/cache', 'system/cache'],
['tmp/fragment_cache', 'system/fragment_cache'],
['tmp/sessions', 'sessions'],
]

namespace :deploy do
  desc "This will deploy the app"
  task :update_code do
    # Para acelerar hacemos una copia de la versión actual y luego svn up en lugar de svn export
    run "cp -rP `readlink #{current_path}` #{release_path}"

    SHARED_DIRS.each do |dinfo|
      dir = "#{release_path}/#{dinfo[0]}"
      # Nos aseguramos de que no borramos los directorios reales borrando
      # primero symlink y luego los directorios vacíos
      run "if [ -h #{dir} ]; then rm #{dir}; fi"
    end

    run "svn up --quiet #{release_path}"

    SHARED_DIRS.each do |dinfo|
      dir = "#{release_path}/#{dinfo[0]}"
      # Nos aseguramos de que no borramos los directorios reales borrando
      # primero symlink y luego los directorios vacíos
      run "if [ -d #{dir} ]; then rm -rf #{dir}; fi"
      run "ln -s #{shared_dir}/#{dinfo[1]} #{dir}"
    end
    
    run "ln -nfs #{release_path} #{current_path}"
    run "cd #{release_path} && ./update.py"
  end
end

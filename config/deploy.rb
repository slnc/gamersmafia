# -*- encoding : utf-8 -*-
set :application, "Gamersmafia"
set :repository,  "git://github.com/gamersmafia/gamersmafia.git"
set :user, 'httpd'
set :use_sudo, false
set :keep_releases, 5

set :deploy_to, "/srv/www/gamersmafia"
set :deploy_via, :remote_cache
set :scm, :git
set :scm_username, 'git'
# set :scm_command, '/usr/local/hosting/bin/git'
# set :git_enable_submodules, 1
set :branch, 'master'

SSH_PATH_TO_HOST = "httpd@gamersmafia.com:62331"

role :app, SSH_PATH_TO_HOST
role :web, SSH_PATH_TO_HOST
role :db, SSH_PATH_TO_HOST, :primary => true

default_environment['RAILS_ENV'] = 'production'

SHARED_DIRS = [
  ['public/storage', 'system/storage'],
  ['public/cache', 'system/cache'],
  ['tmp/fragment_cache', 'system/fragment_cache']
]

namespace(:customs) do
  task :symlink, :roles => :app do
    SHARED_DIRS.each do |dinfo|
      run <<-CMD
       ln -s #{shared_path}/#{dinfo[1]} #{release_path}/#{dinfo[0]}
     CMD
    end
  end

  task :updated_app, :roles => :app do
    tag_release
    run "ln -s #{shared_path}/system/app_production.yml #{release_path}/config/app_production.yml"
    run "cd #{release_path} && echo 'production' > config/mode && rake gm:after_deploy"
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
        raise "\n\tERROR: production has dirty wc!\n\n"
      end
    end
  end
end

# Creates a new tag
def tag_release
  # Determine tag name to create
  `git fetch --tags`
  all_tags = `git tag | grep release`.strip.split("\n")
  tag_prefix = "release-#{Time.now.strftime("%Y%m%d")}"
  daily_id = all_tags.count {|item| item.include?(tag_prefix)}
  padded_id = "%02d" % (daily_id + 1)
  new_tag = "#{tag_prefix}-#{padded_id}"

  `git tag -a -m #{new_tag} #{new_tag}`
  `git push --tags`

  # TODO(juanalonso): cleanup old tags
end

before "deploy:update","customs:check_clean_wc"
after "deploy:update","customs:updated_app"
after "deploy:setup","customs:setup"
after "deploy:symlink","customs:symlink"
after "deploy:restart", "deploy:cleanup"

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

  # passenger
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end

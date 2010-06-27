require 'ostruct'
require 'yaml'

# Esto es un initializer pero necesitamos tenerlo cargado en config/environment.rb
# porque hacemos uso de App. Por lo que necesitamos evitar que se ejecute 2 veces.
if !defined?(::App)
  
  LINUX = 0
  WINDOWS = 1
  
  # load custom config
  mode = File.exists?("#{RAILS_ROOT}/config/mode") ? File.open("#{RAILS_ROOT}/config/mode").read.strip : 'doll2'
  mode = 'test' if RAILS_ENV == 'test'
  require 'action_mailer'

  if mode != 'production'
    ActionMailer::Base.perform_deliveries = false
  end

  default_appyml = "#{RAILS_ROOT}/config/app.yml"
  production_appyml = "#{RAILS_ROOT}/config/app_production.yml"
  appyml = File.exists?(production_appyml) ? production_appyml : default_appyml  
  nconfig = OpenStruct.new(YAML::load(ERB.new((IO.read(appyml))).result))
  env_config = nconfig.send(mode)
  ::App = OpenStruct.new(env_config)
  
  module AppR
    def self.ondisk_git_version
      @_cache_v  ||= begin
        v = File.exists?("#{RAILS_ROOT}/config/REVISION") ? File.open("#{RAILS_ROOT}/config/REVISION").read.strip[0..6] : 'HEAD'
        # esto es necesario porque en bamboo peta si no
        begin
          ActiveRecord::Base.db_query("UPDATE global_vars set svn_revision = '#{v}'")
        rescue
        end 
        v
      end
    end
  end
end

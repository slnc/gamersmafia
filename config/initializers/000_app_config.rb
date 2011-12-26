require 'ostruct'
require 'yaml'

# Esto es un initializer pero necesitamos tenerlo cargado en config/environment.rb
# porque hacemos uso de App. Por lo que necesitamos evitar que se ejecute 2 veces.
if !defined?(::App)
  LINUX = 0
  WINDOWS = 1
  
  # load custom config
  mode = File.exists?("#{Rails.root}/config/mode") ? File.open("#{Rails.root}/config/mode").read.strip : 'development'
  mode = 'test' if Rails.env == 'test'
  require 'action_mailer'

  if mode != 'production'
    ActionMailer::Base.perform_deliveries = false
  end

  default_appyml = "#{Rails.root}/config/app.yml"
  production_appyml = "#{Rails.root}/config/app_production.yml"
  appyml = File.open(default_appyml).read
  appyml<< "\n#{File.open(production_appyml).read}" if File.exists?(production_appyml)
  #appyml = File.exists?(production_appyml) ? production_appyml : default_appyml  
  nconfig = OpenStruct.new(YAML::load(ERB.new(appyml).result))
  env_config = nconfig.send(mode)
  raise "Mode '#{mode}' is not present on app.yml" unless env_config
  ::App = OpenStruct.new(env_config)
  
  ASSET_URL = "http://#{App.asset_domain}#{':' << App.port.to_s if App.port != 80}"
  COOKIEDOMAIN = ".#{App.domain}"
  FRAGMENT_CACHE_PATH = "#{Rails.root}/tmp/fragment_cache"
  
  module AppR
    def self.ondisk_git_version
      @_cache_v  ||= begin
        v = File.exists?("#{Rails.root}/config/REVISION") ? File.open("#{Rails.root}/config/REVISION").read.strip[0..6] : 'HEAD'
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

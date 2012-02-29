require 'ostruct'
require 'yaml'

if !defined?(::App)
  mode_file = "#{Rails.root}/config/mode"

  if Rails.env == "test"
    mode = "test"
  elsif File.exists?(mode_file)
    mode = File.open(mode_file).read.strip
  else
    mode = "development"
  end

  require 'action_mailer'
  ActionMailer::Base.perform_deliveries = (mode == 'production')

  default_appyml = "#{Rails.root}/config/app.yml"
  production_appyml = "#{Rails.root}/config/app_production.yml"
  appyml = File.open(default_appyml).read
  appyml<< "\n#{File.open(production_appyml).read}" if File.exists?(production_appyml)
  nconfig = OpenStruct.new(YAML::load(ERB.new(appyml).result))
  env_config = nconfig.send(mode)
  raise "Mode '#{mode}' is not present on app.yml" unless env_config

  ::App = OpenStruct.new(env_config)

  # Constants
  # TODO(slnc): cambiar referencias a ASSET_URL por App.asset_url
  ASSET_URL = App.asset_url
  COOKIEDOMAIN = ".#{App.domain}"
  FRAGMENT_CACHE_PATH = "#{Rails.root}/tmp/fragment_cache"
end

# -*- encoding : utf-8 -*-
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
  if mode == 'development'
    ActionMailer::Base.perform_deliveries = false
  end

  default_appyml = "#{Rails.root}/config/app.yml"
  production_appyml = "#{Rails.root}/config/app_production.yml"
  appyml = File.open(default_appyml).read
  if File.exists?(production_appyml)
    appyml<< "\n#{File.open(production_appyml).read}"
  end
  nconfig = OpenStruct.new(YAML::load(ERB.new(appyml).result))
  env_config = nconfig.send(mode)
  raise "Mode '#{mode}' is not present on app.yml" unless env_config

  ::App = OpenStruct.new(env_config)

  # Constants
  # TODO(slnc): cambiar referencias a ASSET_URL por App.asset_url
  ASSET_URL = App.asset_url
  COOKIEDOMAIN = ".#{App.domain}"
  FRAGMENT_CACHE_PATH = "#{Rails.root}/tmp/fragment_cache"

  if !Dir.exists?("#{Rails.root}/tmp/scraping")
    Dir.mkdir("#{Rails.root}/tmp/scraping")
  end
end

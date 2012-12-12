# -*- encoding : utf-8 -*-
require File.expand_path('../boot', __FILE__)

require 'rails/all'

require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/datefileoutputter'
include Log4r

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line

  # Esta línea es mágica. Por lo que más quieras, no la elimines o los plugins
  # no cargarán bien.
  Bundler.require(*Rails.groups(:assets => %w(development test)))

  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Gamersmafia
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{RAILS_ROOT}/extras )

    require 'erb'
    load 'config/initializers/000_app_config.rb'

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Skip frameworks you're not going to use. To use Rails without a database,
    # you must remove the Active Record framework.
    # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
    config.encoding = "utf-8"

    # config.dependency_loading = true if $rails_rake_task
    config.action_dispatch.ignore_accept_header = true

    config.filter_parameters += [:password]

    config.autoload_paths << File.join(config.root, 'lib')

    config.assets.enabled = true

    config.assets.version = '1.0'

    config.cache_store = :mem_cache_store
    #config.cache_store  = :file_store, FRAGMENT_CACHE_PATH

    # Activate observers that should always be running
    config.active_record.observers = [
      :achmed_observer,
      :cache_observer,
      :karma_observer,
      :notification_observer,
      :users_action_observer,
      :user_emblem_observer,
    ]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names.
    config.time_zone = 'Europe/Madrid'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
    # config.i18n.default_locale = :de

    # Assign log4r's logger as rails' logger.
    log4r_config= YAML.load_file(File.join(File.dirname(__FILE__),"log4r.yml"))
    YamlConfigurator.decode_yaml(log4r_config['log4r_config'])
    config.logger = Log4r::Logger[App.log_env]

    # Disable auto explains
    config.active_record.auto_explain_threshold_in_seconds = nil

    # Disable ip spoofing as it gives too many false positives
    config.action_dispatch.ip_spoofing_check = false

    config.session_store(:cookie_store,
        :key => 'adn2', :domain => ".#{App.domain}")

    config.secret_token = App.session_secret

    config.active_record.schema_format = :sql
  end
end

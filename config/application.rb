#require `gem which memprof/signal`.chomp

require File.expand_path('../boot', __FILE__)

require 'rails/all'

require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/datefileoutputter'
include Log4r

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  # Bundler.require(*Rails.groups(:assets => %w(development test)))
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

    # Specify gems that this application depends on and have them installed with rake gems:install
    #config.gem 'postgres'
    #config.gem 'ci_reporter'
    #config.gem 'feedtools', :lib => 'feed_tools'
    #config.gem 'feedvalidator', :lib => 'feed_validator'

    #config.gem 'geoip'
    #config.gem 'gruff'
    #config.gem 'rmagick', :lib => 'RMagick'
    #config.gem 'tidy'

    # TODO(slnc): this shouldn't be here anymore
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

    config.filter_parameters += [:password]

    config.autoload_paths << File.join(config.root, 'lib')

    config.assets.enabled = false

    config.assets.version = '1.0'

    config.action_controller.cache_store = :file_store,
                                           "#{Rails.root}/tmp/fragment_cache"

    # Activate observers that should always be running
    config.active_record.observers = [
      :cache_observer,
      :faith_observer,
      :users_action_observer,
      :achmed_observer,
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

    config.cache_store  = :file_store, FRAGMENT_CACHE_PATH
  end
end

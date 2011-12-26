# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.10' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{Rails.root}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  #config.gem 'postgres'
  #config.gem 'ci_reporter'
  #config.gem 'feedtools', :lib => 'feed_tools'
  #config.gem 'feedvalidator', :lib => 'feed_validator'

  config.gem 'geoip'
  config.gem 'gruff'
  config.gem 'rmagick', :lib => 'RMagick'
  config.gem 'tidy'

  require 'erb'
  require 'config/initializers/000_app_config.rb'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  config.action_controller.cache_store = :file_store, "#{Rails.root}/tmp/fragment_cache"

  # Activate observers that should always be running
  config.active_record.observers = :cache_observer, :faith_observer, :users_action_observer, :achmed_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  # config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

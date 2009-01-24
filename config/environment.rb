RAILS_GEM_VERSION = '2.1.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

FRAGMENT_CACHE_PATH = "#{RAILS_ROOT}/tmp/fragment_cache"
Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]
  
  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  
  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug
  
  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  # config.action_controller.session_store = :active_record_store
  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  # TODO reactivar cookie session
  #puts config.action_controller.session_store
  #config.action_controller.session_store = :p_store
  #puts config.action_controller.session_store
  #config.action_controller.session = {
  #  :session_key => '_gms',
  #  :secret      => '1b61f4237e00a91b8b0d1cc359f74e79f71acf535510512d1b155bed7e323b06fdd5f7c7d08ee7b0f71d1d4159eccc164995c0619a7d8bf553952bc36e49e883'
  #}
  
  config.action_controller.session_store = :p_store
  
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql
  
  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  config.action_controller.cache_store = :file_store, FRAGMENT_CACHE_PATH
  config.action_controller.session = { 
    :session_key => "adn2", 
    :secret => "2595bb97b561a0311a2766ec174265f48ec10a58ef4091c4d621b74b92247b02aff39f9c67146b003ff2ea6a963ac69b758af0d6942e3c36cbf771775e6a2d85" 
  }
  
  config.action_controller.cache_store = :file_store, FRAGMENT_CACHE_PATH
  
  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  # config.active_record.observers = :cache_observer, :faith_observer # comment_observer, :cache_observer
  
  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  # config.plugins = [:file_column, :all]
end
ActionController::Base.cache_store = :file_store, FRAGMENT_CACHE_PATH
#ActionController::Base.session_store = :p_store
require File.join(File.dirname(__FILE__), 'app_config')
require 'vendor/plugins/rails_mixings/lib/action_controller.rb'
require 'vendor/plugins/rails_mixings/lib/action_mailer.rb'
require 'vendor/plugins/rails_mixings/lib/notification.rb'
# require 'vendor/plugins/rails_mixings/lib/friendship.rb'

ASSET_URL = "http://#{App.asset_domain}"
COOKIEDOMAIN = ".#{App.domain}"

REPLICATION_CLUSTER = 'gamersmafia'
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:session_domain] = ".#{App.domain}" # unless ENV['RAILS_ENV'] == 'test'
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:session_key] = "adn2" # unless ENV['RAILS_ENV'] == 'test'
# ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:secret] = "watashi ha kanachan daisuki dayou"

class Dbs < ActiveRecord::Base; end

if App.enable_support_db? && RAILS_ENV != 'test'
  abcs = ActiveRecord::Base.configurations
  Dbs.establish_connection( :adapter  => abcs['support']['adapter'],
  :host     => abcs['support']['host'],
  :username => abcs['support']['username'],
  :password => abcs['support']['password'],
  :database => abcs['support']['database']
  )
end
User.connection.client_min_messages = 'warning'
Dbs.connection.client_min_messages = 'warning'

ActionMailer::Base.smtp_settings = {
  :address  => "mail.gamersmafia.com",
  :port  => 25, 
  :domain  => "gamersmafia.com",
  :user_name  => "nagato.gamersmafia.com",
  :password  => 'megustanlasgalletas',
  :authentication  => :login
} 

# if App.enable_dbstats? then
#if nil 
module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      protected
      def log(sql, name)
        if block_given?
          # RSI: changed to get DB statistics in log file at info level
          # if @logger and @logger.debug?
          if @logger and @logger.level <= Logger::INFO
            result = nil
            seconds = Benchmark.realtime { result = yield }
            @runtime += seconds
            log_info(sql, name, seconds)
            result
          else
            yield
          end
        else
          log_info(sql, name, 0)
          nil
        end
      rescue Exception => e
        # Log message and raise exception.
        # Set last_verification to 0, so that connection gets verified
        # upon reentering the request loop
        @last_verification = 0
        message = "#{e.class.name}: #{e.message}: #{sql}"
        log_info(message, name, 0)
        raise ActiveRecord::StatementInvalid, message
      end
    end
  end
end


ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.module_eval do
  @@stats_queries = @@stats_bytes = @@stats_rows = 0
  def self.get_stats
    { :queries => @@stats_queries,
      :rows => @@stats_rows,
      :bytes => @@stats_bytes }
  end
  def self.reset_stats
    @@stats_queries = @@stats_bytes = @@stats_rows = 0
  end
  
  def select_with_stats(sql, name)
    bytes = 0
    rows = select_without_stats(sql, name)
    if App.enable_dbstats? then
      rows.each do |row|
        row.each do |key, value|
          bytes += key.length
          bytes += value.length if value
        end
      end
      @@stats_bytes += bytes
    end
    @@stats_rows += rows.length
    @@stats_queries += 1
    rows
  end
  alias_method_chain :select, :stats
end


ActionController::Base.module_eval do
  def perform_action_with_reset
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::reset_stats
    #ActiveRecord::ConnectionAdapters::QueryCache::reset_stats
    perform_action_without_reset
  end
  
  alias_method_chain :perform_action, :reset
  
  def active_record_runtime(runtime)
    stats = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::get_stats
      "#{super} #{sprintf("%.1fk", stats[:bytes].to_f / 1024)} queries: #{stats[:queries]}"
end
end
#end

require 'app/controllers/application.rb'
User
require 'vendor/plugins/rails_mixings/lib/user.rb'

FRAGMENT_CACHE_PATH = "#{RAILS_ROOT}/tmp/fragment_cache"
ActionController::Base.cache_store = :file_store, FRAGMENT_CACHE_PATH
#ActionController::Base.session_store = :p_store
# require File.join(File.dirname(__FILE__), 'app_config')
#require 'vendor/plugins/rails_mixings/lib/action_controller.rb'
#require 'vendor/plugins/rails_mixings/lib/action_mailer.rb'
#require 'vendor/plugins/rails_mixings/lib/notification.rb'
# require 'vendor/plugins/rails_mixings/lib/friendship.rb'

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
# TODO copypaste de environment de GM
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
    perform_action_without_reset
  end
  
  alias_method_chain :perform_action, :reset
  
  def active_record_runtime
    stats = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::get_stats
      "#{super} #{sprintf("%.1fk", stats[:bytes].to_f / 1024)} queries: #{stats[:queries]}"
  end
end
#end

# require File.join(File.dirname(__FILE__), '../app_config')

ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:prefix => 'gm.')
SVNVERSION = AppR.ondisk_git_version

# NOTA: el orden importa
#require 'category_acting'

ActiveRecord::Base.send :include, HasHid
ActiveRecord::Base.send :include, HasSlug

# NOTA: los observers DEBEN ser los últimos para que se puedan cargar los contenidos de lib/ y plugins
TIMEZONE = '+0100'

FileUtils.mkdir_p("#{RAILS_ROOT}/public/storage/skins") unless File.exists?("#{RAILS_ROOT}/public/storage/skins")
ActiveRecord::Base.partial_updates = false if ActiveRecord::Base.respond_to?(:partial_updates) 

raise "libtidy not found" unless File.exists?(App.tidy_path)

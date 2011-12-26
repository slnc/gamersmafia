OPENURI_HEADERS = {
                    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                    'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                    'Accept-Encoding' => '',
                    'Accept-Language' => 'en-us,en;q=0.5',
                    'Connection' => 'keep-alive',
                    'Keep-Alive' => '300',
                    'User-Agent' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.1.4) Gecko/20091016 Firefox/3.5.4'
}

User.connection.client_min_messages = 'warning'

ActionMailer::Base.smtp_settings = {
  :address  => "mail.gamersmafia.com",
  :port  => 25,
  :domain  => "gamersmafia.com",
  :user_name  => "nagato.gamersmafia.com",
  :password  => 'megustanlasgalletas',
  :authentication  => :login
}

# if App.enable_dbstats? then
if nil
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

ActionController::Base.cache_store = :file_store, FRAGMENT_CACHE_PATH
# TODO(slnc): rails3 commented out
#ActionController::Base.module_eval do
#  def perform_action_with_reset
#    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::reset_stats
#    perform_action_without_reset
#  end
#
#  alias_method_chain :perform_action, :reset
#
#  def active_record_runtime
#    stats = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::get_stats
#    "#{super} #{sprintf("%.1fk", stats[:bytes].to_f / 1024)} queries: #{stats[:queries]}"
#  end
#end
end

# TODO(slnc): rails3 commented out
# ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:prefix => 'gm.')
ActiveRecord::Base.partial_updates = false if ActiveRecord::Base.respond_to?(:partial_updates)
SVNVERSION = AppR.ondisk_git_version
TIMEZONE = '+0100'

FileUtils.mkdir_p("#{Rails.root}/public/storage/skins") unless File.exists?("#{Rails.root}/public/storage/skins")

# NOTA: el orden importa
require 'has_hid'
ActiveRecord::Base.send :include, HasHid

# NOTA: los observers DEBEN ser los últimos para que se puedan cargar los contenidos de lib/ y plugins

raise "libtidy not found" unless File.exists?(App.tidy_path)

module ActionController::Caching::Fragments
  # Quitamos views/ de las keys
  def fragment_cache_key(key)
    ActiveSupport::Cache.expand_cache_key(key.is_a?(Hash) ? url_for(key).split("://").last : key, '')
  end
end

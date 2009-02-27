require File.join(File.dirname(__FILE__), '../app_config')

# Include your application configuration below
if App.windows?
  ActionMailer::Base.delivery_method = :test # smtp
  ActionMailer::Base.smtp_settings[:address] = 'dharana.net'
else
  ActionMailer::Base.delivery_method = :sendmail
end

ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:prefix => 'gm.')
SVNVERSION = AppR.ondisk_svn_version

# NOTA: el orden importa
require 'category_acting'
require 'acts_as_categorizable'
require 'acts_as_content'
require 'acts_as_content_browser'
require 'overload_remote_ip'
require 'all'
require 'cms'
require 'bank'
require 'gmstats'
require 'skins'
require 'bandit'
require 'ads'
require 'vendor/plugins/rails_mixings/lib/stats.rb'
require 'lib/stats.rb'

ActiveRecord::Base.send :include, HasHid
ActiveRecord::Base.send :include, HasSlug
User.db_query("SELECT now()")

# NOTA: los observers DEBEN ser los últimos para que se puedan cargar los contenidos de lib/ y plugins
CacheObserver.instance
FaithObserver.instance
UsersActionObserver.instance

TIMEZONE = '+0100'

FileUtils.mkdir("#{RAILS_ROOT}/public/storage/skins") unless File.exists?("#{RAILS_ROOT}/public/storage/skins")
ActiveRecord::Base.partial_updates = false if ActiveRecord::Base.respond_to?(:partial_updates) 

raise "libtidy not found" unless File.exists?(App.tidy_path)

module Inflector
  def self.sexualize(word, sex)
    if sex == User::FEMALE
      word.gsub(/(o)$/, 'a')
    else
      word
    end
  end
end
require File.join(File.dirname(__FILE__), '../app_config')

# Include your application configuration below
if App.windows?
  ActionMailer::Base.delivery_method = :test # smtp
  ActionMailer::Base.smtp_settings[:address] = 'dharana.net'
else
  ActionMailer::Base.delivery_method = :sendmail
end

ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:prefix => 'gm.')
SVNVERSION = AppR.ondisk_git_version

# NOTA: el orden importa
#require 'category_acting'

ActiveRecord::Base.send :include, HasHid
ActiveRecord::Base.send :include, HasSlug
User.db_query("SELECT now()")

# NOTA: los observers DEBEN ser los últimos para que se puedan cargar los contenidos de lib/ y plugins
TIMEZONE = '+0100'

FileUtils.mkdir_p("#{RAILS_ROOT}/public/storage/skins") unless File.exists?("#{RAILS_ROOT}/public/storage/skins")
ActiveRecord::Base.partial_updates = false if ActiveRecord::Base.respond_to?(:partial_updates) 

raise "libtidy not found" unless File.exists?(App.tidy_path)
ActionView::Base.cache_template_loading = false if App.mode != 'production'

module ActiveSupport::Inflector
  def self.sexualize(word, sex)
    if sex == User::FEMALE
      word.gsub(/(o)$/, 'a')
    else
      word
    end
  end
end

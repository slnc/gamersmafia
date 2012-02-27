puts Gem.loaded_specs.values.map {|x| "#{x.name} #{x.version}"}

#ActiveSupport.run_load_hooks(:active_record, ActiveRecord::Base)
#ActiveSupport.run_load_hooks(:action_controller, ActiveRecord::Base)

Rails.application.config.middleware.use ExceptionNotifier,
    :email_prefix => "[GM Error] ",
    :sender_address => %{"nagato" <nagato@gamersmafia.com>},
    :exception_recipients => [App.webmaster_email],
    :ignore_crawlers      => %w{Googlebot googlebot bingbot}

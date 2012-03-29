task :cruise do
  ENV['RAILS_ENV'] = 'test'

  if File.exists?(Dir.pwd + "/config/database.yml")
    # perform standard Rails database cleanup/preparation tasks if they are defined in project
    # this is necessary because there is no up-to-date development database on a continuous integration box
    if Rake.application.lookup('db:test:load')
      CruiseControl::invoke_rake_task 'db:test:load'
    elsif Rake.application.lookup('db:test:purge')
      CruiseControl::invoke_rake_task 'db:test:purge'
    end

    if Rake.application.lookup('db:migrate')
      CruiseControl::reconnect
      CruiseControl::invoke_rake_task 'db:migrate'
    end
  end

  # invoke 'test' or 'default' task
  if Rake.application.lookup('test')
    CruiseControl::invoke_rake_task 'test'
  elsif Rake.application.lookup('default')
    CruiseControl::invoke_rake_task 'default'
  else
    raise "'cruise', test' or 'default' tasks not found. CruiseControl doesn't know what to build."
  end
end

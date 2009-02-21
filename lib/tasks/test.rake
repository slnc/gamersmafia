require 'lib/redefine_task'

desc 'Test all units, functionals, plugins, scripts, libs, integration'
redefine_task :test do
  Rake::Task["test:units"].invoke rescue got_error = true
  Rake::Task["test:functionals"].invoke rescue got_error = true
  Rake::Task["test:helpers"].invoke rescue got_error = true
  Rake::Task["test:plugins"].invoke rescue got_error = true
  Rake::Task["test:integration"].invoke rescue got_error = true
  Rake::Task["test:libs"].invoke rescue got_error = true
  Rake::Task["test:scripts"].invoke rescue got_error = true
  Rake::Task["test:tasks"].invoke rescue got_error = true
  
  raise "Test failures" if got_error
end

namespace :test do
desc 'Test all units, functionals, plugins, scripts, libs, integration'
redefine_task :rcov do
  Rake::Task["test:all_single_go:rcov"].invoke rescue got_error = true
  # Rake::Task["test:functionals:rcov"].invoke rescue got_error = true
  # Rake::Task["test:helpers:rcov"].invoke rescue got_error = true
  # Rake::Task["test:plugins:rcov"].invoke rescue got_error = true
  # Rake::Task["test:integration:rcov"].invoke rescue got_error = true
  # Rake::Task["test:libs:rcov"].invoke rescue got_error = true
  # Rake::Task["test:scripts:rcov"].invoke rescue got_error = true
  # Rake::Task["test:tasks:rcov"].invoke rescue got_error = true
  
  raise "Test failures" if got_error
end

  desc "Lanza las tasks necesarias para ejecutar todos los tests en bamboo"
  task :bamboo_launch do
    raise "NO" unless `hostname`.strip == 'balrog'
    `rm -r #{RAILS_ROOT}/coverage/*` if File.exists?("#{RAILS_ROOT}/coverage")
    `rm -r #{RAILS_ROOT}/public/storage/*` if File.exists?("#{RAILS_ROOT}/public/storage")
    `git branch --track staging origin/staging`
    `git checkout staging`
    `git submodule init`
    `git submodule update`
    `git pull origin`
    Rake::Task['db:test:real_prepare'].invoke
    Rake::Task['gm:update_default_skin_styles'].invoke
    Rake::Task['ci:setup:testunit'].invoke
    Rake::Task['test:rcov'].invoke
  end
  
  desc "Sincroniza la base de datos de testing con el entorno actual de desarrollo"
  task :sync_from_development do
    Rake::Task['db:test:clone_structure'].invoke
    Rake::Task['db:fixtures:load2'].invoke
    Rake::Task['db:fixtures:load2'].invoke # Lo llamamos dos veces porque si no no se cargan bien
  end
  
  desc 'Test the lib stuff.'
  Rake::TestTask.new(:libs) do |t|
    t.libs << 'test'
    t.pattern = 'test/lib/**/*_test.rb'
    t.verbose = true
  end
  
  desc 'Test scripts tests'
  Rake::TestTask.new(:scripts) do |t|
    t.libs << 'test'
    t.pattern = 'test/scripts/*_test.rb'
    t.verbose = true
  end

  desc 'Test helpers tests'
  Rake::TestTask.new(:helpers) do |t|
    t.libs << 'test'
    t.pattern = 'test/helpers/**/*_test.rb'
    t.verbose = true
  end
  
  desc 'Test tasks tests'
  Rake::TestTask.new(:tasks) do |t|
    t.libs << 'test'
    t.pattern = 'test/tasks/*_test.rb'
    t.verbose = true
  end

  desc 'Test all in a single go'
  Rake::TestTask.new(:all_single_go) do |t|
    t.libs << 'test'
    # t.pattern = 'test/tasks/*_test.rb'
    t.test_files = FileList['test/tasks/*_test.rb', 
                            'test/unit/*_test.rb',
                            'test/functional/*_test.rb',
                            'test/functional/*/*_test.rb',
                            'test/integration/*_test.rb',
                            'vendor/plugins/*/*_test.rb',
                            'test/helpers/*_test.rb',
                            'test/scripts/*_test.rb',
                            'test/lib/**/*_test.rb',
                            'test/helpers/**/*_test.rb']
    t.verbose = true
  end
end

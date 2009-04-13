require 'lib/redefine_task'

desc 'Batería de tests por defecto'
redefine_task :test do
  RAILS_ENV = 'test'
  got_error = false
  %w(functionals helpers integration libs plugins scripts tasks units).each do |tpack|
    Rake::Task["test:#{tpack}"].invoke rescue got_error = true
  end
  
  raise "Test failures" if got_error
end

namespace :test do  
  desc 'Batería por defecto con rcov'
  redefine_task :rcov do
    Rake::Task["test:all_single_go:rcov"].invoke
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
    
    t.test_files = FileList['test/functional/*_test.rb',
                            'test/functional/*/*_test.rb',
                            'test/helpers/*_test.rb',
                            'test/helpers/**/*_test.rb',
                            'test/lib/**/*_test.rb',
                            'test/integration/*_test.rb',
                            'vendor/plugins/*/**/test/**/*_test.rb',
                            'test/scripts/*_test.rb',
                            'test/tasks/*_test.rb',
                            'test/unit/*_test.rb']
    t.verbose = true
  end
  
  # Lanza las tasks necesarias para ejecutar todos los tests en bamboo
  task :bamboo do
    Rake::Task['test:bamboo:init'].invoke
    Rake::Task['test'].invoke
  end
  
  namespace :bamboo do
    task :init do
      RAILS_ENV = 'test'
      raise "NO" unless `hostname`.strip == 'balrog'
      `rm -r #{RAILS_ROOT}/coverage/*` if File.exists?("#{RAILS_ROOT}/coverage")
      `rm -r #{RAILS_ROOT}/public/storage/*` if File.exists?("#{RAILS_ROOT}/public/storage")
      `rm -r #{RAILS_ROOT}/test/reports/*` if File.exists?("#{RAILS_ROOT}/test/reports")
      `git submodule init`
      `git submodule update`
      Rake::Task['db:test:real_prepare'].invoke
      Rake::Task['gm:update_default_skin_styles'].invoke
      Rake::Task['ci:setup:testunit'].invoke
    end
    
    namespace :plan do
      desc "Batería de tests ampliada (rcov, validación html/css/js, tamaño de html/css/js)"
      task :qa do
        Rake::Task['test:bamboo:init'].invoke
        Rake::Task['test:rcov'].invoke
      end
      
      desc "Batería de tests por defecto"
      task :default do
        Rake::Task['test:bamboo'].invoke
      end
      
      desc "Batería de tests de rendimiento"
      task :performance do
        Rake::Task['test:bamboo:init'].invoke
        raise "TODO"
      end
    end
  end
  
end

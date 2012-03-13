desc 'Batería de tests por defecto'
redefine_task :test => :environment do
  Rails.env = 'test'
  Rake::Task['db:fixtures:load2'].invoke
  got_error = false
  %w(functionals integration libs plugins scripts tasks units).each do |tpack|
    Rake::Task["test:#{tpack}"].invoke rescue got_error = true
  end

  raise "Test failures" if got_error
end

namespace :test do

  desc "Sincroniza la base de datos de testing con el entorno actual de desarrollo"
  task :sync_from_development do
    Rake::Task['db:test:clone_structure'].invoke
    Rake::Task['db:fixtures:load2'].invoke
    Rake::Task['db:fixtures:load2'].invoke # Lo llamamos dos veces porque si no no se cargan bien
  end

  desc 'Test the lib stuff.'
  Rake::TestTask.new(:libs) do |t|
    t.libs << 'test'
    t.pattern = 'test/lib/*_test.rb'
    t.verbose = true
  end

  desc 'Test scripts tests'
  Rake::TestTask.new(:scripts) do |t|
    t.libs << 'test'
    t.pattern = 'test/scripts/*_test.rb'
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
                            'test/functional/*/*/*_test.rb',
                            'test/unit/helpers/*_test.rb',
                            'test/unit/helpers/*/*_test.rb',
                            'test/unit/helpers/*/*/*_test.rb',
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
      Rails.env = 'test'
      raise "NO" unless `hostname`.strip == 'balrog'
      `rm -r #{Rails.root}/coverage/*` if File.exists?("#{Rails.root}/coverage")
      `rm -r #{Rails.root}/public/storage/*` if File.exists?("#{Rails.root}/public/storage")
      `rm -r #{Rails.root}/test/reports/*` if File.exists?("#{Rails.root}/test/reports")
      `git submodule init`
      `git submodule update`
      Rake::Task['db:test:real_prepare'].invoke
      Rake::Task['gm:update_default_skin_styles'].invoke
      Rake::Task['ci:setup:testunit'].invoke
    end

    namespace :plan do
      desc "Batería de tests ampliada (validación html/css/js, tamaño de html/css/js)"
      task :qa do
        Rake::Task['test:bamboo:init'].invoke
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

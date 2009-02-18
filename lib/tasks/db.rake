require 'lib/redefine_task'
require 'fileutils'

namespace :db do
  namespace :fixtures do
    desc "Load fixtures into the current environment's database in one transaction.  Load specific fixtures using FIXTURES=x,y"
    task :load2 => :environment do
      require 'active_record/fixtures'
      require 'lib/overload_insert_fixtures'
      ActiveRecord::Base.establish_connection(:test)
      fixture_files = (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'test', 'fixtures', '*.{yml,csv}'))).collect {|fixture_file| File.basename(fixture_file, '.*') }
      Fixtures.create_fixtures('test/fixtures', fixture_files)
    end
  end
  
  namespace :test do
    desc "Carga las fixtures en la bd"
    task :prepare => :environment do
      Rake::Task['db:fixtures:load2'].invoke
    end
    
    desc "Crea la bd test"
    task :create do
      Rake::Task['db:test:purge'].invoke
      abcs = ActiveRecord::Base.configurations
      `dropdb -U #{abcs['test']['username']} #{abcs['test']['database']}`
      `createdb -U #{abcs['test']['username']} #{abcs['test']['database']}`
      `psql --quiet -U #{abcs['test']['username']} -f db/create.sql #{abcs['test']['database']}`
    end
    
    desc "Configures a gm installation from zero for a test environment"
    task :real_prepare do
      FileUtils.cp("config/database.yml.orig", "config/database.yml") unless File.exists?("config/database.yml")
      Rake::Task['db:test:create'].invoke
      Rake::Task['db:fixtures:load2'].invoke
    end
    
    def redefine_task(args, &block)
      Rake::Task.redefine_task(args, &block)
    end
    
    desc "Faster replacement for the original :clone_structure_to_test"
    redefine_task :clone_structure => :environment do
      Rake::Task['db:test:create'].invoke # deprecated
    end
    
    redefine_task :prepare => :environment do
      # purposedly do nothing
    end
  end
end
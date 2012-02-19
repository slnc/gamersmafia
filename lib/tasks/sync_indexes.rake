namespace :gm do
  desc "Sync indexes"
  task :sync_indexes => :environment do
    Rake::Task["gm:sync_indexes:fix_categories"].invoke
    Rake::Task["gm:sync_indexes:fix_categories_count"].invoke
    fix_terms_count
  end
  
  namespace :sync_indexes do    
    desc "Recalcula varias caches de términos"
    task :fix_terms_count => :environment do
      Term.find(:all).each { |t| t.recalculate_counters }
    end
  end
end
namespace :gm do
  desc "Monthly operations"
  task :monthly => :environment do
    Rake::Task["gm:sync_indexes:fix_terms_count"].invoke
  end
end

namespace :gm do
  desc "Monthly operations"
  task :monthly => :environment do
    Rake::Task["gm:sync_indexes:fix_terms_count"].invoke
    GmSys.job('Download.check_invalid_downloads')
  end
end

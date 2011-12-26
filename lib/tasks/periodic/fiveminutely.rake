namespace :gm do
  desc "Operations to be run every 5 minutes"
  task :fiveminutely => :environment do
    Stats.update_online_stats
    GmSys.command("find #{Rails.root}/public/storage/d -mindepth 1 -maxdepth 1  -type d -mmin +60 -exec rm -r {} \\\\\;")
    GmSys.check_workers_pids
  end
end

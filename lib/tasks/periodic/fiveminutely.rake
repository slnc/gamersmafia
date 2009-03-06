namespace :gm do
  desc "Operations to be run every 5 minutes"
  task :fiveminutely => :environment do
    Stats.update_online_stats
    last_in_dbs = Dbs.db_query("SELECT created_on FROM stats.pageviews ORDER BY id DESC LIMIT 1")[0]['created_on'].to_time
    last_in_prod = User.db_query("SELECT created_on FROM stats.pageviews ORDER BY id DESC LIMIT 1")[0]['created_on'].to_time

    if last_in_prod.to_i - last_in_dbs.to_i > 600 # más de 10 minutos de diferencia
      Notification.deliver_support_db_oos(:prod => last_in_prod, :support => last_in_dbs)
    end
    GmSys.command("find #{RAILS_ROOT}/public/storage/d -mindepth 1 -maxdepth 1  -type d -mmin +60 -exec rm -r {} \\\\\;")
    GmSys.check_workers_pids
  end
end

namespace :gm do
  desc "Hourly operations"
  task :hourly => :environment do
    require 'app/controllers/application_controller'
    GmSys.kill_workers # just in case they leak, a refresh is not bad at all
    GmSys.job('Competitions.update_user_competitions_indicators')
    Notification.check_system_emails
    GmSys.command("find #{FRAGMENT_CACHE_PATH}/site/_online_state -type f -mmin +2 -exec rm {} \\\\\;")
    `find #{RAILS_ROOT}/tmp/sessions/ -type f -mmin +30 -name gm.\\\* -exec rm {} \\\;`
    User.db_query("DELETE FROM anonymous_users WHERE lastseen_on < now() - '1 hour'::interval")
    # TODO alariko se muere y no le resucitamos
    # exec("#{RAILS_ROOT}/script/check_alariko.sh") no funciona, hay que pensar otra idea
    CacheObserver.update_pending_contents # Just in case
    GmSys.job('AbTest.update_ab_tests')
    GmSys.job('UsersNewsfeed.process')
    `find /tmp -maxdepth 1 -mmin +1440  -type d -name "0.*" -exec rm -r {} \\\;` # TODO test para esto
  end
end

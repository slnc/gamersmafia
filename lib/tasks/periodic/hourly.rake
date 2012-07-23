namespace :gm do
  desc "Hourly operations"
  task :hourly => :environment do
    GmSys.kill_workers
    AbTest.delay.update_ab_tests
    CacheObserver.update_pending_contents
    Competitions.delay.update_user_competitions_indicators
    Notification.check_system_emails
    UsersNewsfeed.delay.process
    Cache.hourly_clear_file_caches
  end
end

# -*- encoding : utf-8 -*-
namespace :gm do
  desc "Daily operations"
  task :daily => :environment do
    begin
      Rake::Task['log:clear'].invoke
    rescue
    end

    # Order matters for these calls
    Rake::Task['gm:alariko'].invoke
    Faith.clear_faith_points_of_referers_and_resurrectors
    Faith.pay_faith_prices
    Stats.update_users_karma_stats
    Stats.update_users_daily_stats

    # We update predictions of bets for more than one day to account for  for
    # bets that aren't completed on the same day they are closed. It's a
    # tradeoff between the delay in backfilling for late bets and the cost of
    # computing bets results multiple times.
    Bet.update_prediction_accuracy(1.month.ago)
    Bet.update_prediction_accuracy(7.days.ago)
    Bet.update_prediction_accuracy(1.day.ago)
    AbTest.forget_old_treated_visitors
    Advertiser.send_reports_to_publisher_if_on_due_date
    AutologinKey.forget_old_autologin_keys
    Cache.clear_file_caches
    Faction.check_daily_karma
    Faction.check_faction_leaders
    Faith.update_ranking
    Karma.update_ranking
    Ladder.check_ladder_matches
    Popularity.update_rankings
    Question.close_old_open_questions
    Stats.forget_old_pageviews
    Stats.generate_daily_ads_stats
    Stats::Metrics.compute_daily_metrics(1.day.ago)
    Stats::Portals.update_portals_hits_stats
    Term.delete_empty_content_tags_terms
    TrackerItem.forget_old_tracker_items
    User.new_accounts_cleanup
    User.send_happy_birthday
    User.switch_inactive_users_to_zombies
    User.update_max_cache_valorations_weights_on_self_comments
    UsersNewsfeed.old.delete_all
    UsersRole.kill_zombified_staff
  end
end

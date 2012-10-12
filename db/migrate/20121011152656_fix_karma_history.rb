class FixKarmaHistory < ActiveRecord::Migration
  def up
    User.db_query("TRUNCATE stats.users_karma_daily_by_portal")
    User.db_query("TRUNCATE stats.users_daily_stats")
    Stats.update_users_karma_stats
    Stats.update_users_daily_stats
  end

  def down
  end
end

# -*- encoding : utf-8 -*-
class BetsPredictionRanking < ActiveRecord::Migration
  def up
    User.db_query("ALTER TABLE stats.general ADD COLUMN played_bets_participation int not null default 0;")
    User.db_query("ALTER TABLE stats.general ADD COLUMN played_bets_crowd_correctly_predicted int not null default 0;")
    User.db_query("ALTER TABLE stats.users_daily_stats ADD COLUMN played_bets_participation int not null default 0;")
    User.db_query("ALTER TABLE stats.users_daily_stats ADD COLUMN played_bets_correctly_predicted int not null default 0;")
  end

  def down
  end
end

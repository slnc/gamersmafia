class RemoveFaithColumns < ActiveRecord::Migration
  def up
    execute "alter table users drop column cache_faith_points;"
    execute "alter table users drop column ranking_faith_pos;"
    execute "alter table stats.general drop column faith_diff;"
    execute "alter table stats.users_daily_stats drop column faith;"
  end

  def down
  end
end

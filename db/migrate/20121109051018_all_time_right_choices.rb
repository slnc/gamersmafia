class AllTimeRightChoices < ActiveRecord::Migration
  def up
    execute "alter table decision_user_reputations add column all_time_right_choices int not null default 0;"
  end

  def down
  end
end

class AddLastKarmaSkillPoints < ActiveRecord::Migration
  def up
    execute "ALTER TABLE users ADD COLUMN last_karma_skill_points int not null default 0;"
  end

  def down
  end
end

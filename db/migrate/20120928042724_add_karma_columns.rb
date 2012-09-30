class AddKarmaColumns < ActiveRecord::Migration
  def up
    execute "alter table contents add column karma_points int;"
    execute "alter table comments add column karma_points int;"
  end

  def down
  end
end

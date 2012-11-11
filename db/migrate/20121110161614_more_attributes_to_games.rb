class MoreAttributesToGames < ActiveRecord::Migration
  def up
    execute "alter table games add column release_date varchar;"
    execute "alter table games add column publisher_id int references terms;"
  end

  def down
  end
end

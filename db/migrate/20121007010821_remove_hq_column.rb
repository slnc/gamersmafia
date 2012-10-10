class RemoveHqColumn < ActiveRecord::Migration
  def up
    execute "alter table users drop column is_hq;"
  end

  def down
  end
end

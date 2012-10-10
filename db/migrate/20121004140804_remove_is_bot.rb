class RemoveIsBot < ActiveRecord::Migration
  def up
    execute "alter table users drop column is_bot;"
  end

  def down
  end
end

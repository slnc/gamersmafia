class RemoveSomeFields < ActiveRecord::Migration
  def up
    execute "ALTER TABLE contents DROP COLUMN karma_paid;"
    execute "ALTER TABLE comments DROP COLUMN karma_paid;"
  end

  def down
  end
end

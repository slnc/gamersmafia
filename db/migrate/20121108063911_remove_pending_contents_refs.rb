class RemovePendingContentsRefs < ActiveRecord::Migration
  def up
    execute "alter table global_vars drop column pending_contents;"
  end

  def down
  end
end

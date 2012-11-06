class PendingDecisions < ActiveRecord::Migration
  def up
    execute "alter table users add column pending_decisions bool not null default 'f';"
  end

  def down
  end
end

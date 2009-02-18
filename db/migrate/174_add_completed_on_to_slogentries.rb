class AddCompletedOnToSlogentries < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table slog_entries add column completed_on timestamp;"
    execute "update slog_entries set completed_on = now() where reviewer_user_id is not null;"
  end

  def self.down
  end
end

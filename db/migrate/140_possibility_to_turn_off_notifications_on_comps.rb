class PossibilityToTurnOffNotificationsOnComps < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table competitions add column send_notifications bool not null default 't';"
  end

  def self.down
  end
end

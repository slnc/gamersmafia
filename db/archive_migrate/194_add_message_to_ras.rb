class AddMessageToRas < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table recruitment_ads add column message varchar;"
    slonik_execute "alter table recruitment_ads add column deleted bool not null default 'f';"
    Emblems.update_current_users_emblems
  end

  def self.down
  end
end

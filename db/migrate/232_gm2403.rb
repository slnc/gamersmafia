class Gm2403 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table questions add column answer_selected_by_user_id int references users match full;"
  end

  def self.down
  end
end

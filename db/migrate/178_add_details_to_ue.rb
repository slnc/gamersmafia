class AddDetailsToUe < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users_emblems add column details varchar;"
  end

  def self.down
  end
end

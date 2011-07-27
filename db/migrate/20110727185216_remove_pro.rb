class RemovePro < ActiveRecord::Migration
  def self.up
    User.db_query("ALTER TABLE competitions DROP column pro;")
  end

  def self.down
  end
end

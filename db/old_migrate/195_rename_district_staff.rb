class RenameDistrictStaff < ActiveRecord::Migration
  def self.up
    User.db_query("UPDATE users_roles SET role = 'Don' WHERE role = 'BazarDistrictBoss'")
    User.db_query("UPDATE users_roles SET role = 'ManoDerecha' WHERE role = 'BazarDistrictUnderboss'")
  end

  def self.down
  end
end

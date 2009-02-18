class AddObjectId < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users_actions add column object_id int;"
    
    #(198-122).times do |i|
      #User.db_query("INSERT INTO schema_migrations(version) VALUES('#{122+i}')")
      #end
  end

  def self.down
  end
end

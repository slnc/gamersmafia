class CreateGroupsMessages < ActiveRecord::Migration
  def self.up
    create_table :groups_messages do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :groups_messages
  end
end

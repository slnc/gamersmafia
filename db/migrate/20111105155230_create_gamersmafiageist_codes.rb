class CreateGamersmafiageistCodes < ActiveRecord::Migration
  def self.up
    create_table :gamersmafiageist_codes do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :gamersmafiageist_codes
  end
end

class AddReasonToOutstandingUser < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table outstanding_entities add column reason varchar;"
  end

  def self.down
  end
end

class AddTermIdToPotds < ActiveRecord::Migration
  def self.up
	slonik_execute "alter table potds add column term_id int references terms match full on delete cascade;"
  end

  def self.down
  end
end

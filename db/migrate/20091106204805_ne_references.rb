class NeReferences < ActiveRecord::Migration
  def self.up
    slonik_execute "create table ne_references(id serial primary key not null unique, created_on timestamp not null, referenced_on timestamp not null, entity_class varchar not null, entity_id int not null, referencer_class varchar not null, referencer_id int not null);"
  end

  def self.down
  end
end

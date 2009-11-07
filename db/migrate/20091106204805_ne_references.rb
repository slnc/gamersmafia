class NeReferences < ActiveRecord::Migration
  def self.up
    slonik_execute "create table ne_references(id serial primary key not null unique, created_on timestamp not null, referenced_on timestamp not null, entity_class varchar not null, entity_id int not null, referencer_class varchar not null, referencer_id int not null);"
    slonik_execute "create unique index ne_references_uniq on ne_references(entity_class, entity_id, referencer_class, referencer_id);"
    slonik_execute "create index ne_references_entity on ne_references(entity_class, entity_id);"
    slonik_execute "create index ne_references_referencer on ne_references(referencer_class, referencer_id);"
  end

  def self.down
  end
end

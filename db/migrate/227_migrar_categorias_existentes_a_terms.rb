class MigrarCategoriasExistentesATerms < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table terms add column count int not null default 0;"
  end
  
  def self.down
  end
end

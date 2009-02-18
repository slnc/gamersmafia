class Gm1939 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users add column comments_valorations_type_id int references comments_valorations_types;"
    slonik_execute "alter table users add column comments_valorations_strength decimal(10, 2);"
  end

  def self.down
  end
end

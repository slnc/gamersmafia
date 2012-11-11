class CreateTagCreateEntity < ActiveRecord::Migration
  def up
    execute "update users_skills set role = 'CreateEntity' WHERE role = 'CreateTag'"
    execute "alter table games add column user_id int;"
    execute "update games set user_id = 1;"
    execute "alter table games alter column user_id set not null;"
    execute "alter table games add column has_faction bool not null default 'f';"
    execute "update games set has_faction = 't'"
  end

  def down
  end
end

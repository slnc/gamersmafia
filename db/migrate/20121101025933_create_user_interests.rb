class CreateUserInterests < ActiveRecord::Migration
  def change
    User.db_query("CREATE TABLE user_interests (id serial primary key not null unique, user_id int not null references users match full on delete cascade, created_on timestamp not null default now(), entity_type_class varchar not null, entity_id int not null);")
    User.db_query("CREATE INDEX user_interests_entity_class_entity_id on user_interests(entity_type_class, entity_id);")
    User.db_query("CREATE INDEX user_interests_user_id on user_interests(user_id);")
    User.db_query("CREATE UNIQUE INDEX user_interests_uniq on user_interests(user_id, entity_type_class, entity_id);")
  end
end

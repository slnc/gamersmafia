class Gm2370 < ActiveRecord::Migration
  def self.up
    slonik_execute "CREATE TABLE users_contents_tags(id serial primary key not null unique, created_on timestamp not null default now(), user_id int not null references users, content_id int not null references contents, term_id int not null references terms, original_name varchar not null);"
  end

  def self.down
  end
end

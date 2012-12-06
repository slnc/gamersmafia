class ContentAttributes < ActiveRecord::Migration
  def up
    execute "create table content_attributes(id serial primary key not null unique, content_id int not null references contents match full, name varchar not null, varchar_value varchar, int_value int, float_value float, timestamp_value timestamp, text_value text);"
    execute "create index content_attributes_uniq on content_attributes(content_id, name);"
  end

  def down
  end
end

class NewTermFields < ActiveRecord::Migration
  def up
    execute "alter table terms add column short_description varchar;"
    execute "alter table terms add column long_description text;"
    execute "alter table terms add column header_image varchar;"
    execute "alter table terms add column square_image varchar;"
  end

  def down
  end
end

class Gm1958 < ActiveRecord::Migration
  def self.up
    execute "alter table stats.pageloadtime add column db_queries int;"
    execute "alter table stats.pageloadtime add column db_rows int;"
  end

  def self.down
  end
end

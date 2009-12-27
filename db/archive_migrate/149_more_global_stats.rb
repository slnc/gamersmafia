class MoreGlobalStats < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table stats.general add column avg_db_queries_per_request float;"
    slonik_execute "alter table stats.general add column stddev_db_queries_per_request float;"
    slonik_execute "alter table stats.general add column requests int;"
    slonik_execute "alter table stats.general add column database_size int;"
  end

  def self.down
  end
end

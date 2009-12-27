class AddPortalsUpdatedOn < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table global_vars add column portals_updated_on timestamp not null default now();"
  end

  def self.down
  end
end

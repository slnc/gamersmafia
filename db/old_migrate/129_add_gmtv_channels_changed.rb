class AddGmtvChannelsChanged < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table global_vars add column gmtv_channels_updated_on timestamp not null default now();"
  end

  def self.down
  end
end

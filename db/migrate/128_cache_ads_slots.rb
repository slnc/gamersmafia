class CacheAdsSlots < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table global_vars add column ads_slots_updated_on timestamp not null default now();"
  end

  def self.down
  end
end

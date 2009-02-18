class AddAdsStats_ < ActiveRecord::Migration
  def self.up
    slonik_execute "create table stats.ads_daily(id serial primary key, ads_slots_instance_id int references ads_slots_instances match full, created_on date not null, hits int not null, ctr float not null, pageviews int not null);"
  end

  def self.down
  end
end

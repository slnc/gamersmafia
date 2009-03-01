class AddSshotToGmtvChannels < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table gmtv_channels add column screenshot varchar;"
  end

  def self.down
  end
end

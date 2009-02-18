class AddUniqueVisitorsReg < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table stats.portals add column unique_visitors_reg int;"
  end

  def self.down
  end
end

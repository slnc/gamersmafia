class FixOldAdsStats < ActiveRecord::Migration
  def self.up
    #Ad.find(:all, :order => 'id').each do |ad|
    #  puts "ad "<<ad.id.to_s<<" "<<ad.name
    #  adsi = ad.ads_slots_instances.find(:first, :conditions => "deleted = 'f'", :order => 'ads_slot_id ASC, id ASC')
    #  puts "renombrando ocurrencias de ad"<<ad.id.to_s<<" a adsi"<<adsi.id.to_s
    #  User.db_query("UPDATE stats.ads SET element_id = 'adsi#{adsi.id}' WHERE element_id = 'ad#{ad.id}'")
    #end
    
    #90.times do |t|
    #  tstart = (t+1).days.ago.beginning_of_day
    #  tend = tstart.end_of_day
    #  puts "#{tstart}"
    #  Stats.consolidate_ads_daily_stats(tstart, tend)
    #end
    
  end

  def self.down
  end
end

class AddBazarDistrictIdToContent < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table contents add column bazar_district_id int;"
    
    slonik_execute "alter table stats.portals add column pageviews int;"
    slonik_execute "alter table stats.portals add column visits int;"
    slonik_execute "alter table stats.portals add column unique_visitors int;"
    
    Cms::BAZAR_DISTRICTS_VALID.each do |ct|
      cls = Object.const_get(ct)
      BazarDistrict.find(:all).each do |bd|
        tld = bd.top_level_category(cls)
        next unless tld
        tld.find(:all).each do |it|
          User.db_query("UPDATE contents SET bazar_district_id = " << bd.id.to_s << " WHERE id = " << it.unique_content.id.to_s)          
        end
      end
    end
  end

  def self.down
  end
end

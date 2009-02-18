class CreateBazarDistrictPortalsForExistingDistricts < ActiveRecord::Migration
  def self.up
    BazarDistrict.find(:all).each do |bd| BazarDistrictPortal.create({:code => bd.code, :name => bd.name}) end
    bc = BetsCategory.create(:code => 'bazar', :name => 'Bazar')
    bc.update_attributes(:root_id => bc.id)
    bc.children.create(:code => 'deportes', :name => 'Deportes')
    
    dc = DownloadsCategory.create(:code => 'bazar', :name => 'Bazar')
  end

  def self.down
  end
end

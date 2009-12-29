class MigrateBazarDistrictCategoriesToRoot < ActiveRecord::Migration
  def self.up
    BazarDistrict.find(:all).each do |bz|
      Cms::BAZAR_DISTRICTS_VALID.each do |cname|
        cls = Object.const_get(cname).category_class
        bazcat = cls.find(:first, :conditions => 'code = \'bazar\' AND root_id = id')
        next if bazcat.nil?
        inst = bazcat.children.find(:first, :conditions => ['code = ?', bz.code])
        if inst
          inst.root_id = inst.id
          inst.parent_id = nil
          inst.save
        end
      end
    end
  end
  
  def self.down
  end
end

load RAILS_ROOT + '/Rakefile'

class Platform < ActiveRecord::Base
  validates_format_of :code, :with => /^[a-z0-9]{1,6}$/
  validates_format_of :name, :with => /^[a-z0-9:[:space:]]{1,36}$/i
  validates_uniqueness_of :code
  validates_uniqueness_of :name
  has_many :terms
  before_save :check_code_doesnt_belong_to_portal
  after_create :create_term
  
  def create_term
    Term.create(:platform_id => self.id, :name => self.name, :slug => self.code)
  end
  
  def faction
    Faction.find_by_code(self.code)
  end
  
  # TODO copypaste de game
  def update_code_in_other_places_if_changed
    if slnc_changed?(:code)
      return if slnc_changed_old_values[:code].nil?
      f = Faction.find_by_code(slnc_changed_old_values[:code].strip)
      
      f.code = self.code
      f.save
      Cms::CONTENTS_WITH_CATEGORIES.each do |content_name|
        root_cat = Object.const_get(content_name).category_class.find(:first, :conditions =>['code = ? and id = root_id', slnc_changed_old_values[:code]])
        root_cat.code = self.code
        root_cat.save
      end
    end
    true
  end
  
  # TODO copypaste de Game.rb
  after_save :update_img_file
  after_save :update_code_in_other_places_if_changed
  
  def file=(incoming_file)
    @temp_file = incoming_file
    @filename = incoming_file.original_filename if incoming_file.to_s != ''
    @content_type = incoming_file.content_type if incoming_file.to_s != ''
  end
  
  def portals
    [GmPortal.new] + FactionsPortal.find_by_sql("select * from portals where id in (select portal_id from factions_portals a join factions b on a.faction_id = b.id and b.code = '#{self.code}')")
  end
  
  def update_img_file
    if @temp_file and @filename != ''
      File.open("#{RAILS_ROOT}/public/storage/games/#{self.code}.gif", "wb+") do |f| 
        f.write(@temp_file.read)
      end
      Rake::Task["gm:update_default_skin_styles"].invoke
      @temp_file = nil
      #self.path = "/storage/games/#{self.code}.gif"
      #self.save
    end
  end
  
  def check_code_doesnt_belong_to_portal
    # TODO dup en Game.rb
    if self.id
      # TODO temp Portal.count(:conditions => ["code = ? AND id <> ?", self.code, self.id]) == 0 && !Portal::UNALLOWED_CODES.include?(code)
      true
    else
      Portal.find_by_code(self.code).nil? && !Portal::UNALLOWED_CODES.include?(code)
    end
  end
end

load Rails.root + '/Rakefile'

class Platform < ActiveRecord::Base
  validates_format_of :code, :with => /^[a-z0-9]{1,6}$/
  validates_format_of :name, :with => /^[a-z0-9:[:space:]]{1,36}$/i
  validates_uniqueness_of :code
  validates_uniqueness_of :name
  has_many :terms
  before_save :check_code_doesnt_belong_to_portal
  after_create :create_term_and_categories
  observe_attr :code, :name
  
  def create_term_and_categories
    root_term = Term.create(:platform_id => self.id, :name => self.name, :slug => self.code)
    
    Organizations::DEFAULT_CONTENTS_CATEGORIES.each do |c|
      root_term.children.create(:name => c[1], :taxonomy => c[0])
    end
  end
  
  def faction
    Faction.find_by_code(self.code)
  end
  
  # TODO copypaste de game
  def update_code_in_other_places_if_changed
    [:code, :name].each do |thing|
    if slnc_changed?(:code)
      return if slnc_changed_old_values[thing].nil?
      f = Faction.send("find_by_#{thing}", slnc_changed_old_values[thing].strip)
      f.send(thing, self.send(thing))
      f.save
      Cms::CONTENTS_WITH_CATEGORIES.each do |content_name|
        root_cat = Object.const_get(content_name).category_class.find(:first, :conditions =>["thing = #{thing} and id = root_id", slnc_changed_old_values[thing]])
        root_cat.send(thing, self.send(thing))
        root_cat.save
      end
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
      File.open(self.img_file, "wb+") do |f| 
        f.write(@temp_file.read)
      end
      Rake::Task["gm:update_default_skin_styles"].invoke
      @temp_file = nil
      #self.path = "/storage/games/#{self.code}.gif"
      #self.save
    end
  end
  
  def has_img_file?
    File.exists?(self.img_file)
  end
  
  def img_file
    "#{Rails.root}/public/storage/games/#{self.code}.gif"
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

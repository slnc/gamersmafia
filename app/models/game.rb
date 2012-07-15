# -*- encoding : utf-8 -*-
class Game < ActiveRecord::Base
  has_many :games_maps, :dependent => :destroy
  has_many :games_modes, :dependent => :destroy
  has_many :games_versions, :dependent => :destroy
  has_many :users_guids, :dependent => :destroy
  has_many :competitions, :dependent => :destroy

  has_many :terms, :dependent => :destroy

  after_create :create_contents_categories
  after_save :update_faction_code
  before_save :check_code_doesnt_belong_to_portal
  before_create :check_hid

  validates_format_of :code, :with => /^[a-z0-9]{1,6}$/
  validates_format_of :name, :with => /^[a-z0-9:[:space:]]{1,36}$/i
  validates_uniqueness_of :code
  validates_uniqueness_of :name

  ENTITY_USER = 0
  ENTITY_CLAN = 1

  def check_hid
    if Term.count(:conditions => ["slug = ?", self.code]) > 0
      self.errors.add('code', "'#{self.code}' ya está siendo usado")
      return false
    else
      return true
    end
  end

  def faction
    Faction.find_by_code(self.code)
  end

  def update_faction_code
    # self.class.db_query("update factions set code = (SELECT code from games where games.name = factions.name) WHERE name = '#{self.name.gsub(/'/, '\\\\\'')}'")
  end

  def valid_guid?(guid)
    raise 'non-GUID game' unless has_guids
    guid =~ Regexp.compile(self.guid_format)
  end

  def create_contents_categories
    if Faction.find_by_name(self.name).nil? then
      f = Faction.new({:name => self.name, :code => self.code})
      f.save
    end

    portal = Portal.create({:name => self.name, :code => self.code})
    portal.factions<< f

    # El orden es importante
    root_term = Term.create(:game_id => self.id, :name => self.name, :slug => self.code)
    raise "Term isn't created #{root_term.errors.full_messages_html}" if root_term.new_record?
    Organizations::DEFAULT_CONTENTS_CATEGORIES.each do |c|
      root_term.children.create(:name => c[1], :taxonomy => c[0])
    end
  end

  after_save :update_img_file
  after_save :update_code_in_other_places_if_changed

  def file=(incoming_file)
    @temp_file = incoming_file
    @filename = incoming_file.original_filename if incoming_file.to_s != ''
    @content_type = incoming_file.content_type if incoming_file.to_s != ''
  end

  def portals
    [GmPortal.new] + FactionsPortal.find_by_sql("SELECT * from portals where id in (select portal_id from factions_portals a join factions b on a.faction_id = b.id and b.code = '#{self.code}')")
  end

  def update_img_file
    if @temp_file and @filename != ''
      File.open(self.img_file, "wb+") do |f|
        f.write(@temp_file.read)
      end
      @temp_file = nil
      GmSys.command('rake gm:update_default_skin_styles')
    end
  end

  def has_img_file?
    File.exists?(self.img_file)
  end

  def img_file
    "#{Rails.root}/public/storage/games/#{self.code}.gif"
  end

  # TODO tb a plataformas
  def update_code_in_other_places_if_changed
    [:code, :name].each do |thing|
    if self.code_changed?
      return if self.send("#{thing}_changed?".to_sym)
      f = Faction.send("find_by_#{thing}", self.send("#{thing}_was".strip))
      f.send("#{thing}=", self.send(thing))
      f.save
      Term.find(
          :first,
          :conditions => [
              'id = root_id AND slug = ?',
              self.changed["code"].strip]).update_attributes(:slug => self.code)
      Content.find(:all, :conditions => ['id = ?', self.id]).each do |c|
        User.db_query("UPDATE contents SET url = nil WHERE id = #{c.id}")
      end
    end
    end
    true
  end

  def check_code_doesnt_belong_to_portal
    # TODO dup en Platform.rb
    if self.id
      # TODO Temp Portal.count(:conditions => ["code = ? AND id <> ?", self.code, self.id]) == 0 && !Portal::UNALLOWED_CODES.include?(code)
      true
    else
      Portal.find_by_code(self.code).nil? && !Portal::UNALLOWED_CODES.include?(code)
    end
  end
end

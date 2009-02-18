class Portal < ActiveRecord::Base
  UNALLOWED_CODES = %w(bazar arena gm sys sistema webmaster secure ssl static ww www admin)
  serialize :options
  has_and_belongs_to_many :factions # las necesitamos aquí
  has_and_belongs_to_many :skins
  has_and_belongs_to_many :ads_slots
  belongs_to :clan # necesitamos aquí
  belongs_to :default_gmtv_channel
  belongs_to :skin
  
  before_save :check_code
  
  def skin
    self.skin_id ? Skin.find(self.skin_id) : Skin.find_by_hid('default')
  end
  
  def self.find_by_competitions_match(cm)
    # Buscamos los portales que estén asociados a la facción del juego de la competición de cm
    f = Faction.find_by_code("#{cm.competition.game.code}")
    Portal.find(:all, :conditions => "id IN (SELECT portal_id FROM factions_portals WHERE faction_id = #{f.id})")
  end
  
  def self.find_by_id(id)
    id = id.to_i if id.kind_of?(String)
    if id == -1
      GmPortal.new
    elsif id == -2
      BazarPortal.new
    elsif id == -3
      ArenaPortal.new
    else
      Portal.find(:first, :conditions => ['id = ?', id])
    end
  end
  
  
  def latest_articles
    articles = []
    articles += self.interview.find(:published, :limit => 8, :order => 'created_on DESC') if self.interview
    articles += self.column.find(:published, :limit => 8, :order => 'created_on DESC') if  self.column
    articles += self.tutorial.find(:published, :limit => 8, :order => 'created_on DESC') if self.tutorial
    articles += self.review.find(:published, :limit => 8, :order => 'created_on DESC') if self.review
    
    ordered = {}
    for a in articles
      ordered[a.created_on.to_i] = a
    end
    
    articles = ordered.sort.reverse
    afinal = []
    i = 0
    while i < 8 and i < articles.length do
      afinal << articles[i][1]
      i += 1
    end
    afinal
  end
  
  private
  def check_code
    !UNALLOWED_CODES.include?(self.code)
  end
end

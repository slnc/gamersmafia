# -*- encoding : utf-8 -*-
class Portal < ActiveRecord::Base
  UNALLOWED_CODES = %w(
      admin
      arena
      bazar
      gm
      secure
      sistema
      ssl
      static
      sys
      webmaster
      ww
      www
  )
  serialize :options
  has_and_belongs_to_many :factions # las necesitamos aquí
  has_and_belongs_to_many :skins
  has_and_belongs_to_many :ads_slots
  belongs_to :clan # necesitamos aquí
  belongs_to :default_gmtv_channel
  belongs_to :skin
  file_column :small_header
  after_save :update_global_vars

  scope :factions, :conditions => ['type = \'FactionsPortal\'']

  before_save :check_code

  def update_global_vars
    GlobalVars.update_var("portals_updated_on", "now()")
  end

  def skin
    self.skin_id ? Skin.find(self.skin_id) : Skin.find_by_hid('default')
  end

  def self.find_by_competitions_match(cm)
    # Buscamos los portales que estén asociados a la facción del juego de la competición de cm
    f = Faction.find_by_code("#{cm.competition.game.slug}")
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

  def self.find_by_root_term(term)

  end

  def latest_articles(limit=8)
    articles = []
    articles += Interview.in_portal(self).published.find(:all, :limit => limit, :order => 'created_on DESC') if self.interview
    articles += Column.in_portal(self).published.find(:all, :limit => limit, :order => 'created_on DESC') if  self.column
    articles += Tutorial.in_portal(self).published.find(:all, :limit => limit, :order => 'created_on DESC') if self.tutorial
    articles += Review.in_portal(self).published.find(:all, :limit => limit, :order => 'created_on DESC') if self.review

    ordered = {}
    for a in articles
      ordered[a.created_on.to_i] = a
    end

    articles = ordered.sort.reverse
    afinal = []
    i = 0
    while i < limit and i < articles.length do
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

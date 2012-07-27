# -*- encoding : utf-8 -*-
class RecruitmentAd < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable

  belongs_to :clan
  # WARNING CLAN_ID significa otra cosa que en el resto de contenidos

  belongs_to :country
  belongs_to :game
  serialize :levels

  validates_presence_of :game_id

  after_create :link_to_root_term

  def link_to_root_term
    Cms::modify_content_state(self, Ias.MrMan, Cms::PUBLISHED)
    Term.single_toplevel(:game_id => self.game_id).link(self.unique_content)
    true
  end

  def OLDtitle
    self.clan_id ? "#{self.clan.name} busca miembros" : "#{self.user.login} busca clan"
  end

  def title_entity
    self.clan_id ? self.clan.name : self.user.login
  end

  def mark_as_deleted
    Cms.modify_content_state(self, Ias.MrMan, Cms::DELETED)
    self.update_attributes(:deleted => true)
  end
end

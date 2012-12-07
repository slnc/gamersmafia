# -*- encoding : utf-8 -*-
# ContentAttribute:
# - country_id (int)
# - levels (varchar)
# - clan_id (int)
# - game_id (int)
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
    Content.publish_content_directly(self, Ias.MrMan)
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
    Content.delete_content(self, Ias.MrMan)
    self.update_attributes(:deleted => true)
  end
end

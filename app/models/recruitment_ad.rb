class RecruitmentAd < ActiveRecord::Base
  belongs_to :user
  belongs_to :clan
  belongs_to :country
  belongs_to :game
  serialize :levels
  
  validates_presence_of :game_id
  
  observe_attr :deleted
  
  def title
    self.clan_id ? "#{self.clan.name} busca miembros" : "#{self.user.login} busca clan"
  end
  
  def title_entity
    self.clan_id ? self.clan.name : self.user.login
  end
  
  def can_be_edited_by?(user)
    user.has_admin_permission?(:capo) || user.id == self.user_id || (self.clan_id && self.clan.user_is_clanleader(user.id))
  end
  
  def mark_as_deleted
    self.update_attributes(:deleted => true) unless self.deleted?
  end
end

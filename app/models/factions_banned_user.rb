# -*- encoding : utf-8 -*-
class FactionsBannedUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :banner_user, :class_name => 'User', :foreign_key => 'banner_user_id'
  belongs_to :faction
  validates_presence_of :user_id
  validates_presence_of :faction_id
  validates_presence_of :banner_user_id
  validates_uniqueness_of :user_id, :scope => :faction_id, :message => ' ya está baneado'
  after_create :notify_admins

  private
  def notify_admins
    Alert.create({:type_id => Alert::TYPES[:security], :headline => "Usuario <strong><a href=\"#{Routing.gmurl(self.user)}\">#{self.user.login}</a></strong> baneado de la facción <a href=\"#{Routing.gmurl(Faction.find(self.faction_id))}\">#{self.faction.name}</a>" })
  end
end

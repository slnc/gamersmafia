# -*- encoding : utf-8 -*-
class Group < ActiveRecord::Base
  has_many :members
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
  validates_presence_of :name

  has_users_skill 'GroupAdministrator'
  has_users_skill 'GroupMember'

  def members_count
    UsersSkill.count(:conditions => ["role IN ('GroupMember', 'GroupAdministrator') AND role_data = ?", self.id.to_s])
  end

  def members
    UsersSkill.find(:all, :conditions => ["role IN ('GroupMember', 'GroupAdministrator') AND role_data = ?", self.id.to_s], :order => 'lower(users.login)', :include => :user).collect { |ur| ur.user }
  end

  def administrators
    UsersSkill.find(:all, :conditions => ["role = 'GroupAdministrator' AND role_data = ?", self.id.to_s], :order => 'lower(users.login)', :include => :user).collect { |ur| ur.user }
  end

  def add_administrator(u)
    ur = UsersSkill.find(:first, :conditions => ["role = 'GroupAdministrator' AND role_data = ? AND user_id = ?", self.id.to_s, u.id])
    if ur.nil?
      UsersSkill.create(:user_id => u.id, :role => 'GroupAdministrator', :role_data => self.id.to_s)
      true
    else
      false
    end
  end

  def remove_administrator(u)
    ur = UsersSkill.find(:all, :conditions => ["role = 'GroupAdministrator' AND role_data = ? AND user_id = ?", self.id.to_s, u.id])
    ur.destroy if ur
  end


  def add_user_to_group(user)
    prev = UsersSkill.find(:all, :conditions => ['role IN (\'GroupMember\', \'GroupAdministrator\') AND role_data = ? AND user_id = ?', self.id.to_s, user.id])
    if prev.size == 0
      UsersSkill.create(:role => 'GroupMember', :role_data => self.id.to_s, :user_id => user.id)
      true
    else
      false
    end
  end

  def remove_user_from_group(user)
    UsersSkill.find(:all, :conditions => ['role IN (\'GroupMember\', \'GroupAdministrator\') AND role_data = ? AND user_id = ?', self.id.to_s, user.id]).each do |ur|
      ur.destroy
    end
    true
  end
end

# -*- encoding : utf-8 -*-
class ClansGroup < ActiveRecord::Base
  belongs_to :clan
  has_and_belongs_to_many :users
  belongs_to :clans_groups_type

  def has_user(user_id)
    if self.class.db_query("SELECT user_id FROM clans_groups_users WHERE clans_group_id = #{self.id} and user_id = #{user_id}").size > 0 then
      true
    else
      false
    end
  end

  def to_s
    name
  end
end

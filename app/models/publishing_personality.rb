# -*- encoding : utf-8 -*-
class PublishingPersonality < ActiveRecord::Base
  belongs_to :user
  belongs_to :content_type

  def self.find_or_create(user, content_type)
    pp = find(:first, :conditions => ['user_id = ? and content_type_id = ?', user.id, content_type.id])
    pp = create({:user_id => user.id, :content_type_id => content_type.id}) if pp.nil?
    pp
  end

  def recalculate
    new_weight = Cms::get_user_weight_with(self.content_type, self.user)
    if new_weight == Infinity
      self.experience = 1.0
    elsif new_weight == -1*Infinity
      self.experience = -1.0
    else
      self.experience = new_weight
    end
    self.save
  end

  def successes
    User.db_query("SELECT count(a.id) FROM publishing_decisions A JOIN contents b ON a.content_id = b.id WHERE a.is_right = 't' AND b.content_type_id = #{content_type_id} AND a.user_id = #{user_id}")[0]['count'].to_i
  end

  def failures
    fallos = User.db_query("SELECT count(a.id) FROM publishing_decisions A JOIN contents b ON a.content_id = b.id WHERE a.is_right = 'f' AND b.content_type_id = #{content_type_id} AND a.user_id = #{user_id}")[0]['count'].to_i
  end
end

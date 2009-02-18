class PublishingPersonality < ActiveRecord::Base
  belongs_to :user
  belongs_to :content_type
  
  def self.find_or_create(user, content_type)
    p = find(:first, :conditions => ['user_id = ? and content_type_id = ?', user.id, content_type.id])
    p = create({:user_id => user.id, :content_type_id => content_type.id}) if p.nil?
    p
  end
  
  def recalculate
    self.experience = Cms::get_user_weight_with(self.content_type, self.user)
    self.experience = 1.0 if self.experience == Infinity
    self.experience = -1.0 if self.experience == -1*Infinity
    self.save
  end
  
  def successes
    User.db_query("SELECT count(a.id) FROM publishing_decisions A JOIN contents b ON a.content_id = b.id WHERE a.is_right = 't' AND b.content_type_id = #{content_type_id} AND a.user_id = #{user_id}")[0]['count'].to_i
  end
  
  def failures
    fallos = User.db_query("SELECT count(a.id) FROM publishing_decisions A JOIN contents b ON a.content_id = b.id WHERE a.is_right = 'f' AND b.content_type_id = #{content_type_id} AND a.user_id = #{user_id}")[0]['count'].to_i    
  end
end

module UserMixings
  def friendships_received_pending
    Friendship.find(:all, :conditions => ['receiver_user_id = ? and accepted_on is null', self.id])
  end
  
  def friendships_sent_pending
    Friendship.find(:all, :conditions => ['sender_user_id = ? and accepted_on is null', self.id])
  end
  
  def friends
    Friendship.find(:all, :conditions => ['(receiver_user_id = ? or sender_user_id = ?) and accepted_on is not null', self.id, self.id], :include => [:sender, :receiver]).collect { |f|
      f.receiver_user_id == self.id ? f.sender : f.receiver
    }.sort { |a,b| a.login.downcase <=> b.login.downcase }
  end
  
  def friends_ids_sql
    # devuelve una sql para ser lanzada sobre friendships que devuelva los amigos del usuario actual
    "(SELECT sender_user_id FROM friendships WHERE accepted_on IS NOT NULL AND receiver_user_id = #{self.id}) UNION ((SELECT receiver_user_id FROM friendships where accepted_on IS NOT NULL AND sender_user_id = #{self.id}))"
  end
  
  def friends_count
    Friendship.count(:conditions => ['(receiver_user_id = ? or sender_user_id = ?) and accepted_on is not null', self.id, self.id])
  end
  
  def friends_online
    User.find(:all, :conditions => "id IN (SELECT receiver_user_id from friendships where accepted_on is not null and sender_user_id = #{self.id} UNION SELECT sender_user_id from friendships where accepted_on is not null and receiver_user_id = #{self.id}) AND lastseen_on > now() - '30 minutes'::interval", :order => 'lower(login)')
  end
end

class Friendship < ActiveRecord::Base
  # a friendship is said to be established when the accepted_on field is not null
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender_user_id'
  belongs_to :receiver, :class_name => 'User', :foreign_key => 'receiver_user_id'
  validates_uniqueness_of :sender_user_id, :scope => :receiver_user_id, :if => Proc.new { |f| f.receiver_user_id }
  
  
  before_create :check_max_unanswered
  before_create :create_external_invitation_key
  before_save :check_either_receiver_user_id_or_email_is_set
  before_save :check_not_own_friend
  
  
  after_create :send_notification
  after_save :check_friendship_requests_flags
  after_destroy :check_friendship_requests_flags
  after_destroy :mark_pending_friends_recommendations
  
  observe_attr :accepted_on
  
  def mark_pending_friends_recommendations
    FriendsRecommendation.users_are_now_not_friends(self.receiver, self.sender) if self.sender.respond_to?(:friends_recommendations)  
  end
  
  def check_max_unanswered    
    if Friendship.count(:conditions => ['sender_user_id = ? and accepted_on is null', self.sender_user_id]) >= Friendship.max_unanswered
      self.errors.add_to_base("Tienes demasiadas peticiones de amistad abiertas. Debes cancelar alguna antes de crear nuevas")
      false
    else
      true
    end
  end
  
  def accept
    self.accepted_on = Time.now
    self.save
    FriendsRecommendation.users_are_now_friends(self.receiver, self.sender) if self.sender.respond_to?(:friends_recommendations)
    Notification.deliver_new_friendship_accepted(self.sender, { :receiver => self.receiver })
  end
  
  def self.find_between(u1, u2, ignore_this_id=nil)
    # order solo se usa para el script de migración y limpiar "duplicados"
    if u1.class.name == 'String'
      tm = u1
      u1 = u2
      u2 = tm
    end
    raise "error, uno de los dos debe ser user" if u1.class.name != 'User' 
    sql_ignore = ignore_this_id ? " AND id <> #{ignore_this_id}" : ''
    if u2.class.name == 'String' then
      # raise "buscando por String"
      Friendship.find(:first, :conditions => ["receiver_email = ? and sender_user_id = ?#{sql_ignore}", u2, u1])
    else
      # puts "((receiver_user_id = ? and sender_user_id = ?) OR (receiver_user_id = ? and sender_user_id = ?)) #{sql_ignore}"
      Friendship.find(:first, :conditions => ["((receiver_user_id = ? and sender_user_id = ?) OR (receiver_user_id = ? and sender_user_id = ?)) #{sql_ignore}", u1, u2, u2, u1], :order => "sender_user_id, receiver_user_id")
    end
  end
  
  def accept_external(receiver)
    self.update_attributes(:receiver_email => nil,
                           :receiver_user_id => receiver.id,
                           :accepted_on => Time.now)
  end
  
  private
  def check_not_own_friend
    sender_user_id == receiver_user_id ? false : true
  end
  
  def check_friendship_requests_flags
    [self.receiver, self.sender].each do |u|
      next unless u.class.name == 'User'
      u.has_new_friend_requests = u.friendships_received_pending.size > 0 ? true : false
      u.save
    end
    true
  end
  
  def send_notification
    if self.receiver_user_id then
      Notification.deliver_new_friendship_request(self.receiver ? self.receiver : self.receiver_email, { :from => "#{self.sender.to_s} <#{self.sender.email}>", :sender => self.sender, :invitation_text => self.invitation_text, :invitation_key => self.external_invitation_key })
      FriendsRecommendation.users_are_now_friends(self.receiver, self.sender) if self.sender.respond_to?(:friends_recommendations)
    else # external
      Notification.deliver_new_friendship_request_external(self.receiver ? self.receiver : self.receiver_email, { :from => "#{self.sender.to_s} <#{self.sender.email}>", :sender => self.sender, :invitation_text => self.invitation_text, :invitation_key => self.external_invitation_key })      
    end
  end
  
  def check_either_receiver_user_id_or_email_is_set
    if self.receiver_user_id.nil? && self.receiver_email.to_s.empty? then
      self.errors.add_to_base("Imposible crear la amistad sin un destinatario.")
      return false
    end
    
    if self.receiver_email.to_s != '' && !(Cms::EMAIL_REGEXP =~ self.receiver_email) then
      self.errors.add_to_base("El email introducido no es válido.")
      return false
    end
    
    true
  end
  
  def create_external_invitation_key
    self.external_invitation_key = Digest::MD5.hexdigest((Kernel.rand(1000000).to_i + self.sender_user_id + Time.now.to_i).to_s)
    true
  end
  
  def self.max_unanswered
    200
  end
  
  
end
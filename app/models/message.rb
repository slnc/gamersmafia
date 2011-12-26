class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User', :foreign_key => 'user_id_from'
  belongs_to :recipient, :class_name => 'User', :foreign_key => 'user_id_to'

  #belongs_to :thread, :class_name => 'Message', :foreign_key => 'thread_id'
  #belongs_to :in_reply_to, :class_name => 'Message', :foreign_key => 'in_reply_to'

  R_USER = 0
  R_CLAN = 1
  R_FRIENDS = 2
  R_FACTION = 3
  R_FACTION_STAFF = 4

  NO_EMPTY_TITLE = 'no puede estar en blanco'

  validates_presence_of :title, :message, {:message => NO_EMPTY_TITLE}

  before_save :check_not_self
  after_create :notify_recipient
  after_create :set_thread_id_if_nil
  before_create :check_in_reply_to
  #before_create :check_spam

  after_save :update_recipient_unread
  after_destroy :update_recipient_unread
  observe_attr :is_read
  observe_attr :receiver_deleted

  plain_text :title
  before_save :sanitize_message

  scope :recipient_is,
              lambda { |user| { :conditions => ["user_id_to = ?", user.id]}}
  scope :recipient_undeleted,
              :conditions => "receiver_deleted is false"


  #def check_spam
  #  self.sender.created_on < 2.days.ago || Message.count(:conditions => ['user_id_from = ?', self.user_id_from]) < 10
  #end

  def sanitize_message
    self.message = self.message
  end

  # TODO borrando muchos mensajes de golpe no es eficiente
  def self.update_unread_count(user)
    dbr = Message.db_query("UPDATE users
                               SET cache_unread_messages = (SELECT COUNT(id)
                                                              FROM messages
                                                             WHERE user_id_to = #{user.id}
                                                              AND is_read is false
                                                              AND receiver_deleted is false)
                            WHERE id = #{user.id};
                           SELECT cache_unread_messages FROM users where id = #{user.id}")
    user.cache_unread_messages = dbr[0]['cache_unread_messages'].to_i
  end

  public
  def read(u=nil)
    return if self.is_read?

    self.update_attributes(:is_read => true)
    Message.update_unread_count(u) if u
  end

  def preview
    new_lines = message.split("\n").collect { |ln| (ln.strip == '' || ln[0..0] == '>') ? '' : ln }.join(' ')
    new_lines.strip
  end

  def delete_from_sender
    self.sender_deleted = true
    self.save
  end

  def delete_from_recipient
    self.receiver_deleted = true
    self.save
  end

  private
  def update_recipient_unread
    if self.frozen? || (!self.is_read?) || self.slnc_changed?(:is_read) || self.slnc_changed?(:receiver_deleted)
      Message.update_unread_count(self.recipient)
    end
  end

  def notify_recipient
    if self.recipient.notifications_newmessages then
      Notification.deliver_newmessage(self.recipient, { :sender => self.sender, :message => self})
    end
  end

  def check_in_reply_to
    return if self.thread_id
    if self.in_reply_to
      m = Message.find_by_id(self.in_reply_to)
      if m.nil? || ![m.user_id_to, m.user_id_from].include?(self.user_id_from)
        # message refered to is nonexistant, we silently ignore in_reply_to
        # as the original message can have been deleted
        self.in_reply_to = nil
      else
        m.has_replies = true
        m.save
        self.thread_id = m.thread_id
      end
    end
  end

  def set_thread_id_if_nil
    self.update_attributes(:thread_id => self.id) if self.thread_id.nil?
  end

  def check_not_self
    self.message_type = R_USER unless self.message_type
    self.user_id_to != self.user_id_from
  end
end

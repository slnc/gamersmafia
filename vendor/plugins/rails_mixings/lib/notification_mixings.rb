module NotificationMixings
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def check_system_emails
      if App.system_mail_host.index('gmail')
        @imap = Net::IMAP.new(App.system_mail_host, '993', true)
        @imap.login(App.system_mail_user, App.system_mail_password)
      else
        @imap = Net::IMAP.new(App.system_mail_host)
        @imap.authenticate('LOGIN', App.system_mail_user, App.system_mail_password)
      end

      @imap.select('INBOX')
      
      max = 500
      i = 0
      @imap.search(["NOT", "DELETED"]).each do |message_id|
        #puts "processing email #{message_id}"
        break if i >= max
        if process_email_envelope(@imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"])
          mark_for_deletion(message_id)
        #elsif process_email_body(@imap.fetch(message_id, "BODYSTRUCTURE")[0].attr["ENVELOPE"])
         # mark_for_deletion(message_id)
        else
          mark_for_deletion(message_id)
          # puts "don't know what to do with email #{message_id} #{@imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"].subject}"
          # move_unknown_email(message_id)
        end
        i = i+1
      end
      
      @imap.expunge
    end
    
    def mark_for_deletion(message_id)
      ##puts "marking for deletion message_id #{message_id}"
      @imap.store(message_id, "+FLAGS", [:Deleted])
    end
    
    def process_email_envelope(envelope)
      #puts "processing envelope.subject #{envelope.subject} (#{envelope.to[0]})"
      failed = ['Mail delivery failed: returning message to sender',
              'Undelivered Mail Returned to Sender',
              'Delivery Status Notification (Failure)',
              'Delivery Notification: Delivery has failed',
              'failure notice',
              'Undeliverable Message',
              'Message Delivery Failure',
              'Delivery status notification',
              'Delivery Status Notification']
      
      if failed.include?(envelope.subject) or (envelope.subject and (envelope.subject.downcase.include?('delivery') or envelope.subject.downcase.include?('returned mail')))
        m = /-([0-9a-zA-Z]+)$/.match(envelope.to[0].mailbox)
        
        if envelope.to[0].host == App.system_mail_domain.gsub('mail.', '') && !m.nil?
          message_key = m[1]
          se = SentEmail.find_by_message_key(message_key)
          if se
            u = User.find_by_login(se.recipient.split(' ')[0])
            u.disable_all_email_notifications if u
          end
          true
        else
          # puts "not deleting message because envelope host is #{envelope.to[0].host}"
          false
        end
      else
        false
      end
    end
    
    def process_email_body(envelope)
      false
    end
  end
end

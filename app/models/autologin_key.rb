class AutologinKey < ActiveRecord::Base
  belongs_to :user

  def touch
    # Things to do when an autologin key is used.
    tstamp = Time.now
    self.user.update_attribute(:lastseen_on, tstamp)
    self.update_attribute(:lastused_on, tstamp)
  end
end

# -*- encoding : utf-8 -*-
class AutologinKey < ActiveRecord::Base
  belongs_to :user

  def self.forget_old_autologin_keys
    AutologinKey.delete_all("lastused_on < now() - '1 month'::interval")
    User.db_query(
        "SELECT count(*), user_id
         FROM autologin_keys
         GROUP BY user_id
         HAVING count(*) > 3
         ORDER BY count(*) desc").each do |dbr|
      uid = dbr['user_id']
      AutologinKey.delete_all("user_id = #{uid}
                         AND id NOT IN (select id
                                          FROM autologin_keys
                                         where user_id = #{uid}
                                      order by id desc
                                         limit 3)")
    end
  end

  def touch
    # Things to do when an autologin key is used.
    tstamp = Time.now
    self.user.update_attribute(:lastseen_on, tstamp)
    self.update_attribute(:lastused_on, tstamp)
  end
end

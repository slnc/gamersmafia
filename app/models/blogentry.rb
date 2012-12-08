# -*- encoding : utf-8 -*-
# ContentAttribute:
# (none)
class Blogentry < Content
  def self.reset_urls_of_user_id(user_id)
    Blogentry.find(
        :all,
        :conditions => ['user_id = ?', user_id]).each { |c| c.url = nil; Routing.gmurl(c) }
  end
end

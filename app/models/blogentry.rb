# -*- encoding : utf-8 -*-
class Blogentry < ActiveRecord::Base
  acts_as_content

  def resolve_hid
    self.title
  end

  def self.reset_urls_of_user_id(user_id)
    Blogentry.find(:all, :conditions => ['user_id = ?', user_id]).collect {|be| be.unique_content}.each { |c| c.url = nil; Routing.gmurl(c) }
  end
end

require 'open-uri'


module Jira
  Q_AUTH = "&os_username=#{App.jira_username}&os_password=#{App.jira_password}"
  BASE_JIRA_URL = "http://hq.gamersmafia.com/secure/admin/user/"
  HQ_GROUPS = ['jira-users', 'GM+HQ', 'confluence-users']
  
  def self.user_exists?(user)
    out = open("#{BASE_JIRA_URL}/ViewUser.jspa?name=#{user}#{Jira::Q_AUTH}", 
    OPENURI_HEADERS).read
    !out.include?('User does not exist')
  end
  
  def self.create_user(user, email)
    # There is no destroy_user because issues or comments associated with that 
    # user would become dereferenced and we don't want that. 
    open("#{BASE_JIRA_URL}/AddUser.jspa?username=#{user}&fullname=#{user}&" +
         "email=#{email}&sendEmail=true&Crear=Crear#{Jira::Q_AUTH}", 
    OPENURI_HEADERS)
  end
  
  def self.activate_user(user)
    Jira::HQ_GROUPS.each do |group|
      Jira.add_user_to_group(user, group)
    end
  end
  
  def self.deactivate_user(user)
    Jira::HQ_GROUPS.each do |group|
      Jira.remove_user_from_group(user, group)
    end
  end
  
  def self.add_user_to_group(user, group)
    open("#{BASE_JIRA_URL}/EditUserGroups.jspa?join=Join+%3E%3E&" +
         "groupsToJoin=#{group}&name=#{user}#{Jira::Q_AUTH}", OPENURI_HEADERS)
  end
  
  def self.remove_user_from_group(user, group)
    open("#{BASE_JIRA_URL}/EditUserGroups.jspa?leave=%3C%3C+Leave&" +
         "groupsToLeave=#{group}&name=#{user}&returnUrl=UserBrowser.jspa" +
         "#{Jira::Q_AUTH}", OPENURI_HEADERS)
  end
end

if Rails.env == 'test'
  module Jira
    def self.user_exists?(user)
    end
    
    def self.create_user(user, email)
    end
    
    def self.activate_user(user)
    end
    
    def self.deactivate_user(user)
    end
    
    def self.add_user_to_group(user, group)
    end
    
    def self.remove_user_from_group(user, group)
    end
  end
end
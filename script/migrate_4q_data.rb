#!/usr/bin/env ruby
if !defined?(App)
  defined? ENV['RAILS_ENV'] ? RAILS_ENV = ENV['RAILS_ENV'] : 'production' # necesario para testing
  require File.dirname(__FILE__) + '/../config/environment'
end
require File.dirname(__FILE__) + '/../app/controllers/application'
class FQDb < ActiveRecord::Base; end

FQDb.establish_connection(
                          :adapter  => "mysql",
:host     => "localhost",
:username => "root",
:password => "",
:database => "fq",
:encoding => 'utf8'
)


users_ids = []

def import_users(users_ids)
  FQDb.db_query("SELECT * FROM users ORDER BY uid").each do |dbu|
    dbc = {:login => dbu['name'],
      :password => dbu['pass'],
      :email => dbu['mail'],
      :created_on => Time.at(dbu['created'].to_i),
      :lastseen_on => Time.at(dbu['changed'].to_i),
    }
    # TODO picture
    users_ids[dbu['uid'].to_i] = Import::Users.import(dbc)
  end
end

#def import_privatemsg(users_ids)
#  
#end

# contents
def import_blogs(users_ids)
  FQDb.db_query("SELECT * FROM node where type = 'blog'").each do |dbn|
    node_stats = FQDb.db_query("SELECT * FROM node_counter where nid = #{dbn['nid']}") 
    
    dbc = {:title => dbn['title'],
      :content => Comments.formatize(dbn['body'].gsub("\r", "\n")),
      :created_on => Time.at(dbn['created'].to_i),
      :updated_on => Time.at(dbn['changed'].to_i),
      :user_id => users_ids[dbn['uid'].to_i],
      :state => Cms::PUBLISHED
    }
    
    if node_stats.size > 0
      dbc[:hits_anonymous] = node_stats[0]['totalcount'].to_i
    end
    begin
      b = Import::Contents.import(dbc, Blogentry)
    rescue
      dbc[:content] = Iconv.iconv('utf-8//IGNORE', 'ascii', dbc[:content] + ' ')[0]
      dbc[:title] = Iconv.iconv('utf-8//IGNORE', 'ascii', dbc[:title] + ' ')[0]
      b = Import::Contents.import(dbc, Blogentry)
    end
    
    u = b.user
    old = u.notifications_trackerupdates
    u.notifications_trackerupdates = false
    u.save
    FQDb.db_query("SELECT * FROM comments where nid = #{dbn['nid']}").each do |dbco|
      nc = { :comment => Comments.formatize(dbco['comment'].gsub("\r", "\n")),
        :content_id => b.unique_content.id,
        :host => dbco['hostname'],
        :created_on => Time.at(dbco['timestamp'].to_i),
        :updated_on => Time.at(dbco['timestamp'].to_i),
        :user_id => users_ids[dbco['uid'].to_i]
      } 
      begin
        Import::Contents.import(nc, Comment)
      rescue
        
        nc[:comment] = Iconv.iconv('utf-8//IGNORE', 'ascii', nc[:comment] + ' ')[0]
        puts "Imposible importar comentario: #{nc[:comment]}"
        Import::Contents.import(nc, Comment)
      end
    end
    if old != u.notifications_trackerupdates
      u.notifications_trackerupdates = old
      u.save
    end
    
  end
end

def import_event(users_ids)
  FQDb.db_query("SELECT * FROM node where type = 'event'").each do |dbn|
    node_stats = FQDb.db_query("SELECT * FROM node_counter where nid = #{dbn['nid']}")
    dbei = FQDb.db_query("SELECT * FROM event where nid = #{dbn['nid']}")[0]
    
    dbc = {:name => dbn['title'],
      :description => Comments.formatize(dbn['body'].gsub("\r", "\n")),
      :created_on => Time.at(dbn['created'].to_i),
      :updated_on => Time.at(dbn['changed'].to_i),
      :starts_on => Time.at(dbei['event_start'].to_i),
      :ends_on => Time.at(dbei['event_end'].to_i),
      :events_category_id => EventsCategory.find_by_code('q3a').id,
      :user_id => users_ids[dbn['uid'].to_i],
      :state => Cms::PUBLISHED
    }
    
    if node_stats.size > 0
      dbc[:hits_anonymous] = node_stats[0]['totalcount'].to_i
    end
    b = Import::Contents.import(dbc, Event)
    u = b.user
    old = u.notifications_trackerupdates
    u.notifications_trackerupdates = false
    u.save
    FQDb.db_query("SELECT * FROM comments where nid = #{dbn['nid']}").each do |dbco|
      nc = { :comment => Comments.formatize(dbco['comment'].gsub("\r", "\n")),
        :content_id => b.unique_content.id,
        :host => dbco['hostname'],
        :created_on => Time.at(dbco['timestamp'].to_i),
        :updated_on => Time.at(dbco['timestamp'].to_i),
        :user_id => users_ids[dbco['uid'].to_i]
      } 
      begin
        Import::Contents.import(nc, Comment)
      rescue
        puts "Imposible importar comentario: #{dbco['comment']}"
      end
    end
    if old != u.notifications_trackerupdates
      u.notifications_trackerupdates = old
      u.save
    end
  end
end

def import_forum(users_ids)
  tc4q = TopicsCategory.find_by_code('4quakers')
  if tc4q.nil?
    q3a = TopicsCategory.find_by_code('q3a')
    tc4q = q3a.children.create({:name => '4Quakers', :code => '4quakers'})
  end
  FQDb.db_query("SELECT * FROM node where type = 'forum'").each do |dbn|
    node_stats = FQDb.db_query("SELECT * FROM node_counter where nid = #{dbn['nid']}")
    
    dbc = {:title => dbn['title'],
      :text => Comments.formatize(dbn['body'].gsub("\r", "\n")),
      :created_on => Time.at(dbn['created'].to_i),
      :updated_on => Time.at(dbn['changed'].to_i),
      :topics_category_id => tc4q.id,
      :user_id => users_ids[dbn['uid'].to_i],
      :state => Cms::PUBLISHED
    }
    
    if node_stats.size > 0
      dbc[:hits_anonymous] = node_stats[0]['totalcount'].to_i
    end
    b = Import::Contents.import(dbc, Topic)
    u = b.user
    old = u.notifications_trackerupdates
    u.notifications_trackerupdates = false
    u.save
    FQDb.db_query("SELECT * FROM comments where nid = #{dbn['nid']}").each do |dbco|
      nc = { :comment => Comments.formatize(dbco['comment'].gsub("\r", "\n")),
        :content_id => b.unique_content.id,
        :host => dbco['hostname'],
        :created_on => Time.at(dbco['timestamp'].to_i),
        :updated_on => Time.at(dbco['timestamp'].to_i),
        :user_id => users_ids[dbco['uid'].to_i]
      } 
      begin
        Import::Contents.import(nc, Comment)
      rescue
        puts "Imposible importar comentario: #{dbco['comment']}"
      end
    end
    if old != u.notifications_trackerupdates
      u.notifications_trackerupdates = old
      u.save
    end
  end
end

def import_image(users_ids)
  
end

def import_news_page(users_ids)
  q3a = NewsCategory.find_by_code('q3a')
  FQDb.db_query("SELECT * FROM node where type = 'news_page'").each do |dbn|
    node_stats = FQDb.db_query("SELECT * FROM node_counter where nid = #{dbn['nid']}")
    
    dbc = {:title => dbn['title'],
      :summary => Comments.formatize(dbn['body'].gsub("\r", "\n")),
      :created_on => Time.at(dbn['created'].to_i),
      :updated_on => Time.at(dbn['changed'].to_i),
      :news_category_id => q3a.id,
      :user_id => users_ids[dbn['uid'].to_i],
      :state => Cms::PUBLISHED
    }
    
    if node_stats.size > 0
      dbc[:hits_anonymous] = node_stats[0]['totalcount'].to_i
    end
    b = Import::Contents.import(dbc, News)
    u = b.user
    old = u.notifications_trackerupdates
    u.notifications_trackerupdates = false
    u.save
    FQDb.db_query("SELECT * FROM comments where nid = #{dbn['nid']}").each do |dbco|
      nc = { :comment => Comments.formatize(dbco['comment'].gsub("\r", "\n")),
        :content_id => b.unique_content.id,
        :host => dbco['hostname'],
        :created_on => Time.at(dbco['timestamp'].to_i),
        :updated_on => Time.at(dbco['timestamp'].to_i),
        :user_id => users_ids[dbco['uid'].to_i]
      } 
      begin
        Import::Contents.import(nc, Comment)
      rescue
        puts "Imposible importar comentario: #{dbco['comment']}"
      end
    end
    if old != u.notifications_trackerupdates
      u.notifications_trackerupdates = old
      u.save
    end
  end
end

def import_poll(users_ids)
  
end

actions = %w(users blogs)
f_users_ids = "4quakers.com_users_ids.yml"
if !File.exists?(f_users_ids)
  import_users(users_ids)
  File.open("4quakers.com_users_ids.yml", "w") { |f| f.write(users_ids.to_yaml) }
else
  users_ids = YAML::load(File.open("4quakers.com_users_ids.yml"))
end

import_blogs(users_ids)
import_event(users_ids)
import_forum(users_ids)
import_news_page(users_ids)
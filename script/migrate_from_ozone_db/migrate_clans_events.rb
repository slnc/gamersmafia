#!/usr/bin/env ruby
defined? ENV['RAILS_ENV'] ? RAILS_ENV = ENV['RAILS_ENV'] : 'production' # necesario para testing
require File.dirname(__FILE__) + '/../config/environment'

class Oz < ActiveRecord::Base; end
def safe_str(str)
  Oz.connection.quote(str.to_s)
  # str.to_s.gsub('\\', '\\\\\\').gsub('\'', '\\\\\'')
  #str
end
# p safe_str("el Amigo ' lopez")

# raise 'fuck'
Oz.establish_connection( :adapter  => 'postgresql',
                         :host     => 'localhost',
                         :username => 'postgres',
                         :password => 'ic4ro69',
                         :database => 'gm_ozone2'
                        )


ctype_id = ContentType.find_by_name('ClansEvent').id
Clan.db_query("DELETE FROM clans_events")

Oz.db_query("select a.* from celements_events a join subcommunities b on a.subcommunity_id = b.id where subcommunity_id IN (select id from subcommunities where type_id = 2)").each do |dbn|
  clan_id = Oz.db_query("SELECT id FROM clans WHERE name = (SELECT name FROM subcommunities WHERE id = #{dbn['subcommunity_id']})")
  next if clan_id.size == 0
  clan_id = clan_id[0]['id']

  next if not Clan.find_by_id(clan_id)

  Clan.db_query("INSERT INTO clans_events(id, 
                                        created_on, 
                                        updated_on, 
                                        user_id, 
                                        hits_registered, 
                                        hits_anonymous, 
                                        cache_comments_count, 
                                        state, 
                                        clan_id, 
                                        name, 
                                        description,
                                        website,
                                        starts_on,
                                        ends_on) 
                                VALUES (#{dbn['id']},
                                        '#{dbn['creation_tstamp']}',
                                        '#{dbn['lastupdate_tstamp']}',
                                        #{dbn['author_user_id']},
                                        #{dbn['hits_registered']},
                                        #{dbn['hits_anonymous']},
                                        #{dbn['_cache_comments_count'] || 0},
                                        #{Cms::PUBLISHED},
                                        #{clan_id},
                                        #{safe_str(dbn['name'])}, 
                                        #{safe_str(dbn['description'])},
                                        #{safe_str(dbn['website'])},
                                        #{safe_str(dbn['timestamp_start'])},
                                        #{safe_str(dbn['timestamp_end'])})")

  new_content_id = Content.db_query("INSERT INTO contents(content_type_id, external_id, updated_on, name, comments_count, is_public, state, clan_id)
                                                   VALUES(#{ctype_id}, #{dbn['id']}, '#{dbn['lastupdate_tstamp']}', #{safe_str(dbn['name'])}, #{dbn['_cache_comments_count'] || 0}, 't', #{Cms::PUBLISHED}, #{clan_id}); SELECT id FROM contents order by id desc limit 1;")[0]['id']

  # comments
  Oz.db_query("SELECT * FROM comments_celements_events where item_id = #{dbn['id']}").each do |dbc|
    next if User.find_by_id(dbc['user_id']).nil?
    Comment.db_query("INSERT INTO comments (content_id, user_id, host, created_on, updated_on, comment)
                            VALUES (#{new_content_id}, #{dbc['user_id']}, '#{dbc['host']}', '#{dbc['timestamp']}', '#{dbc['timestamp']}', #{safe_str(dbc['comment'])})")
  end
end

max = Clan.db_query("select max(id) FROM clans_events")[0]['max'].to_i + 1
Clan.db_query("alter sequence clans_events_id_seq RESTART #{max}")

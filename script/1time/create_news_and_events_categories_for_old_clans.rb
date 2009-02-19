ClansNews
ClansEvent
ClansTopic

Clan.find(:all, :conditions => 'simple_mode is false').each do |clan|
  if not ClansNewsCategory.find(:first, :conditions => ['name = ? AND code = ? and clan_id = ?', clan.name, clan.tag, clan.id])
    new_cat = ClansNewsCategory.create({:name => clan.name, :code => clan.tag, :clan_id => clan.id})
    User.db_query("UPDATE clans_news SET clans_news_category_id = #{new_cat.id} WHERE clan_id = #{clan.id}")
    puts "creating newscategory for #{clan}"
  end

  if not ClansEventsCategory.find(:first, :conditions => ['name = ? AND code = ? and clan_id = ?', clan.name, clan.tag, clan.id])
    new_cat2 = ClansEventsCategory.create({:name => clan.name, :code => clan.tag, :clan_id => clan.id})
    User.db_query("UPDATE clans_events SET clans_events_category_id = #{new_cat2.id} WHERE clan_id = #{clan.id}")
    puts "creating eventscategory for #{clan}"
  end

  [ClansTopicsCategory, ClansDownloadsCategory, ClansImagesCategory].each do |cls|
    if not cls.find(:first, :conditions => ['name = ? AND code = ? and clan_id = ?', clan.name, clan.tag, clan.id])
      new_cat2 = cls.create({:name => clan.name, :code => clan.tag, :clan_id => clan.id})
      puts "creating #{cls.name} for #{clan}"
    else
      new_cat2 = cls.find(:first, :conditions => ['name = ? AND code = ? and clan_id = ?', clan.name, clan.tag, clan.id])
    end
    User.db_query("UPDATE #{ActiveSupport::Inflector::tableize(cls.name)} SET root_id = #{new_cat2.id} WHERE clan_id = #{clan.id}")
    User.db_query("UPDATE #{ActiveSupport::Inflector::tableize(cls.name)} SET parent_id = #{new_cat2.id} WHERE clan_id = #{clan.id} AND parent_id is null and id <> #{new_cat2.id}")
  end
end

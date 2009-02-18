Topic.find(:all, :conditions => 'topics_category_id > 1173', :order => 'id ASC').each do |t|
  if t.cache_comments_count > 0 then
    lastc = t.unique_content.comments.find(:first, :order => 'created_on DESC')
    d = lastc ? lastc.created_on : t.created_on
  else
    d = t.created_on
  end
    User.db_query("UPDATE topics SET updated_on = '#{d.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{t.id}")
    User.db_query("UPDATE contents SET created_on = '#{t.created_on.strftime('%Y-%m-%d %H:%M:%S')}', updated_on = '#{d.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{t.unique_content.id}")
end


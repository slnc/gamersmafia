Blogentry.find_all.each do |be|
  be.cache_comments_count = be.unique_content.comments_count
  be.updated_on = be.created_on

  if be.cache_comments_count > 1 then
    be.updated_on = be.comments.find(:first, :order => 'created_on DESC')
  end
  be.save
end

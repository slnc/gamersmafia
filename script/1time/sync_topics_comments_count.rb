TopicsCategory.find(:all).each do |tc|
  child_cats = tc.get_all_children
  child_cats<< tc.id
  sum = User.db_query("SELECT sum(cache_comments_count) FROM topics WHERE topics_category_id IN (#{child_cats.join(',')})")[0]['sum']
  if sum.to_i != tc.comments_count
    puts "before: #{tc.comments_count} | after: #{sum}" 
    User.db_query("UPDATE topics_categories set comments_count = #{sum.to_i} WHERE id = #{tc.id}")
  end
end
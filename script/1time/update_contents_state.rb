Content.find(:all).each do |c|
  begin
    rc = c.real_content 
  rescue Exception
  else
    if rc.deleted
      new_state = Cms::DELETED
    elsif (not rc.respond_to?(:approved_by_user_id)) || rc.approved_by_user_id
      new_state = Cms::PUBLISHED
    else
      new_state = Cms::PENDING
    end
    User.db_query("UPDATE contents SET state = #{new_state} WHERE id = #{c.id}; UPDATE #{Inflector::tableize(rc.class.name)} SET state = #{new_state} WHERE id = #{rc.id}")
  end
end

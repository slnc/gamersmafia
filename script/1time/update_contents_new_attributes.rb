Content.find(:all, :conditions => 'game_id IS NULL AND clan_id IS NULL').each do |c|
  begin
    rc = c.real_content
    g_id = rc.get_platform_id 
#    is_public = rc.is_public?
    User.db_query("UPDATE contents SET platform_id = #{g_id} WHERE id = #{c.id}") if g_id
#    User.db_query("UPDATE contents SET is_public = #{is_public} WHERE id = #{c.id}")
  rescue Exception
  end
end

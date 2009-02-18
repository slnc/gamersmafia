
Content.find(:all, :conditions => 'game_id IS NULL AND clan_id IS NULL AND platform_id IS NULL').each do |c|
  begin
    rc = c.real_content
  rescue ActiveRecord::RecordNotFound
    
  else
    g_id = rc.get_my_platform_id 
    User.db_query("UPDATE contents SET platform_id = #{g_id} WHERE id = #{c.id}") if g_id
    puts "contenido de plataforma encontrado!" if g_id
  end  
end

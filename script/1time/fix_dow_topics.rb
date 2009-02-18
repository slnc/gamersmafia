require 'iconv'
Topic.find(:all, :conditions => 'topics_category_id > 1173 AND id NOT IN (18375, 18349, 18366, 18555, 18554, 18540, 18541)', :order => 'id ASC').each do |t|
  puts t.id
  begin
    #puts "UPDATE topics SET title = #{User.connection.quote(Iconv::iconv('iso-8859-1','UTF-8', t.title)[0])}, text = #{User.connection.quote(Iconv::iconv('iso-8859-1','UTF-8', t.text)[0])} WHERE id = #{t.id}"
    User.db_query("UPDATE topics SET title = #{User.connection.quote(Iconv::iconv('iso-8859-1','UTF-8', t.title)[0])}, text = #{User.connection.quote(Iconv::iconv('iso-8859-1','UTF-8', t.text)[0])} WHERE id = #{t.id}")
    User.db_query("UPDATE contents SET title = #{User.connection.quote(Iconv::iconv('iso-8859-1','UTF-8', t.title)[0])}, updated_on = '#{t.updated_on.strftime('%Y-%m-%d %H:%m:%S')}', created_on = '#{t.created_on.strftime('%Y-%m-%d %H:%m:%S')}'  WHERE id = #{t.unique_content.id}")
  rescue Iconv::IllegalSequence => errstr:
    puts "Iconv::IllegalSequence"
    puts errstr.to_s
  rescue ActiveRecord::StatementInvalid => errstr:
    puts "ActiveRecord::StatementInvalid"
    puts errstr.to_s
  end


  t.unique_content.comments.each do |c|
    begin
      #puts "UPDATE comments SET comment = #{User.connection.quote(Iconv::iconv('iso-8859-1','UTF-8', c.comment)[0])} WHERE id = #{c.id}"
      User.db_query("UPDATE comments SET comment = #{User.connection.quote(Iconv::iconv('iso-8859-1','UTF-8', c.comment)[0])} WHERE id = #{c.id}")
    rescue Iconv::IllegalSequence => errstr:
      puts "Iconv::IllegalSequence"
      puts errstr.to_s
    rescue ActiveRecord::StatementInvalid => errstr:
      puts "ActiveRecord::StatementInvalid"
      puts errstr.to_s
    end
  end
  #rescue ActiveRecord::StatementInvalid:
  #puts "Error al actualizar este"
  #rescue Iconv::IllegalSequence:
  #puts "Error en esta secuencia, ignoranding"
  #end
end

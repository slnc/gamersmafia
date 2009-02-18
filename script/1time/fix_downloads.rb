i = 0
j = 0
for d in Download.find(:all, :conditions => "path is not null and path not like '%None' and id not in(select download_id from download_mirrors)")
  d_real_path = d.path.gsub(/\/storage/, "/home/httpd/websites/gamersmafia.com/public/storage")
  if not File.exists?(d_real_path)
   puts "file not found (#{d.id}): #{d_real_path}"
    f_name = d_real_path.match(/([^\/]+)$/)[0]
    cmd = open("|/usr/bin/locate '#{f_name}'")
    locate_out = cmd.gets.to_s.strip
    cmd.close
    if locate_out.match('gamersmafia.bak')
      puts "encontrado #{f_name} archivo huérfano, apunto de mover #{locate_out} a #{d_real_path}"
      File.rename(locate_out, d_real_path)
      i += 1
    else
      puts "no se ha encontrado archivo huérfano"
      j += 1
    end
  end
end
puts "#{i} archivos movidos correctamente"
puts "#{j} archivos totalmente huérfanos"

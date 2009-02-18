Dir.glob("/home/httpd/users/*").each do |dir|
  next unless File.exists?("#{dir}/profile/portrait.jpg") 
  u = User.find(:first, :conditions => ['id = ? and photo = \'bogus\'', File.basename(dir)])
  next unless u
  # move photo to new path
  new_path = "storage/users/#{u.id % 1000}/#{u.id}_portrait.jpg"
  full = "#{RAILS_ROOT}/public/#{new_path}"
  FileUtils.mkdir_p(File.dirname(full)) unless File.exists?(File.dirname(full)) 
  raise "fuck! #{full}" if File.exists?(full)
  FileUtils.cp("#{dir}/profile/portrait.jpg", full)
  User.db_query("UPDATE users SET photo = '#{new_path}' WHERE id = #{u.id}")
  puts "updated photo for user #{u.login} (#{u.id})"
end

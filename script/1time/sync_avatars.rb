User.find(:all, :conditions => 'avatar_id IS NOT NULL').each do |u|
  u.change_avatar(u.avatar_id)
end

User.find(:all, :conditions => 'avatar_id IS NULL').each do |u|
  r_path = Pathname.new(RAILS_ROOT).realpath # NO USAR RAILS_ROOT DIRECTAMENTE EGGS
  src = "#{r_path}/public/images/default_avatar.jpg"
  
  dst = "#{r_path}/public/storage/users_avatars/#{u.id%100}/#{u.id}.jpg"
  
  if not File.exists?(File.dirname(dst)) then
    FileUtils.mkdir_p File.dirname(dst)
  end
  
  
  File.unlink(dst) if File.symlink?(dst)
  File.symlink(src, dst)
end
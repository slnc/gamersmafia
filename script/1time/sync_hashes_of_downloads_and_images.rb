require 'digest/md5'
def file_hash(somefile)
  md5_hash = ''
  File.open(somefile) do |f| # binmode es vital por los saltos de línea y win/linux
    f.binmode
    md5_hash = Digest::MD5.hexdigest(f.read)
  end
  md5_hash
end
    
    i = 0
    Download.find(:all, :conditions => 'file IS NOT NULL and file_hash_md5 is null').each do |d|
      full_file = "#{RAILS_ROOT}/public/#{d.file}"
      if File.exists?(full_file)
        User.db_query("UPDATE downloads SET file_hash_md5 = '#{file_hash(full_file)}' WHERE id = #{d.id}")
        puts "#{d.name} updated"
      end
      i += 1
      if i % 25 == 0
        GC.start 
        puts i
      end
    end
    
    i = 0
    Image.find(:all, :conditions => 'image IS NOT NULL and image_hash_md5 is null').each do |d|
      full_file = "#{RAILS_ROOT}/public/#{d.image}"
      if File.exists?(full_file)
        User.db_query("UPDATE images SET image_hash_md5 = '#{file_hash(full_file)}' WHERE id = #{d.id}")
        # puts "#{d.image} updated"
      end
      i += 1
      if i % 25 == 0
        GC.start 
        puts i
      end
    end
    
-- eliminar duplicados y hacer los hashes únicos
-- no permitir subir imágenes, descargas con hashes duplicados (validation)
    

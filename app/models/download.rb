require 'digest/md5'

class Download < ActiveRecord::Base
  MIRRORS_REQUEST = ["http://#{App.domain}/dauth", "http://descargas.newlightsystems.com/GM/auth_download.php"]
  MIRRORS_DOWNLOAD = ["http://#{App.domain}/", "http://descargas.newlightsystems.com/GM/"]
  VALID_DOWNLOAD_COOKIE = /^[a-z0-9]{32}$/
  acts_as_content
  acts_as_categorizable
  
  has_many :downloaded_downloads
  
  has_many :download_mirrors, :dependent => :destroy
  belongs_to :image_category
  
  # TODO arreglar este lío y hacerlo en todos los contents con categoría
  file_column :file
  #  before_save :check_uploaded_file
  
  # TODO esto debería hacerlo silencecore_file_column
  #  def check_uploaded_file
  #    if @tmp_files['file']
  #      tmp_file = @tmp_files['file']
  #      if tmp_file.respond_to?('path') and tmp_file.path.to_s != '' then
  #        new_hash = file_hash(tmp_file.path)
  #      else # file size < 19Kb (es un StringIO)
  #        new_hash = Digest::MD5.hexdigest(tmp_file.read)
  #        tmp_file.rewind
  #      end
  #
  #      self.errors.add('file', 'El archivo especificado ya existe')
  #      Download.count(:conditions => ['file_hash_md5 = ?', new_hash]) == 0      
  #    end
  #  end
  
  
  # select id, (select name from downloads_categories where id = a.root_id), downloads_count from downloads_categories a where lower(name) like  '%demos%' and downloads_count > 0;
  def mute_to_demo
    opts = self.attributes
    
    opts['demos_category_id'] = DemosCategory.find_by_code(self.downloads_category.root.code).id
    opts['games_mode_id'] = Game.find_by_code(self.downloads_category.root.code).games_modes.find(:first).id
    
    %w(downloads_category_id clan_id essential).each do |attr|
      opts.delete attr  
    end
    
    if self.file_hash_md5 && Demo.find_by_file_hash_md5(self.file_hash_md5)
      raise "Ya hay otra demo con este hash: #{self.file_hash_md5}"
    end
    demo = Demo.new(opts)
    demo.changed
    demo.entity1_external = self.title
    demo.entity2_external = self.title
    raise "Error al guardar la demo: #{demo.errors.full_messages}" unless demo.save
    User.db_query("UPDATE demos SET created_on = '#{opts['created_on'].strftime('%Y-%m-%d %H:%M:%S')}', updated_on = '#{opts['updated_on'].strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{demo.id}")
    ucdownload = self.unique_content
    ucdemo = demo.unique_content
    User.db_query("UPDATE contents SET external_id = 50000 + id WHERE id = #{ucdownload.id}")
    User.db_query("UPDATE contents SET external_id = 50000 + id WHERE id = #{ucdemo.id}")
    User.db_query("UPDATE contents SET content_type_id = (select id from content_types where name = 'Demo'), external_id = #{demo.id} WHERE id = #{ucdownload.id}")
    User.db_query("UPDATE contents SET content_type_id = (select id from content_types where name = 'Download'), external_id = #{self.id} WHERE id = #{ucdemo.id}")
    self.destroy
  end
  
  def self.create_symlink(cookie, download_file, mirror=nil)
    # crea un symlink con la cookie dada al archivo dado o bien en un host remoto o bien en local
    # si es local lo crea en public/d/#{cookie}/#{File.basename(download.file)}
    # mirror=nil means a local request, for testing purposes
    download = Download.find_by_file(download_file)
    raise ActiveRecord::RecordNotFound unless download 
    realfile = "#{RAILS_ROOT}/public/#{download.file}"
    mirror = nil if RAILS_ENV == 'test' # && !mirror.nil?
    
    raise ActiveRecord::RecordNotFound if download.new_record? || (!File.exists?(realfile)) || !File.file?(realfile)
    raise "invalid cookie chars: #{cookie}" unless Download::VALID_DOWNLOAD_COOKIE =~ cookie
    dstdir = "#{RAILS_ROOT}/public/storage/d/#{cookie}"
    if mirror.nil?
      FileUtils.mkdir_p(dstdir) unless File.exists?(dstdir)
      dstfile = "#{dstdir}/#{File.basename(realfile)}"
      File.symlink(realfile, dstfile) unless File.exists?(dstfile) || App.windows?
    else
      require 'open-uri'
      # TODO hacer un megabegin
      begin
        out = open("#{Download::MIRRORS_REQUEST[mirror]}?gmk=#{App.mirror_auth_key}&ddc=#{cookie}&f=#{download.file}").read
      rescue
        out = '0'
      end
      if out != '1'
        mirror = nil
        create_symlink(cookie, download_file)
        # TODO log raise "Error descargando desde NLS, defaulting a GM: #{out}"
      end
      mirror
    end
  end
  
  def self.check_invalid_downloads
    Download.find(:all, :conditions => ['state = ? AND file is NOT NULL and file <> \'\'', Cms::PUBLISHED], :order => 'id DESC').each do |d|
      if !File.exists?("#{RAILS_ROOT}/public/#{d.file}") && d.download_mirrors.count == 0
        puts "#{d.id.to_s.ljust(6, ' ')} #{d.file}"
        # TODO deshabilitado por precaución User.db_query("UPDATE downloads SET file = NULL WHERE id = #{d.id}")
      end
    end and nil
  end
  
  def self.check_orphaned_downloads
    
    Download.find(:all, :conditions => ['state = ? AND (file is NULL OR file = \'\') AND (select count(*) from download_mirrors where download_id = downloads.id) = 0', Cms::PUBLISHED], :order => '(select root_id FROM downloads_categories where id = downloads.downloads_category_id), id DESC').each do |d|
      puts "#{ApplicationController.gmurl(d).ljust(55, ' ')} #{d.title}"
    end and nil
  end
end # Download.find(1442).mute_to_demo ||||||| REACTIVAR file_column a demo después

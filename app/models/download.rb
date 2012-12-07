# -*- encoding : utf-8 -*-
# ContentAttribute:
# - downloaded_times (int)
# - essential (bool)
# - file_hash_md5 (varchar)
# - file (varchar)
require 'digest/md5'

class Download < ActiveRecord::Base
  MIRRORS_REQUEST = ["http://#{App.domain}/dauth"] #, "http://descargas.newlightsystems.com/GM/auth_download.php"]
  MIRRORS_DOWNLOAD = ["http://#{App.domain}/"] #, "http://descargas.newlightsystems.com/GM/"]
  VALID_DOWNLOAD_COOKIE = /^[a-z0-9]{32}$/
  acts_as_content
  acts_as_categorizable

  has_many :downloaded_downloads

  has_many :download_mirrors, :dependent => :destroy
  belongs_to :image_category

  file_column :file

  after_save :process_download_mirrors

  def mirrors_new=(opts_new)
    @_tmp_mirrors_new = opts_new
    self.attributes.delete :mirrors_new
  end

  def mirrors_delete=(opts_new)
    @_tmp_mirrors_delete = opts_new
    self.attributes.delete :mirrors_delete
  end

  def mirrors=(opts_new)
    @_tmp_mirrors = opts_new
    self.attributes.delete :mirrors
  end

  def process_download_mirrors
    if @_tmp_mirrors_new
      @_tmp_mirrors_new.each { |s| self.download_mirrors.create({:url => s.strip}) unless s.strip == ''  }
      @_tmp_mirrors_new = nil
    end

    if @_tmp_mirrors_delete
      @_tmp_mirrors_delete.each { |id| self.download_mirrors.find(id).destroy if self.download_mirrors.find_by_id(id) }
      @_tmp_mirrors_delete = nil
    end

    if @_tmp_mirrors
      @_tmp_mirrors.keys.each do |id|
        mirror = self.download_mirrors.find_by_id(id.to_i)
        if mirror && mirror.url != @_tmp_mirrors[id]
          mirror.url = @_tmp_mirrors[id].strip
          mirror.save
        end
      end
      @_tmp_mirrors = nil
    end
    true
  end

  def self.create_symlink(cookie, download_file, mirror=nil)
    # crea un symlink con la cookie dada al archivo dado o bien en un host remoto o bien en local
    # si es local lo crea en public/d/#{cookie}/#{File.basename(download.file)}
    # mirror=nil means a local request, for testing purposes
    download = Download.find_by_file(download_file)
    raise ActiveRecord::RecordNotFound unless download
    realfile = "#{Rails.root}/public/#{download.file}"
    mirror = nil if Rails.env == 'test' # && !mirror.nil?

    if download.new_record? || (!File.exists?(realfile)) || !File.file?(realfile)
      Rails.logger.warn(
        "Requested download '#{download}' has no real file:" +
        " #{download.new_record?} || #{(!File.exists?(realfile))} ||" +
        " #{!File.file?(realfile)}")
      raise ActiveRecord::RecordNotFound
    end
    raise "invalid cookie chars: #{cookie}" unless Download::VALID_DOWNLOAD_COOKIE =~ cookie
    dstdir = "#{Rails.root}/public/storage/d/#{cookie}"
    if mirror.nil?
      FileUtils.mkdir_p(dstdir) unless File.exists?(dstdir)
      dstfile = "#{dstdir}/#{File.basename(realfile)}"
      File.symlink(realfile, dstfile) unless File.exists?(dstfile)
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
    u = User.find_by_login('MrAchmed')
    Download.find(:all, :conditions => ['state = ?', Cms::PUBLISHED], :order => 'id DESC').each do |d|
      if d.file.to_s != '' && !File.exists?("#{Rails.root}/public/#{d.file}") && d.download_mirrors.count == 0
        d.update_attributes(:file => nil)
      end

      if d.file.nil? && d.download_mirrors.count == 0
        ttype, scope = Alert.fill_ttype_and_scope_for_content_report(d)
        sl = Alert.create({:scope => scope, :type_id => ttype, :reporter_user_id => u.id, :headline => "#{Cms.faction_favicon(d)}<strong><a href=\"#{Routing.url_for_content_onlyurl(d)}\">#{d.id}</a></strong> reportado (Ni descarga directa ni mirrors) por <a href=\"#{Routing.gmurl(u)}\">#{u}</a>"})
      end
    end and nil
  end

  def to_s
    "Download: id: #{self.id} title:#{self.title} file:#{self.file}"
  end
end

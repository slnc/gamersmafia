class Skin < ActiveRecord::Base
  has_and_belongs_to_many :portals
  has_many :skin_textures
  
  file_column :file
  file_column :intelliskin_header
  file_column :intelliskin_favicon
  observe_attr :file
  
  before_save :update_version_if_file_changed
  after_save :check_file_changed
  after_create :setup_initial_zip

  validates_uniqueness_of :name

  has_hid
  
  CGEN_CSS_START = '/* COLOR GEN START - DO NOT REMOVE */'
  CGEN_CSS_END = '/* COLOR GEN END - DO NOT REMOVE */'
  
  def self.extract_css_imports(s)
    out = []
    while s.length > 0
      m = s.match(/^(@import url\(([a-zA-Z0-9_\/.-]+)\))/)
      if m && (/\.css$/ =~ m[2]) 
        sss = m[2]
        out<< sss
        s = s[m[1].length..s.length]
      else
        s = ''
      end
    end
    sssssssssss = out.join("\n")
    out
  end
  
  def self.rextract_css_imports(base_file_name)
    # This function will recursively extract all the @imports inside 
    # and return a big string with all the @imports contents 
    f_contents = File.open(base_file_name).read
    
    imports = extract_css_imports(f_contents)
    out = f_contents
    imports.each do |import|
      # TODO Higher Security?
      full = "#{RAILS_ROOT}/public#{import[0..import.length]}" if import[0..0] == '/'
      fname = (import[0..0] == '/' || import[1..1] == ':') ? full : "#{File.dirname(base_file_name)}/#{import}"
      import_contents = self.rextract_css_imports(fname)
      import_contents.gsub!(/(url\(([^\/]{1}))/, "url(#{File.dirname(fname).gsub(RAILS_ROOT, '').gsub('public/', '')}/\\2")
      # reemplazamos urls relativas por absolutas
      if import[0..0] != '/' then # asumimos que este import es relativo
        # miramos cuantas / hay y quitamos los ../ necesarios
        #import.count('/').times do
        #  import_contents.gsub!('url(../', 'url(') # quitamos un nivel de anidamiento
        #end
        import_contents.gsub!('url(/storage/gs.png)', "url(/storage/gs.png?#{SVNVERSION})")
      end
      out.gsub!("@import url(#{import});", import_contents)
    end
    out
  end
  
  def self.find_by_hid(hid)
    if %w(arena default bazar).include?(hid)
      Skin.new({:name => hid, :hid => hid, :version => SVNVERSION})
    else
      super(hid)
    end
  end
  
  public
    
  def remove_skin_texture(sk)
    clean_style_file(*sk.texture.markers)
    sk.destroy
    save_config
  end
  
  def is_intelliskin?
    config[:intelliskin]
  end
  
  # Devuelve los includes a usar para esta skin
  def css_include
    if App.compress_skins?
      "#{uripath}/style_compressed.#{version}.css"
    else
      "#{uripath}/style.#{version}.css"
    end
  end
  
  
  def gen_compressed
    fpath = "#{realpath}/style.css"
    compressed = "#{realpath}/style_compressed.css"
    data = Skin.rextract_css_imports(fpath)
    data.gsub!('url(/', "url(#{ASSET_URL}/")
    File.open(compressed, 'w') { |f| f.write(data) }
    `java -jar script/yuicompressor-2.3.6.jar "#{compressed}" -o "#{compressed}" --line-break 500`
  end
  
  #  def update_intelliskin(new_params)
  #    config.merge!(new_params)
  #    save_config
  #  end
  
  def update_favicon(mixed_thing)
    if mixed_thing
      File.open("#{RAILS_ROOT}/public/storage/skins/#{self.hid}/favicon.png", 'wb') do |f|
        f.write(mixed_thing.read) # TODO write as ico file too
      end
    end
  end
  
  
  def config
    @__cache_config ||= HashWithIndifferentAccess.new(YAML::load(File.open("#{realpath}/config.yml") { |f| f.read }))
  end
  
  # Solo la vamos a llamar cuando la skin es intelliskin
  def save_config
    config # necesario ponerlo aquí
    self.version += 1
    self.save
    File.open("#{realpath}/config.yml", 'w') { |f| f.write(YAML::dump(config)) }
    build_skin
    # inject_into_css("#mggmtv { height: #{config[:intelliskin][:header_height]}px};", APPEND) if config[:intelliskin][:header_height]
    true
  end
  
  
  def clean_style_file(start_marker, end_marker)
    style_css = File.open("#{realpath}/style.css") { |f| f.read }
    
    if style_css.index(start_marker) && style_css.index(end_marker)
      style_css = "#{style_css[0..(style_css.index(start_marker)-1)]}#{style_css[(style_css.index(end_marker)+end_marker.size)..style_css.size]}"
      style_css.gsub!("\n\n", "\n")
      File.open("#{realpath}/style.css", 'w') { |f| f.write(style_css) }
    end
  end
  
  def config_intelliskin
    self.config[:intelliskin] = {} if config[:intelliskin].nil?
    self.config[:intelliskin]
  end
  
  
  private
  def setup_initial_zip
    template = case self.class.name
      when 'ClansSkin':
        'clan'
      when 'FactionsSkin':
        'default'
    else
      raise "#{self.class.name} unsupported skin type"
    end
    
    # Tengo que crear el .zip inicial con la template
    cfg_dir = Pathname.new("#{RAILS_ROOT}\/config/skins/template_#{template}").realpath.to_s
    cfg_dir.gsub!('/', '\\') if App.windows?
    dst_file = Pathname.new("#{RAILS_ROOT}/public/storage/skins").realpath.to_s << "/#{self.hid}_initial.zip"
    dst_file.gsub!('/', '\\') if App.windows?
    system("cd \"#{cfg_dir}\" && zip -q -r \"#{dst_file}\" .")
    User.db_query("UPDATE skins SET file = 'storage/skins/#{self.hid}_initial.zip' WHERE id = #{self.id}")
    self.reload # para leer file bien (no funciona hacer self.file)
    unzip_package
  end
  
  def update_version_if_file_changed
    self.version += 1 if slnc_changed?(:file)
  end
  
  def check_file_changed
    # Si ha cambiado el archivo de la skin desempaquetamos
    # TODO comprobar que la estructura es correcta, no haya symlinks, que el hid es válido, etc
    unzip_package if slnc_changed?(:file)
  end
  
  def unzip_package
    dst_folder = "#{RAILS_ROOT}/public/storage/skins/#{self.hid}"
    FileUtils.mkdir_p(dst_folder) unless File.exists?(dst_folder)
    da_fail ="#{RAILS_ROOT}/public/#{self.file}"
    if File.exists?(da_fail)
      config if File.exists?("{realpath}/config.yml") # antes de machacar leemos la config si existe
      system("unzip -o -q \"#{da_fail}\" -d \"#{dst_folder}\"")
      # Si la skin hereda de otro incluímos su css al principio de style.css
      parent = config[:general][:parentskin]
      # TODO sanitize parent
      if parent
        import = %w(default arena bazar clan_default).include?(parent) ? "/skins/#{parent}" : "../#{parent}"
        inject_into_css("@import url(#{import}/style.css);", PREPPEND)
      end
      
      build_skin
    else
      puts "#{da_fail} doesnt exists"
    end
    true
  end
  
  def add_intelliskin_colors
    clean_style_file(CGEN_CSS_START, CGEN_CSS_END)
    inject_into_css(CGEN_CSS_START + "\n" + Skins::ColorGenerators.const_get(config[:intelliskin][:color_gen]).process(config[:intelliskin][config[:intelliskin][:color_gen]][:color_gen_params]) + "\n" + CGEN_CSS_END)
  end
  
  def build_skin
    add_intelliskin_colors if config[:intelliskin]
    process_textures if config[:intelliskin]
  end
  
  def process_textures
    self.skin_textures.find(:all, :order => 'textured_element_position, texture_skin_position', :include => :texture).each do |sk|
      sk.skin = self # para evitar llamar a la skin cada vez, a lo mejor lo hace ruby autom
      clean_style_file(*sk.texture.markers)
      css, files = sk.process
      # las imagenes van a ir uripath/images/#{sk.id}/
      files.each do |fname|
        bname = File.basename(fname)
        FileUtils.mkdir_p("#{realpath}/images/#{sk.id}")
        FileUtils.cp(fname, "#{realpath}/images/#{sk.id}/#{bname}")
        css.gsub!("url(#{bname})", "url(#{uripath}/images/#{sk.id}/#{bname}?#{version})") # las imgs sabemos que estan metidas como si estuvieran en el mismo dir
      end
      inject_into_css(sk.texture.markers[0] + "\n" + css + "\n" + sk.texture.markers[1])
    end
  end
  
  #  def unzip_package
  #    dst_folder = "#{RAILS_ROOT}/public/storage/skins/#{self.hid}"
  #    FileUtils.mkdir_p(dst_folder) unless File.exists?(dst_folder)
  #    da_fail ="#{RAILS_ROOT}/public/#{self.file}"
  #    if File.exists?(da_fail)
  #      config if File.exists?("{realpath}/config.yml") # antes de machacar leemos la config si existe
  #      system("unzip -o -q \"#{da_fail}\" -d \"#{dst_folder}\"")
  #      # Si la skin hereda de otro incluímos su css al principio de style.css
  #      parent = config[:general][:parentskin]
  #      # TODO sanitize parent
  #      if parent
  #        import = %w(default clan_default).include?(parent) ? "/skins/#{parent}" : "../#{parent}"
  #        inject_into_css("@import url(#{import}/style.css);", PREPPEND)
  #      end
  #      
  #      # Si la skin es intelliskin generamos los colores
  #      if config[:intelliskin]
  #        inject_into_css(Skins::ColorGenerators.const_get(config[:intelliskin][:color_gen]).process(config[:intelliskin][:color_gen_params]))
  #      end
  #    end
  #    true
  #  end
  
  APPEND=0
  PREPPEND=1
  
  def inject_into_css(str, mode=APPEND)
    fpath = "#{realpath}/style.css"
    old = File.exists?(fpath) ? File.open(fpath) { |f| f.read } : ''
    File.open(fpath, 'w') do |f|
      if mode == APPEND
        f.write("#{old}\n#{str}")
      else
        f.write("#{str}\n#{old}")
      end
    end
    gen_compressed
  end
  
  def uripath
    %w(default arena bazar).include?(hid) ? "/skins/#{hid}" : "/storage/skins/#{hid}"
  end
  
  def realpath
    "#{RAILS_ROOT}/public#{uripath}"
  end
  
  
  def provided_colors
    # Devuelve todos los colores definidos para esta skin
    # Le pedimos a nuestro color_gen los colores
    
    # Le pedimos a todas las texturas que tengamos asociadas
    
  end
end

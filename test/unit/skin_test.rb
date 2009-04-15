require File.dirname(__FILE__) + '/../test_helper'

class SkinTest < ActiveSupport::TestCase
  
  # Skin default should return an special skin
  def test_default_skin_is_special
    defskin = Skin.find_by_hid('default')
    assert_equal 'default', defskin.hid
    assert_equal 'default', defskin.name
    assert_nil defskin.id
  end
  
  def test_other_skin_is_found
    defskin = Skin.find_by_hid('skinguay')
    assert_equal 'skinguay', defskin.hid
    assert_equal 1, defskin.id
  end
  
  def test_create_skin_should_create_default_file_with_factions_skin
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/skins/miwanna") if File.exists?("#{RAILS_ROOT}/public/storage/skins/miwanna")
    FileUtils.rm("#{RAILS_ROOT}/public/storage/skins/miwanna_initial.zip") if File.exists?("#{RAILS_ROOT}/public/storage/skins/miwanna_initial.zip")
    @s = FactionsSkin.create({:user_id => 1, :name => 'miwanna'})
    assert_equal false, @s.new_record?
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{@s.file}")
    assert_equal true, File.exists?("#{@s.send(:realpath)}/config.yml")
  end
  
  def test_create_skin_should_create_default_file_with_clans_skin
    @s = ClansSkin.create({:user_id => 1, :name => 'miwanna'})
    assert_equal false, @s.new_record?
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{@s.file}")
  end
  
  def test_skin_file_changed_must_make_it_updated
    @el_dir = "#{RAILS_ROOT}/public/storage/skins/miwanna"
    initialzip = "#{RAILS_ROOT}/public/storage/skins/miwanna_initial.zip"
    File.unlink(initializip) if File.exists?(initialzip)
    FileUtils.rm_rf(@el_dir) if File.exists?(@el_dir)
    test_create_skin_should_create_default_file_with_factions_skin
    assert_equal true, @s.update_attributes({:file => fixture_file_upload('/files/sample_skin_in_root.zip', 'application/zip')})
    assert_equal true, File.exists?(@el_dir)
    style_css = "#{@el_dir}/style.css"
    assert_equal true, File.exists?(style_css)
    assert_equal false, (/default/ =~ File.open(style_css).read).nil?
  end
  
  def test_skin_file_changed_must_bump_its_version
    test_create_skin_should_create_default_file_with_factions_skin
    v = @s.version
    assert_equal true, @s.update_attributes({:file => fixture_file_upload('/files/sample_skin_in_root.zip', 'application/zip')})
    assert_equal v + 1, @s.version
  end
  
  def test_skin_update_intelliskin_should_update_config_attrs_correctly
    test_create_skin_should_create_default_file_with_clans_skin
    # change one attr
    @s.config[:general][:intelliskin] = true
    assert_not_nil @s.save_config
    assert_equal true, @s.config[:general][:intelliskin]
    
    # reload
    @s = Skin.find(:first, :order => 'id desc') # reload it
    # saving without modifying
    assert_not_nil @s.save_config
    assert_equal true, @s.config[:general][:intelliskin]
    
    # modifying array
    @s.config[:intelliskin] = {:sidebar_position => 'left', :header => '', :favicon => '', :page_width => '100pc', :color_gen => 'OnWhite', :OnWhite =>  {:color_gen_params => {:hue => '85'}} }
    assert_not_nil @s.save_config
    assert_equal 'left', @s.config[:intelliskin][:sidebar_position]
    assert_equal '100pc', @s.config[:intelliskin][:page_width]
    assert_equal 'OnWhite', @s.config[:intelliskin][:color_gen]
  end
  
  def test_skin_update_intelliskin_should_update_style_css_correctly
    test_skin_update_intelliskin_should_update_config_attrs_correctly
    style_css = File.open("#{@s.send(:realpath)}/style.css") { |f| f.read }
    assert_not_nil style_css.index(Skin::CGEN_CSS_START)
    assert_equal 1, style_css.scan(Skin::CGEN_CSS_START).size
  end
  
  def test_save_config_should_regenerate_compressed_file
    @s = Skin.find(:first, :order => 'id desc')
    comp_ver = "#{@s.send(:realpath)}/style_compressed.css"
    File.unlink(comp_ver) if File.exists?(comp_ver)
    # WARNING: @s se va a redefinir ahora
    test_skin_update_intelliskin_should_update_config_attrs_correctly
    assert_equal true, File.exists?("#{@s.send(:realpath)}/style_compressed.css")
    #assert_css_contents_match(File.open("#{@s.send(:realpath)}/style.css").read, File.open("#{@s.send(:realpath)}/style_compressed.css").read)
  end
  
  def test_unzip_package_should_regenerate_compressed_file
    test_skin_update_intelliskin_should_update_config_attrs_correctly
    File.unlink("#{@s.send(:realpath)}/style_compressed.css")
    assert_equal true, @s.send(:unzip_package)
    assert_equal true, File.exists?("#{@s.send(:realpath)}/style_compressed.css")
  end
  
  def assert_css_contents_match(f1, f_compressed)
    css_files = Skin.extract_css_imports(f1)
    expected = ''
    css_files.each do |f| expected<< f.read end
    assert_equal expected, f_compressed
  end
  
  def test_extract_css_imports_should_correctly_work
    s = '''@import url(css/layout.css);
@import url(css/colourscheme.css);
@import url(/css/typography.css);
/* @import url(css/commented_out.css); */'''
    out = Skin.extract_css_imports(s)
    assert_equal 3, out.length
    assert_equal 'css/layout.css', out[0]
    assert_equal 'css/colourscheme.css', out[1]
    assert_equal "/css/typography.css", out[2]
  end
  
  def test_rextract_should_work
    out = Skin.rextract_css_imports('test/fixtures/files/skin_recursive/style.css')
    out.gsub!("\r\n", "\n")
    assert_equal(".sublayout {} \n\n.layout {}\n\n.typo {}\n.test {}\n/* @import url(css/commented_out.css); */", out)
  end
  
  def test_provided_colors_should_return_color_gen_colors
    
  end
  
  def test_provided_colors_should_return_templates_colors
    # TODO
    # @s.templates<< Skins::Textures::STBackground.generate('')
    
  end
  # TODO no hay tests para verificar que estamos haciendo bien la traducción de urls
end

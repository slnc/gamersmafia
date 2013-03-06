# -*- encoding : utf-8 -*-
require 'test_helper'

class SkinTest < ActiveSupport::TestCase

  def setup
    if not File.exists?(Skin::FAVICONS_CSS_FILENAME)
      `touch #{Skin::FAVICONS_CSS_FILENAME}`
    end

  end

  # Skin default should return an special skin
  test "default_skin_is_special" do
    defskin = Skin.find_by_hid('default')
    assert_equal 'default', defskin.hid
    assert_equal 'default', defskin.name
    assert_equal -1, defskin.id
  end

  test "other_skin_is_found" do
    defskin = Skin.find_by_hid('skinguay')
    assert_equal 'skinguay', defskin.hid
    assert_equal 1, defskin.id
  end

  test "create_skin_should_create_default_file_with_factions_skin" do
    FileUtils.rm_rf("#{Skin::SKINS_DIR}/miwanna") if File.exists?("#{Skin::SKINS_DIR}/miwanna")
    FileUtils.rm("#{Skin::SKINS_DIR}/miwanna_initial.zip") if File.exists?("#{Skin::SKINS_DIR}/miwanna_initial.zip")
    Skin.any_instance.stubs(:call_yuicompressor).at_least_once
    @s = Skin.create({:user_id => 1, :name => 'miwanna'})
    assert_equal false, @s.new_record?
    assert_equal true, File.exists?("#{Rails.root}/public/#{@s.file}")
    assert_equal true, File.exists?("#{@s.send(:realpath)}/config.yml")
  end

  test "create_skin_should_create_default_file_with_clans_skin" do
    Skin.any_instance.stubs(:call_yuicompressor).at_least_once
    @s = Skin.create({:user_id => 1, :name => 'miwanna'})
    assert_equal false, @s.new_record?
    assert_equal true, File.exists?("#{Rails.root}/public/#{@s.file}")
  end

  test "skin_file_changed_must_make_it_updated" do
    @el_dir = "#{Skin::SKINS_DIR}/miwanna"
    initialzip = "#{Skin::SKINS_DIR}/miwanna_initial.zip"
    File.unlink(initialzip) if File.exists?(initialzip)
    FileUtils.rm_rf(@el_dir) if File.exists?(@el_dir)
    test_create_skin_should_create_default_file_with_factions_skin
    assert_equal true, @s.update_attributes({:file => fixture_file_upload('/files/sample_skin_in_root.zip', 'application/zip')})
    assert_equal true, File.exists?(@el_dir)
    style_css = "#{@el_dir}/style.css"
    assert_equal true, File.exists?(style_css)
    assert_equal false, (/default/ =~ File.open(style_css).read).nil?
  end

  test "skin_file_changed_must_bump_its_version" do
    test_create_skin_should_create_default_file_with_factions_skin
    old_version = @s.version
    assert(
        @s.update_attributes(
            :file => fixture_file_upload(
                '/files/sample_skin_in_root.zip', 'application/zip')))
    assert_equal(old_version + 1, @s.version)
  end

  test "skin_update_intelliskin_should_update_config_attrs_correctly" do
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

  test "skin_update_intelliskin_should_update_style_css_correctly" do
    test_skin_update_intelliskin_should_update_config_attrs_correctly
    style_css = File.open("#{@s.send(:realpath)}/style.css") { |f| f.read }
    assert_not_nil style_css.index(Skin::CGEN_CSS_START)
    assert_equal 1, style_css.scan(Skin::CGEN_CSS_START).size
  end

  test "save_config_should_regenerate_compressed_file" do
    @s = Skin.find(:first, :order => 'id desc')
    comp_ver = "#{@s.send(:realpath)}/style_compressed.css"
    File.unlink(comp_ver) if File.exists?(comp_ver)
    # WARNING: @s se va a redefinir ahora
    test_skin_update_intelliskin_should_update_config_attrs_correctly
    assert_equal true, File.exists?("#{@s.send(:realpath)}/style_compressed.css")
  end

  test "unzip_package_should_regenerate_compressed_file" do
    test_skin_update_intelliskin_should_update_config_attrs_correctly
    File.unlink("#{@s.send(:realpath)}/style_compressed.css")
    assert_equal true, @s.send(:unzip_package)
    assert_equal true, File.exists?("#{@s.send(:realpath)}/style_compressed.css")
  end
end

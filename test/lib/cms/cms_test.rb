require File.dirname(__FILE__) + '/../../../test/test_helper'
require 'RMagick'

class CmsTest < Test::Unit::TestCase
  # tests para image_thumbnail
  THUMB_FILE = "/tmp/thumb.jpg"
  SQUARE_FILE = "#{RAILS_ROOT}/test/fixtures/files/square.jpg"
  TALL_FILE = "#{RAILS_ROOT}/test/fixtures/files/tall.jpg"
  WIDE_FILE = "#{RAILS_ROOT}/test/fixtures/files/wide.jpg"
  PARSE_IMAGES_BASEDIR = "#{RAILS_ROOT}/tmp/test/lib/cms"
  
  def setup
    # solo lo necesitamos para los tests de image_thumbnail pero bueno
    File.unlink(THUMB_FILE) if File.exists?(THUMB_FILE)
  end
  
  # SQUARE (f)
  def test_square_f_wide
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 200, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 200, img.columns
    assert_equal 50, img.rows
  end
  
  def test_square_f_tall
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 50, 200, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 200, img.rows
  end
  
  def test_square_f_square
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 50, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end
  
  # SQUARE (k)
  def test_square_k_wide
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 200, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end
  
  def test_square_k_tall
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 50, 200, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end
  
  def test_square_k_square
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 50, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end
  
  
  # TALL (f)
  def test_tall_f_wide
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 200, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 200, img.columns
    assert_equal 50, img.rows
  end
  
  def test_tall_f_tall
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 50, 200, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 200, img.rows
  end
  
  def test_tall_f_square
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 50, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end
  
  
  # TALL (k)
  def test_tall_k_wide
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 200, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 14, img.columns
    assert_equal 50, img.rows
  end
  
  def test_tall_k_tall
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 50, 200, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 175, img.rows
  end
  
  def test_tall_k_square
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 50, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 14, img.columns
    assert_equal 50, img.rows
  end
  
  # WIDE (f)
  def test_wide_f_wide
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 200, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 200, img.columns
    assert_equal 50, img.rows
  end
  
  def test_wide_f_tall
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 50, 200, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 200, img.rows
  end
  
  def test_wide_f_square
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 50, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end
  
  # WIDE (k)
  def test_wide_k_wide
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 200, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 175, img.columns
    assert_equal 50, img.rows
  end
  
  def test_wide_k_tall
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 50, 200, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 14, img.rows
  end
  
  def test_wide_k_square
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 50, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 14, img.rows
  end
  
  
  # OTROS TESTS
  def test_valid_title_regexp
    assert_nil "\nhola< >\n\001\002" =~ Cms::VALID_TITLE_REGEXP
    assert_not_nil "¿España y México son Países de Habla-Hispana!!?" =~ Cms::VALID_TITLE_REGEXP
  end
  
  def test_dns_regexp
    assert_nil 'un mal dominio' =~ Cms::DNS_REGEXP
    assert_not_nil 'laflecha.net' =~ Cms::DNS_REGEXP
    assert_not_nil 'www.31337.net' =~ Cms::DNS_REGEXP
  end
  
  def test_url_regexp
    assert_nil 'un mal dominio' =~ Cms::URL_REGEXP
    assert_not_nil 'http://laflecha.net' =~ Cms::URL_REGEXP
    assert_not_nil 'http://www.31337.net/some/dir/file.html?param1=val&param2=foo#bar' =~ Cms::URL_REGEXP
  end
  
  def test_email_regexp
    assert_nil 'no es un email' =~ Cms::EMAIL_REGEXP
    assert_not_nil 'sample.user@domain.test' =~ Cms::EMAIL_REGEXP
  end
  
  def test_ip_regexp
    assert_nil 'aodajsjad' =~ Cms::IP_REGEXP
    assert_nil '256.0.0.1' =~ Cms::IP_REGEXP
    assert_not_nil '127.0.0.1' =~ Cms::IP_REGEXP
    assert_not_nil '80.58.32.1' =~ Cms::IP_REGEXP
  end
  
  def test_html_clean_minimal
    assert_equal "hello world", Cms::clean_html('hello world')
  end
  
  def test_html_clean_broken
    assert_equal "<strong>hello world</strong>", Cms::clean_html("<strong>hello world")
  end
  
  def test_should_create_valid_fqdn_from_string
    assert_equal 'hola', Cms::to_fqdn('[-=)!(HO-_lA$·"!].')
  end
  
  def test_parse_images_should_do_nothing_on_empty_string
    assert_equal '', Cms::parse_images('', PARSE_IMAGES_BASEDIR)
  end
  
  def test_parse_images_should_do_nothing_on_string_with_no_images
    # TODO check that its copying files to correct place
    FileUtils.mkdir_p("#{RAILS_ROOT}/public/storage/users_files/0/0")
    FileUtils.cp(TALL_FILE, "#{RAILS_ROOT}/public/storage/users_files/0/0/userfile.jpg")
    FileUtils.cp(TALL_FILE, "#{RAILS_ROOT}/public/storage/users_files/0/0/userfile a.jpg")
    assert_equal '<a href="http://www.hola.com/">Mundo img jajaja</a> aa', Cms::parse_images('<a href="http://www.hola.com/">Mundo img jajaja</a> aa', PARSE_IMAGES_BASEDIR)
  end
  
  def test_parse_images_should_download_remote_image_if_domain_is_unknown
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal '<img src="/storage/wswg/0000/dark_castle0.jpg" />', Cms::parse_images('<img src="http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg" />', 'wswg/0000')
  end
  
  def test_parse_images_should_download_local_image_if_userdir
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal '<img src="/storage/wswg/0000/userfile.jpg" />', Cms::parse_images("<img src=\"http://#{App.domain}/storage/users_files/0/0/userfile.jpg\" />", 'wswg/0000')
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal '<img src="/storage/wswg/0000/userfile.jpg" />', Cms::parse_images("<img src=\"/storage/users_files/0/0/userfile.jpg\" />", 'wswg/0000')
  end
  
  def test_parse_images_should_thumbnail_and_put_a_link_image_if_shown_dimensions_differ_from_image_dimensions_and_no_link_around
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal '<a href="/storage/wswg/0000/userfile.jpg"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile.jpg" /></a>', Cms::parse_images("<img src=\"/storage/users_files/0/0/userfile.jpg\" width=\"50px\" height=\"50px\" />", 'wswg/0000')
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal '<a href="/storage/wswg/0000/userfile.jpg"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile.jpg" /></a>', Cms::parse_images("<img src=\"/storage/users_files/0/0/userfile.jpg\" style=\"width: 50px; height: 50px\" />", 'wswg/0000')
    
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal '<a href="/storage/wswg/0000/userfile-a.jpg"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile-a.jpg" /></a>', Cms::parse_images("<img src=\"/storage/users_files/0/0/userfile%20a.jpg\" style=\"width: 50px; height: 50px\" />", 'wswg/0000')
    
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    
    assert_equal '<div style="text-align: center;"><a href="/storage/wswg/0000/userfile.jpg"><img src="/cache/thumbnails/f/342x70/storage/wswg/0000/userfile.jpg" /></a>foo<img class="flag" src="/storage/wswg/0000/dark_castle0.jpg" border="0"> ', Cms::parse_images('<div style="text-align: center;"><img style="width: 342px; height: 70px;" src="/storage/users_files/0/0/userfile.jpg">foo<img src="http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg" class="flag" border="0"> ', 'wswg/0000')
  end
  
  def test_parse_images_should_thumbnail_image_without_creating_link_if_shown_dimensions_differ_from_image_dimensions_and_has_link_around
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal '<a href="foo"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile.jpg" /></a>', Cms::parse_images("<a href=\"foo\"><img src=\"/storage/users_files/0/0/userfile.jpg\" width=\"50px\" height=\"50px\" /></a>", 'wswg/0000')
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal '<a href="foo"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile.jpg" /></a>', Cms::parse_images("<a href=\"foo\"><img src=\"/storage/users_files/0/0/userfile.jpg\" width=\"50px\" height=\"50px\" /></a>", 'wswg/0000')
  end
  
  def test_parse_images_should_work_with_everything_in_place
    strn = <<-END
    <img src="http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg" style="width: 100px; height: 100px;" />
    hola
    <img src="http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg" />
  foobar
  hahah
    <img src="http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg" style="width: 100px; height: 100px;" width="95px" height="95px" />
  hehe
    <img src="http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg" width="95px" height="95px" />

  lerebinonn
    <img src="http://#{App.domain}/storage/users_files/0/0/userfile.jpg" />
  YEAH
  END
    
    expected = <<-END
    <a href="/storage/wswg/0000/dark_castle0.jpg"><img src="/cache/thumbnails/f/100x100/storage/wswg/0000/dark_castle0.jpg" /></a>
    hola
    <img src="/storage/wswg/0000/1_dark_castle0.jpg" />
  foobar
  hahah
    <a href="/storage/wswg/0000/2_dark_castle0.jpg"><img src="/cache/thumbnails/f/100x100/storage/wswg/0000/2_dark_castle0.jpg" /></a>
  hehe
    <a href="/storage/wswg/0000/3_dark_castle0.jpg"><img src="/cache/thumbnails/f/95x95/storage/wswg/0000/3_dark_castle0.jpg" /></a>

  lerebinonn
    <img src="/storage/wswg/0000/userfile.jpg" />
  YEAH
  END
    
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal expected, Cms::parse_images(strn, 'wswg/0000')
  end
  
  def test_parse_images_should_work_with_everything_in_place2
    strn = <<-END
    <img src="/storage/news/userfile.jpg" style="width: 25px; height: 25px;" />
    hola
    <img src="http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg" />
  foobar
  hahah
    <img src="http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg" style="width: 100px; height: 100px;" width="95px" height="95px" />
  hehe
    <img src="http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg" width="95px" height="95px" />

  lerebinonn
    <img src="http://#{App.domain}/storage/users_files/0/0/userfile.jpg" />
  YEAH
  END
    expected = <<-END
    <a href="/storage/news/userfile.jpg"><img src="/cache/thumbnails/f/25x25/storage/news/userfile.jpg" /></a>
    hola
    <img src="/storage/wswg/0000/dark_castle0.jpg" />
  foobar
  hahah
    <a href="/storage/wswg/0000/1_dark_castle0.jpg"><img src="/cache/thumbnails/f/100x100/storage/wswg/0000/1_dark_castle0.jpg" /></a>
  hehe
    <a href="/storage/wswg/0000/2_dark_castle0.jpg"><img src="/cache/thumbnails/f/95x95/storage/wswg/0000/2_dark_castle0.jpg" /></a>

  lerebinonn
    <img src="/storage/wswg/0000/userfile.jpg" />
  YEAH
  END
    
    FileUtils.mkdir_p("#{RAILS_ROOT}/public/storage/news/")
    FileUtils.cp(TALL_FILE, "#{RAILS_ROOT}/public/storage/news/userfile.jpg")
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/wswg/0000")
    assert_equal expected, Cms::parse_images(strn, 'wswg/0000')
  end
  
  def test_copy_image_to_dir_should_copy_local_file_to_tmp_dir
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/fii")
    Cms::copy_image_to_dir(TALL_FILE, 'fii')
    assert File.exists?("#{RAILS_ROOT}/public/storage/fii/#{File.basename(TALL_FILE)}")
  end
  
  def test_copy_image_to_dir_should_copy_local_file_to_tmp_dir_and_rename_it_correctly
    test_copy_image_to_dir_should_copy_local_file_to_tmp_dir
    Cms::copy_image_to_dir(TALL_FILE, 'fii')
    assert File.exists?("#{RAILS_ROOT}/public/storage/fii/#{File.basename(TALL_FILE)}")
  end
  
  def test_copy_image_to_dir_should_copy_external_file_to_tmp_dir
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/fii")
    Cms::copy_image_to_dir('http://dharana.net/wp-content/uploads/2006/11/dark_castle0.jpg', 'fii')
    assert File.exists?("#{RAILS_ROOT}/public/storage/fii/dark_castle0.jpg")
  end
  
  def test_copy_image_to_dir_should_return_nil_if_unexisting_local_file
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/fii")
    assert_nil Cms::copy_image_to_dir('adkjsakdasjhdkjsadkd', 'fii')
  end
  
  def test_copy_image_to_dir_should_return_nil_if_unexisting_remote_file
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/fii")
    assert_nil Cms::copy_image_to_dir('http://www.dharana.net/adakjhdskahdk', 'fii')
  end
  
  def test_transform_content_should_work_if_requirements_match
    
    @n1 = News.find(1)
    prev_content_url = @n1.unique_content.url
    @on = Cms.transform_content(@n1, Tutorial, {:terms => 1})
    assert_equal false, @on.new_record?
    assert_equal 'Tutorial', @on.class.name
    # Verificamos que los atributos únicos de offtopic se han completado con la info de noticia
    @on.unique_attributes.each do |k,v|
      assert_equal v, @n1.send(k) if @n1.respond_to?(k)
    end
    assert_not_equal @on.unique_content.url, prev_content_url 
  end
  
  #def test_transform_content_should_maintain_comments
  #  @n1 = News.find(1)
  #  c = post_comment_on_unittest @n1
  #  @n1.reload
  #  n1_coments_count = @n1.unique_content.comments.count
  #  referred_content_id = c.content_id
  #  test_transform_content_should_work_if_requirements_match
  #  c.reload
  #  assert_equal referred_content_id, c.content_id
  #  assert_equal n1_coments_count, @on.unique_content.comments.count
  #end
  
  def test_transform_content_should_maintain_publishing_state
    @n1 = News.find(1)
    state = @n1.state
    state_uniq = @n1.unique_content.state
    assert_equal state, state_uniq
    test_transform_content_should_work_if_requirements_match
    assert_equal state, @on.state
    assert_equal state, @on.state, @on.unique_content.state
  end
  
  def test_transform_content_should_change_karma
    @n1 = News.find(1)
    u = @n1.user
    orig_kp = u.karma_points
    test_transform_content_should_work_if_requirements_match
    
    u.reload
    assert_equal orig_kp - Karma::KPS_CREATE['News'] + Karma::KPS_CREATE['Tutorial'], u.karma_points 
  end
  
  def test_should_maintain_clan_id_if_content_is_clannable
    
  end
  
  def test_transform_content_should_maintain_common_class_attributes    
    @n1 = News.find(1)
    old_values = {}
    Cms::COMMON_CLASS_ATTRIBUTES.each { |attr| old_values[attr] = @n1.send(attr) }
    test_transform_content_should_work_if_requirements_match
     (Cms::COMMON_CLASS_ATTRIBUTES - [:id, :state, :log]).each do |attr|
      assert_equal old_values[attr], @on.send(attr), "#{attr} is '#{@on.send(attr)}' but should be '#{old_values[attr]}'" 
    end
  end
  
  # TODO: confirmar que funciona con campos de tipo file y category
  
  def test_transform_content_should_destroy_previous_content
    test_transform_content_should_work_if_requirements_match
    assert_equal true, @n1.frozen?
    assert_nil News.find_by_id(@n1.id)
  end
  
  def test_user_can_edit_content_that_is_category
    u10 = User.find(10)
    f = Faction.find_by_boss(u10)
    assert f.update_boss(nil) if f
    ut = Faction.find_by_code('ut')
    assert ut.update_boss(u10)
    u10.faction_id = ut.id
    assert u10.save
    assert Cms.user_can_edit_content?(u10, Image.new(:terms => 1))
  end
  
  def test_sicario_can_edit_contents_of_own_district
    u59 = User.find(59)
    bd = BazarDistrict.find(1)
    bd.add_sicario(u59)
    n65 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n65)
  end
  
  def test_don_can_edit_contents_of_own_district
    u59 = User.find(59)
    bd = BazarDistrict.find(1)
    bd.update_don(u59)
    n65 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n65)
  end
  
  def test_mano_derecha_can_edit_contents_of_own_district
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_mano_derecha(u59)
    n65 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n65)
  end
  
  def test_factions_editor_can_edit_contents_of_own_faction
    f = Faction.find(1)
    u59 = User.find(59)
    assert_count_increases(UsersRole) { f.add_editor(u59, ContentType.find_by_name('News'))}
    n1 = News.find(1)
    assert Cms.user_can_edit_content?(u59, n1)
  end
  
  def test_boss_can_edit_contents_of_own_faction
    f = Faction.find(1)
    u59 = User.find(59)
    assert f.update_boss(u59)
    n1 = News.find(1)
    assert Cms.user_can_edit_content?(u59, n1)
  end
  
  def test_underboss_can_edit_contents_of_own_faction
    f = Faction.find(1)
    u59 = User.find(59)
    assert f.update_underboss(u59)
    n1 = News.find(1)
    assert Cms.user_can_edit_content?(u59, n1)
  end
  
  def test_don_can_edit_contents_of_own_district
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_don(u59)
    n1 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n1)
  end
  
  def test_don_can_edit_topic_of_own_district
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_don(u59)
    tc = TopicsCategory.find_by_code('anime')
    tcc = tc.children.create({:name => 'General'})
    t1 = Topic.create(:user_id => 1, :topics_category_id => tcc.id, :title => 'hola anime', :main => 'soy un topic de anime')
    assert Cms.user_can_edit_content?(u59, t1)
  end
  
  def test_manoderecha_can_edit_contents_of_own_district
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_mano_derecha(u59)
    n1 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n1)
  end
  
  def test_sicario_can_edit_contents_of_own_district
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.add_sicario(u59)
    n1 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n1)
  end
  
  def test_user_can_edit_coverage_of_event_where_you_have_permissions
    u10 = User.find(10)
    f = Faction.find_by_boss(u10)
    assert f.update_boss(nil) if f
    ut = Faction.find_by_code('ut')
    assert ut.update_boss(u10)
    u10.faction_id = ut.id
    assert u10.save
    e = Event.new(:starts_on => 1.year.ago, :ends_on => 11.months.ago, :user_id => 1, :title => 'foo')
    assert e.save, e.errors.full_messages_html
    Term.single_toplevel(:slug => 'ut').link(e)
    Cms::publish_content(e, User.find(1))
    e.reload
    assert_equal Cms::PUBLISHED, e.state
    
    c = Coverage.new(:user_id => 1, :event_id => e.id, :title => "foo", :description => "bar")
    assert c.save, c.errors.full_messages_html
    Cms::publish_content(c, User.find(1))
    c.reload
    assert_equal Cms::PUBLISHED, e.state
    assert Cms.user_can_edit_content?(u10, c)
  end
  
  
  
  # permissions
  def test_capos_should_edit_everything
    # TODO
  end
end

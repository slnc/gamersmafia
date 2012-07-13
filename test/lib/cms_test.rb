require 'test_helper'
require 'RMagick'

class CmsTest < ActiveSupport::TestCase
  # tests para image_thumbnail
  THUMB_FILE = "/tmp/thumb.jpg"
  SQUARE_FILE = "#{Rails.root}/test/fixtures/files/square.jpg"
  TALL_FILE = "#{Rails.root}/test/fixtures/files/tall.jpg"
  WIDE_FILE = "#{Rails.root}/test/fixtures/files/wide.jpg"
  PARSE_IMAGES_BASEDIR = "#{Rails.root}/tmp/test/lib/cms"

  def setup
    # solo lo necesitamos para los tests de image_thumbnail pero bueno
    File.unlink(THUMB_FILE) if File.exists?(THUMB_FILE)
  end

  # SQUARE (f)
  test "square_f_wide" do
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 200, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 200, img.columns
    assert_equal 50, img.rows
  end

  test "square_f_tall" do
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 50, 200, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 200, img.rows
  end

  test "square_f_square" do
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 50, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end

  # SQUARE (k)
  test "square_k_wide" do
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 200, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end

  test "square_k_tall" do
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 50, 200, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end

  test "square_k_square" do
    Cms::image_thumbnail(SQUARE_FILE, THUMB_FILE, 50, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end


  # TALL (f)
  test "tall_f_wide" do
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 200, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 200, img.columns
    assert_equal 50, img.rows
  end

  test "tall_f_tall" do
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 50, 200, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 200, img.rows
  end

  test "tall_f_square" do
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 50, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end


  # TALL (k)
  test "tall_k_wide" do
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 200, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 14, img.columns
    assert_equal 50, img.rows
  end

  test "tall_k_tall" do
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 50, 200, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 175, img.rows
  end

  test "tall_k_square" do
    Cms::image_thumbnail(TALL_FILE, THUMB_FILE, 50, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 14, img.columns
    assert_equal 50, img.rows
  end

  # WIDE (f)
  test "wide_f_wide" do
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 200, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 200, img.columns
    assert_equal 50, img.rows
  end

  test "wide_f_tall" do
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 50, 200, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 200, img.rows
  end

  test "wide_f_square" do
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 50, 50, 'f')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 50, img.rows
  end

  # WIDE (k)
  test "wide_k_wide" do
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 200, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 175, img.columns
    assert_equal 50, img.rows
  end

  test "wide_k_tall" do
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 50, 200, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 14, img.rows
  end

  test "wide_k_square" do
    Cms::image_thumbnail(WIDE_FILE, THUMB_FILE, 50, 50, 'k')
    assert File.exists?(THUMB_FILE)
    img = Magick::Image.read(THUMB_FILE).first
    assert_equal 50, img.columns
    assert_equal 14, img.rows
  end


  # OTROS TESTS
  test "valid_title_regexp" do
    assert_nil "\nhola< >\n\001\002" =~ Cms::VALID_TITLE_REGEXP
    assert_not_nil "¿España y México son Países de Habla-Hispana!!?" =~ Cms::VALID_TITLE_REGEXP
  end

  test "dns_regexp" do
    assert_nil 'un mal dominio' =~ Cms::DNS_REGEXP
    assert_not_nil 'laflecha.net' =~ Cms::DNS_REGEXP
    assert_not_nil 'www.31337.net' =~ Cms::DNS_REGEXP
  end

  test "url_regexp" do
    assert_nil 'un mal dominio' =~ Cms::URL_REGEXP
    assert_not_nil 'http://laflecha.net' =~ Cms::URL_REGEXP
    assert_not_nil 'http://www.31337.net/some/dir/file.html?param1=val&param2=foo#bar' =~ Cms::URL_REGEXP
  end

  test "email_regexp" do
    assert_nil 'no es un email' =~ Cms::EMAIL_REGEXP
    assert_not_nil 'sample.user@domain.test' =~ Cms::EMAIL_REGEXP
  end

  test "ip_regexp" do
    assert_nil 'aodajsjad' =~ Cms::IP_REGEXP
    assert_nil '256.0.0.1' =~ Cms::IP_REGEXP
    assert_not_nil '127.0.0.1' =~ Cms::IP_REGEXP
    assert_not_nil '80.58.32.1' =~ Cms::IP_REGEXP
  end

  test "html_clean_minimal" do
    assert_equal "hello world", Cms::clean_html('hello world')
  end

  test "html_clean_broken" do
    assert_equal("<strong>hello world</strong>",
                 Cms::clean_html("<strong>hello world"))
  end

  test "should_create_valid_fqdn_from_string" do
    assert_equal 'hola', Cms::to_fqdn('[-=)!(HO-_lA$·"!].')
  end

  test "comments_parse_images_should_do_nothing_on_empty_string" do
    assert_equal '', Cms::download_and_rewrite_bb_imgs('', PARSE_IMAGES_BASEDIR)
  end

  test "comments_parse_images_should_work_if_remote" do
    out = Cms::download_and_rewrite_bb_imgs(
        'foo <img src="http://slnc.me/wp-content/uploads/2006/11/' +
        'dark_castle0.jpg" /> bar', 'test/cms')
    assert(/foo <img src=\"http:\/\/test.host\/storage\/test\/cms\/.*dark_castle0.jpg\" \/> bar/ =~ out)
  end


  test "parse_images_should_do_nothing_on_empty_string" do
    assert_equal '', Cms::parse_images('', PARSE_IMAGES_BASEDIR)
  end

  test "parse_images_should_do_nothing_on_string_with_no_images" do
    # TODO check that its copying files to correct place
    FileUtils.mkdir_p("#{Rails.root}/public/storage/users_files/0/0")
    FileUtils.cp(TALL_FILE, "#{Rails.root}/public/storage/users_files/0/0/userfile.jpg")
    FileUtils.cp(TALL_FILE, "#{Rails.root}/public/storage/users_files/0/0/userfile a.jpg")
    assert_equal '<a href="http://www.hola.com/">Mundo img jajaja</a> aa', Cms::parse_images('<a href="http://www.hola.com/">Mundo img jajaja</a> aa', PARSE_IMAGES_BASEDIR)
  end

  test "parse_images_should_download_remote_image_if_domain_is_unknown" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    tall_file_contents = open(TALL_FILE).read
    Cms.expects(:get_url_contents).returns(tall_file_contents)
    in_html = '<img src="http://www.google.com/dark_castle0.jpg" />'
    assert_equal('<img src="/storage/wswg/0000/dark_castle0.jpg" />',
                 Cms::parse_images(in_html, 'wswg/0000'))
  end

  test "parse_images_should_download_local_image_if_userdir" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal "<img src=\"http://#{App.domain}/storage/users_files/0/0/userfile.jpg\" />", Cms::parse_images("<img src=\"http://#{App.domain}/storage/users_files/0/0/userfile.jpg\" />", 'wswg/0000')
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal "<img src=\"http://#{App.domain}/storage/users_files/0/0/userfile.jpg\" />", Cms::parse_images("<img src=\"/storage/users_files/0/0/userfile.jpg\" />", 'wswg/0000')
  end

  test "parse_images_should_thumbnail_and_put_a_link_image_if_shown_dimensions_differ_from_image_dimensions_and_no_link_around" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal '<a href="/storage/wswg/0000/userfile.jpg"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile.jpg" /></a>', Cms::parse_images("<img src=\"/storage/users_files/0/0/userfile.jpg\" width=\"50px\" height=\"50px\" />", 'wswg/0000')
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal '<a href="/storage/wswg/0000/userfile.jpg"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile.jpg" /></a>', Cms::parse_images("<img src=\"/storage/users_files/0/0/userfile.jpg\" style=\"width: 50px; height: 50px\" />", 'wswg/0000')

    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal '<a href="/storage/wswg/0000/userfile-a.jpg"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile-a.jpg" /></a>', Cms::parse_images("<img src=\"/storage/users_files/0/0/userfile%20a.jpg\" style=\"width: 50px; height: 50px\" />", 'wswg/0000')

    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")

    output = Cms::parse_images('<div style="text-align: center;"><img style="width: 342px; height: 70px;" src="/storage/users_files/0/0/userfile.jpg">foo<img src="http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg" class="flag" border="0"> ', 'wswg/0000')
    assert output.include?("<img src=\"/cache/thumbnails/f/342x70/storage/wswg/0000/userfile.jpg\" />")
    assert output.include?(" src=\"/storage/wswg/0000/dark_castle0.jpg\"")
  end

  test "parse_images_should_thumbnail_image_without_creating_link_if_shown_dimensions_differ_from_image_dimensions_and_has_link_around" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal '<a href="foo"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile.jpg" /></a>', Cms::parse_images("<a href=\"foo\"><img src=\"/storage/users_files/0/0/userfile.jpg\" width=\"50px\" height=\"50px\" /></a>", 'wswg/0000')
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal '<a href="foo"><img src="/cache/thumbnails/f/50x50/storage/wswg/0000/userfile.jpg" /></a>', Cms::parse_images("<a href=\"foo\"><img src=\"/storage/users_files/0/0/userfile.jpg\" width=\"50px\" height=\"50px\" /></a>", 'wswg/0000')
  end

  test "parse_images_should_work_with_everything_in_place" do
    strn = <<-END
    <img src="http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg" style="width: 100px; height: 100px;" />
    hola
    <img src="http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg" />
  foobar
  hahah
    <img src="http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg" style="width: 100px; height: 100px;" width="95px" height="95px" />
  hehe
    <img src="http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg" width="95px" height="95px" />

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
    <img src="http://#{App.domain}/storage/users_files/0/0/userfile.jpg" />
  YEAH
  END

    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal expected, Cms::parse_images(strn, 'wswg/0000')
  end

  test "parse_images_should_work_with_everything_in_place2" do
    strn = <<-END
    <img src="/storage/news/userfile.jpg" style="width: 25px; height: 25px;" />
    hola
    <img src="http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg" />
  foobar
  hahah
    <img src="http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg" style="width: 100px; height: 100px;" width="95px" height="95px" />
  hehe
    <img src="http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg" width="95px" height="95px" />

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
    <img src="http://#{App.domain}/storage/users_files/0/0/userfile.jpg" />
  YEAH
  END

    FileUtils.mkdir_p("#{Rails.root}/public/storage/news/")
    FileUtils.cp(TALL_FILE, "#{Rails.root}/public/storage/news/userfile.jpg")
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal expected, Cms::parse_images(strn, 'wswg/0000')
  end

  test "copy_image_to_dir_should_copy_local_file_to_tmp_dir" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/fii")
    Cms::copy_image_to_dir(TALL_FILE, 'fii')
    assert File.exists?("#{Rails.root}/public/storage/fii/#{File.basename(TALL_FILE)}")
  end

  test "copy_image_to_dir_should_copy_local_file_to_tmp_dir_and_rename_it_correctly" do
    test_copy_image_to_dir_should_copy_local_file_to_tmp_dir
    Cms::copy_image_to_dir(TALL_FILE, 'fii')
    assert File.exists?("#{Rails.root}/public/storage/fii/#{File.basename(TALL_FILE)}")
  end

  test "copy_image_to_dir_should_copy_external_file_to_tmp_dir" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/fii")
    Cms::copy_image_to_dir('http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg', 'fii')
    assert File.exists?("#{Rails.root}/public/storage/fii/dark_castle0.jpg")
  end

  test "copy_image_to_dir_should_return_nil_if_unexisting_local_file" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/fii")
    assert_nil Cms::copy_image_to_dir('adkjsakdasjhdkjsadkd', 'fii')
  end

  test "copy_image_to_dir_should_return_nil_if_unexisting_remote_file" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/fii")
    assert_nil Cms::copy_image_to_dir('http://www.slnc.me/adakjhdskahdk', 'fii')
  end

  test "transform_content_should_work_if_requirements_match" do

    @n1 = News.find(1)
    prev_content_url = @n1.unique_content.url
    @on = Cms.transform_content(@n1, Tutorial, {:terms => 1})
    assert_equal false, @on.new_record?
    assert_equal 'Tutorial', @on.class.name
    # Verificamos que los atributos únicos de offtopic se han completado con la info de noticia
    @on.unique_attributes.each do |k,v|
      assert_equal(v, @n1.send(k)) if @n1.respond_to?(k)
    end
    assert_not_equal @on.unique_content.url, prev_content_url
  end

  #test "transform_content_should_maintain_comments" do
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

  test "transform_content_should_maintain_publishing_state" do
    @n1 = News.find(1)
    state = @n1.state
    state_uniq = @n1.unique_content.state
    assert_equal state, state_uniq
    test_transform_content_should_work_if_requirements_match
    assert_equal state, @on.state
    assert_equal state, @on.state, @on.unique_content.state
  end

  test "transform_content_should_change_karma" do
    @n1 = News.find(1)
    u = @n1.user
    orig_kp = u.karma_points
    test_transform_content_should_work_if_requirements_match

    u.reload
    assert_equal orig_kp - Karma::KPS_CREATE['News'] + Karma::KPS_CREATE['Tutorial'], u.karma_points
  end

  test "should_maintain_clan_id_if_content_is_clannable" do

  end

  test "transform_content_should_maintain_common_class_attributes" do
    @n1 = News.find(1)
    old_values = {}
    Cms::COMMON_CLASS_ATTRIBUTES.each { |attr| old_values[attr] = @n1.send(attr) }
    test_transform_content_should_work_if_requirements_match
     (Cms::COMMON_CLASS_ATTRIBUTES - [:id, :state, :log, :terms, :unique_content_id]).each do |attr|
      assert_equal old_values[attr], @on.send(attr), "#{attr} is '#{@on.send(attr)}' but should be '#{old_values[attr]}'"
    end
  end

  # TODO: confirmar que funciona con campos de tipo file y category

  test "transform_content_should_destroy_previous_content" do
    test_transform_content_should_work_if_requirements_match
    assert_equal true, @n1.frozen?
    assert_nil News.find_by_id(@n1.id)
  end

  test "user_can_edit_content_that_is_category" do
    u10 = User.find(10)
    f = Faction.find_by_boss(u10)
    assert f.update_boss(nil) if f
    ut = Faction.find_by_code('ut')
    assert ut.update_boss(u10)
    assert_equal ut.id, u10.faction_id
    assert Cms.user_can_edit_content?(u10, Image.new(:terms => 1))
  end

  test "capo_can_edit_blogentry" do
    u10 = User.find(10)
    u10.give_admin_permission(:capo)
    be = Blogentry.find(:first)
    assert Cms.user_can_edit_content?(u10, be)
  end

  test "mano_derecha_can_edit_contents_of_own_district" do
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_mano_derecha(u59)
    n65 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n65)
  end

  test "factions_editor_can_edit_contents_of_own_faction" do
    f = Faction.find(1)
    u59 = User.find(59)
    assert_count_increases(UsersRole) { f.add_editor(u59, ContentType.find_by_name('News'))}
    n1 = News.find(1)
    assert Cms.user_can_edit_content?(u59, n1)
  end

  test "boss_can_edit_contents_of_own_faction" do
    f = Faction.find(1)
    u59 = User.find(59)
    assert f.update_boss(u59)
    n1 = News.find(1)
    assert Cms.user_can_edit_content?(u59, n1)
  end

  test "underboss_can_edit_contents_of_own_faction" do
    f = Faction.find(1)
    u59 = User.find(59)
    assert f.update_underboss(u59)
    n1 = News.find(1)
    assert Cms.user_can_edit_content?(u59, n1)
  end

  test "don_can_edit_contents_of_own_district" do
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_don(u59)
    n1 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n1)
  end

  test "don_can_edit_topic_of_own_district" do
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_don(u59)
    tc = Term.single_toplevel(:slug => 'anime')
    tcc = tc.children.create({:name => 'General', :taxonomy => 'TopicsCategory'})
    t1 = Topic.create(:user_id => 1, :terms => tcc.id, :title => 'hola anime', :main => 'soy un topic de anime')
    assert !t1.new_record?, t1.errors.full_messages_html
    p t1.terms
    assert Cms.user_can_edit_content?(u59, t1)
  end

  test "manoderecha_can_edit_contents_of_own_district" do
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_mano_derecha(u59)
    n1 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n1)
  end

  test "sicario_can_edit_contents_of_own_district" do
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.add_sicario(u59)
    n1 = News.find(65)
    assert Cms.user_can_edit_content?(u59, n1)
  end

  test "user_can_edit_coverage_of_event_where_you_have_permissions" do
    u10 = User.find(10)
    f = Faction.find_by_boss(u10)
    assert f.update_boss(nil) if f
    ut = Faction.find_by_code('ut')
    assert ut.update_boss(u10)
    assert_equal ut.id, u10.faction_id
    e = Event.new(:starts_on => 1.year.ago, :ends_on => 11.months.ago, :user_id => 1, :title => 'foo')
    assert e.save, e.errors.full_messages_html
    Term.single_toplevel(:slug => 'ut').link(e.unique_content)
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
  test "capos_should_edit_everything" do
    # TODO
  end
end

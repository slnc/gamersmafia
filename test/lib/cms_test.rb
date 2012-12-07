# -*- encoding : utf-8 -*-
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
    File.unlink(THUMB_FILE) if File.exists?(THUMB_FILE)
  end

  test "extract_html_images no images" do
    assert_equal [], Cms.extract_html_images("foo")
  end

  test "extract_html_images images" do
    extracted_imgs = Cms.extract_html_images(
      "<img src=\"/foo.jpg\" />\n<img src=\"/bar.jpg\" />")
    assert_equal ["/foo.jpg", "/bar.jpg"], extracted_imgs
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
    Cms.expects(:get_url_contents).returns(open(TALL_FILE).read)
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
    output = Cms::parse_images(
          '<a href="http://www.hola.com/">Mundo img jajaja</a> aa',
        PARSE_IMAGES_BASEDIR)
    assert_equal(
      '<a href="http://www.hola.com/">Mundo img jajaja</a> aa', output)
  end

  test "parse_images_should_download_remote_image_if_domain_is_unknown" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    Cms.expects(:get_url_contents).returns(open(TALL_FILE).read)
    in_html = '<img src="http://www.google.com/dark_castle0.jpg" />'
    assert_equal('<img src="/storage/wswg/0000/dark_castle0.jpg" />',
                 Cms::parse_images(in_html, 'wswg/0000'))
  end

  test "parse_images_should_download_local_image_if_userdir" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal "<img src=\"http://#{App.domain}/storage/users_files/0/0/userfile.jpg\" />", Cms::parse_images("<img src=\"http://#{App.domain}/storage/users_files/0/0/userfile.jpg\" />", 'wswg/0000')
    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal "<img src=\"/storage/wswg/0000/userfile.jpg\" />", Cms::parse_images("<img src=\"/storage/users_files/0/0/userfile.jpg\" />", 'wswg/0000')
  end

  test "parse_images_should_thumbnail_and_put_a_link_image_if_shown_dimensions_differ_from_image_dimensions_and_no_link_around" do
    Cms.expects(:get_url_contents).returns(open(TALL_FILE).read)
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
    Cms.expects(:get_url_contents).at_least_once.returns(open(TALL_FILE).read)
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
    <img src="/storage/wswg/0000/userfile.jpg" />
  YEAH
  END

    FileUtils.rm_rf("#{Rails.root}/public/storage/wswg/0000")
    assert_equal expected, Cms::parse_images(strn, 'wswg/0000')
  end

  test "parse_images_should_work_with_everything_in_place2" do
    Cms.expects(:get_url_contents).at_least_once.returns(open(TALL_FILE).read)
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
    <img src="/storage/wswg/0000/userfile.jpg" />
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
    Cms.expects(:get_url_contents).returns(open(TALL_FILE).read)
    FileUtils.rm_rf("#{Rails.root}/public/storage/fii")
    Cms::copy_image_to_dir('http://slnc.me/wp-content/uploads/2006/11/dark_castle0.jpg', 'fii')
    assert File.exists?("#{Rails.root}/public/storage/fii/dark_castle0.jpg")
  end

  test "copy_image_to_dir_should_return_nil_if_unexisting_local_file" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/fii")
    assert_nil Cms::copy_image_to_dir('adkjsakdasjhdkjsadkd', 'fii')
  end

  test "copy_image_to_dir_should_return_nil_if_unexisting_remote_file" do
    Cms.expects(:get_url_contents).at_least_once.raises(Exception, "Error")
    FileUtils.rm_rf("#{Rails.root}/public/storage/fii")
    assert_nil Cms::copy_image_to_dir('http://www.slnc.me/adakjhdskahdk', 'fii')
  end

  test "user_can_edit_content_that_is_category" do
    u10 = User.find(10)
    f = Faction.find_by_boss(u10)
    assert f.update_boss(nil) if f
    ut = Faction.find_by_code('ut')
    assert ut.update_boss(u10)
    assert_equal ut.id, u10.faction_id
    assert Authorization.can_edit_content?(u10, Image.new(:terms => 1))
  end

  test "edit_contents_can_edit_blogentry" do
    u10 = User.find(10)
    give_skill(u10.id, "EditContents")
    be = Blogentry.find(:first)
    assert Authorization.can_edit_content?(u10, be)
  end

  test "mano_derecha_can_edit_contents_of_own_district" do
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_mano_derecha(u59)
    n65 = News.find(65)
    assert Authorization.can_edit_content?(u59, n65)
  end

  test "factions_editor_can_edit_contents_of_own_faction" do
    f = Faction.find(1)
    u59 = User.find(59)
    assert_count_increases(UsersSkill) { f.add_editor(u59, ContentType.find_by_name('News'))}
    n1 = News.find(1)
    assert Authorization.can_edit_content?(u59, n1)
  end

  test "boss_can_edit_contents_of_own_faction" do
    f = Faction.find(1)
    u59 = User.find(59)
    assert f.update_boss(u59)
    n1 = News.find(1)
    assert Authorization.can_edit_content?(u59, n1)
  end

  test "underboss_can_edit_contents_of_own_faction" do
    f = Faction.find(1)
    u59 = User.find(59)
    assert f.update_underboss(u59)
    n1 = News.find(1)
    assert Authorization.can_edit_content?(u59, n1)
  end

  test "don_can_edit_contents_of_own_district" do
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_don(u59)
    n1 = News.find(65)
    assert Authorization.can_edit_content?(u59, n1)
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
    assert Authorization.can_edit_content?(u59, t1)
  end

  test "manoderecha_can_edit_contents_of_own_district" do
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.update_mano_derecha(u59)
    n1 = News.find(65)
    assert Authorization.can_edit_content?(u59, n1)
  end

  test "sicario_can_edit_contents_of_own_district" do
    bd = BazarDistrict.find(1)
    u59 = User.find(59)
    bd.add_sicario(u59)
    n1 = News.find(65)
    assert Authorization.can_edit_content?(u59, n1)
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
    Term.single_toplevel(:slug => 'ut').link(e)
    Content.publish_content_directly(e, User.find(1))
    e.reload
    assert_equal Cms::PUBLISHED, e.state

    c = Coverage.new(:user_id => 1, :event_id => e.id, :title => "foo", :description => "bar")
    assert c.save, c.errors.full_messages_html
    Content.publish_content_directly(c, User.find(1))
    c.reload
    assert_equal Cms::PUBLISHED, e.state
    assert Authorization.can_edit_content?(u10, c)
  end

  # permissions
  test "capos_should_edit_everything" do
    # TODO
  end

  test "plain_text_to_html" do
    expected = (
      "<p>foo</p>\n<p>bar baz sd klsj dlkajd lkjasd lkjasdlk jadl jadklj" +
      " asdljasdlkjasldk jaskldjkl</p>\n<p>tapang</p>\n<p></p>\n<p>wiki</p>")
    input_str = (
      "foo\nbar baz sd klsj dlkajd lkjasd lkjasdlk jadl jadklj asdljasdl" +
      "kjasldk jaskldjkl\ntapang\n\nwiki")
    assert_equal expected, Cms.plain_text_to_html(input_str)
  end

end

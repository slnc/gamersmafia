require 'test_helper'

class ClanTest < ActiveSupport::TestCase
  test "validations_minimal_data" do
    # valid minimal data
    @clan = Clan.new({:tag => 'tagvali', :name => 'Super valid clan'})
    assert_equal true, @clan.save, @clan.errors.to_yaml
    assert_equal 'tagvali', @clan.tag
    assert_equal 'Super valid clan', @clan.name
  end
  
  test "create_term" do
    test_validations_minimal_data
    t = Term.find(:first, :conditions => ['clan_id = ? AND parent_id IS NULL', @clan.id])
    assert t
    assert_equal @clan.name, t.name
    assert_equal @clan.tag, t.slug
  end
  
  test "invalid_minimal_data" do
    c = Clan.new({:tag => 'mega large owning tag', :name => '31337!!'})
    assert_equal false, c.save, c.errors.to_yaml
  end
  
  test "should_create_clan_with_tag_with_extended_chars" do
    c = Clan.new({:tag => '[|]', :name => 'Super valid clan', :irc_server => 'irc.quakenet.org', :irc_channel => 'somos_los_campeones', :competition_roster => fixture_file_upload('files/image.jpg'), :website_external => 'http://gamersmafia.com/', :description => 'somos los amos!'})
    assert_equal true, c.save, c.errors.to_yaml
  end
  
  
  test "valid_extended_data" do
    c = Clan.new({:tag => 'tagvali', :name => 'Super valid clan', :irc_server => 'irc.quakenet.org', :irc_channel => 'somos_los_campeones', :competition_roster => fixture_file_upload('files/image.jpg'), :website_external => 'http://gamersmafia.com/', :description => 'somos los amos!'})
    assert_equal true, c.save, c.errors.to_yaml
  end
  
  test "invalid_extended_data" do
    c = Clan.new({:tag => 'tagvalium', :name => 'Super valid clan', :irc_server => 'irc.quakenet.org', :irc_channel => 'somos_los_campeones', :competition_roster => fixture_file_upload('files/image.jpg'), :website_external => 'gamersmafia.com/', :description => '<script type="text/javascript">alert("Hello World!");</script>somos los amos!'})
    assert_equal false, c.save, c.errors.to_yaml
  end
  
  test "activate_website_should_create_clans_portal" do
    @c = Clan.find(1)
    assert_equal false, @c.website_activated?
    assert_nil @c.clans_portals[0]
    @c.activate_website
    assert_equal true, @c.website_activated?
    @c.reload
    assert_not_nil @c.clans_portals[0]
    assert_equal Cms::to_fqdn(@c.tag), @c.clans_portals[0].code
  end
  
  test "activate_website_should_create_clans_skin_and_assign_it_to_the_clans_portal" do
    assert_count_increases(ClansSkin) do
      test_activate_website_should_create_clans_portal
    end
    assert_equal true, (@c.clans_portals[0].skins.count > 0)
    assert_equal @c.clans_portals[0].skins[0].id, @c.clans_portals[0].skin_id
  end
  
  test "activate_website_should_create_contents_categories" do
    @c = Clan.find(1)
    test_activate_website_should_create_clans_portal
    root_term = Term.single_toplevel(:clan_id => @c.id)
    assert root_term
    assert_equal 1, root_term.children.count
  end
  
  test "hot" do
    Clan.hot(1, 1.day.ago, Time.now)
  end
end

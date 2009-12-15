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
  
  test "hot" do
    Clan.hot(1, 1.day.ago, Time.now)
  end
end

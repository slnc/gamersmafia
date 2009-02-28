require File.dirname(__FILE__) + '/../test_helper'

class UsersActionObserverTest < ActionController::IntegrationTest
  
  def test_should_properly_work_with_recruitment_ads
    @ra = RecruitmentAd.new(:user_id => 1, :game_id => 1, :title => 'busco cosas', :main => 'hola')
    assert_count_increases(UsersAction) do
      assert @ra.save
    end
    
    assert_count_decreases(UsersAction) do
      @ra.mark_as_deleted
    end
  end
  
  def test_should_properly_work_with_photos_updated_in_profiles
    u1 = User.find(1)
    u1.photo = fixture_file_upload('files/buddha.jpg')
    assert_count_increases(UsersAction) do
      assert u1.save
    end
  end
  
  def test_should_properly_reflect_user_change_faction
    u1 = User.find(1)
    assert_count_increases(UsersAction) do
      Factions.user_joins_faction(u1, Faction.find(2))
    end
  end
  
  def test_should_properly_reflect_content
    n = News.create(:terms => 1, :user_id => 1, :title => "titulin", :description => "fooo")
    assert_count_increases(UsersAction) do
      Cms.publish_content(n, User.find(1))
    end
    
    n.reload
    assert_count_decreases(UsersAction) do
      Cms.deny_content(n, User.find(1), 'feillo')
    end
  end
  
  def test_should_properly_work_with_clans_movements
    @cm = ClansMovement.new(:user_id => 1, :clan_id => 1, :direction => ClansMovement::IN)
    assert_count_increases(UsersAction) do
      assert @cm.save
    end
    
    assert_count_decreases(UsersAction) do
      @cm.destroy
    end
  end
  
  def test_should_properly_work_with_emblems
    @ue = UsersEmblem.new(:user_id => 1, :emblem => Emblems::EMBLEMS_TO_REPORT[0])
    assert_count_increases(UsersAction) do
      assert @ue.save
    end
    
    assert_count_decreases(UsersAction) do
      @ue.destroy
    end
  end
  
  def test_should_properly_work_with_profile_signatures
    @ps = ProfileSignature.new(:user_id => 1, :signer_user_id => 2, :signature => 'fada')
    uai = UsersAction.count
    assert @ps.save
    assert_equal uai + 2, UsersAction.count 

    @ps.destroy
    assert_equal uai, UsersAction.count
  end
  
  def test_should_properly_work_with_friendships
    @ps = Friendship.new(:sender_user_id => 58, :receiver_user_id => 59)
    assert @ps.save
    
    uai = UsersAction.count
    @ps.accept
    assert_equal uai + 2, UsersAction.count 
    
    @ps.destroy
    assert_equal uai, UsersAction.count
  end
  
  def test_should_properly_work_with_clans
    @cl = Clan.new(:name => 'jolinchos', :tag => 'jols', :creator_user_id => 1)
    assert_count_increases(UsersAction) do
      assert @cl.save
    end
    
    assert_count_decreases(UsersAction) do
      assert @cl.update_attributes(:deleted => true)
    end
  end
end

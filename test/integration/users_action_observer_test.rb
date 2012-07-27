# -*- encoding : utf-8 -*-
require 'test_helper'

class UsersActionObserverTest < ActionController::IntegrationTest

  test "should_properly_work_with_recruitment_ads" do
    assert_count_increases(UsersAction) do
      @ra = RecruitmentAd.create(
        :user_id => 1, :game_id => 1, :title => 'busco cosas', :main => 'hola')
      p @ra.errors.full_messages_html
    end

    assert_count_decreases(UsersAction) do
      @ra.mark_as_deleted
    end
  end

  test "should_properly_work_with_photos_updated_in_profiles" do
    u1 = User.find(1)
    u1.photo = fixture_file_upload('files/buddha.jpg')
    assert_count_increases(UsersAction) do
      assert u1.save
    end
  end

  test "should_properly_reflect_user_change_faction" do
    u1 = User.find(1)
    assert_count_increases(UsersAction) do
      Factions.user_joins_faction(u1, Faction.find(2))
    end
  end

  test "should_properly_reflect_content" do
    n = News.create(:terms => 1, :user_id => 1, :title => "titulin", :description => "fooo")
    assert_count_increases(UsersAction) do
      Cms.publish_content(n, User.find(1))
    end

    n.reload
    assert_count_decreases(UsersAction) do
      Cms.deny_content(n, User.find(1), 'feillo')
    end
  end

  test "should_properly_work_with_clans_movements" do
    @cm = ClansMovement.new(:user_id => 1, :clan_id => 1, :direction => ClansMovement::IN)
    assert_count_increases(UsersAction) do
      assert @cm.save
    end

    assert_count_decreases(UsersAction) do
      @cm.destroy
    end
  end

  test "should_properly_work_with_emblems" do
    @ue = UsersEmblem.new(:user_id => 1, :emblem => Emblems::EMBLEMS_TO_REPORT[0])
    assert_count_increases(UsersAction) do
      assert @ue.save
    end

    assert_count_decreases(UsersAction) do
      @ue.destroy
    end
  end

  test "should_properly_work_with_profile_signatures" do
    @ps = ProfileSignature.new(:user_id => 1, :signer_user_id => 2, :signature => 'fada')
    uai = UsersAction.count
    assert @ps.save
    assert_equal uai + 2, UsersAction.count

    @ps.destroy
    assert_equal uai, UsersAction.count
  end

  test "should_properly_work_with_friendships" do
    @ps = Friendship.new(:sender_user_id => 58, :receiver_user_id => 59)
    assert @ps.save

    uai = UsersAction.count
    @ps.accept
    assert_equal uai + 2, UsersAction.count

    @ps.destroy
    assert_equal uai, UsersAction.count
  end

  test "should_properly_work_with_clans" do
    @cl = Clan.new(:name => 'jolinchos', :tag => 'jols', :creator_user_id => 1)
    assert_count_increases(UsersAction) do
      assert @cl.save
    end

    assert_count_decreases(UsersAction) do
      assert @cl.update_attributes(:deleted => true)
    end
  end
end

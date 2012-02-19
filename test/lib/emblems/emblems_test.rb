require File.dirname(__FILE__) + '/../../../test/test_helper'

class EmblemsTest < ActiveSupport::TestCase
  def assert_gives_emblem(emblem, &block)
    @u = User.find(1) if @u.nil?
    assert_equal 0, @u.users_emblems.count(:conditions => "emblem = '#{emblem}'")
    yield
    Emblems.give_emblems
    @u.reload
    assert_equal 1, @u.users_emblems.count(:conditions => "emblem = '#{emblem}'")
    assert_equal '1', @u.emblems_mask[Emblems::EMBLEMS[emblem.to_sym][:index]..Emblems::EMBLEMS[emblem.to_sym][:index]]
  end
  
  test "give_emblems_doesnt_repeat_if_too_soon" do
    test_give_emblems_hq
    ue_count = UsersEmblem.count
    Emblems.give_emblems
    assert_equal ue_count, UsersEmblem.count
  end
  
  test "should_reset_emblems_mask_of_older" do
    test_give_emblems_hq
    User.db_query("UPDATE users_emblems SET created_on = now() - '1 week 1 day'::interval")
    assert @u.update_attributes(:is_hq => false)
    assert @u.emblems_mask.index('1') != nil 
    Emblems.give_emblems
    @u.reload
    assert_equal '0', @u.emblems_mask[Emblems::EMBLEMS[:hq][:index]..Emblems::EMBLEMS[:hq][:index]]
  end
  
  test "give_emblems_hq" do
    assert_gives_emblem('hq') do
      assert @u.update_attributes(:is_hq => true)
    end
  end
  
  test "give_emblems_capo" do
    assert_gives_emblem('capo') do
      assert @u.give_admin_permission(:capo)
    end
  end
  
  test "give_emblems_baby" do
    assert_gives_emblem('baby') do
      assert @u.update_attributes(:created_on => Time.now)
    end
  end
  
  test "give_emblems_bets_master" do
    # TODO test
  end
  
  test "give_emblems_most_knowledgeable" do
    # TODO test
  end
  
  test "give_emblems_living_legend" do
    assert_gives_emblem('living_legend') do
      @u2 = User.find(2)
      @u3 = User.find(3)
      f2 = Friendship.create(:sender_user_id => @u2.id, :receiver_user_id => @u3.id)
      assert f2.accept
    end
  end
  
  test "give_emblems_funniest" do
    assert_gives_emblem('funniest') do
      cv = CommentsValoration.new(:weight => 1.0, :comment_id => 1, :user_id => 3, :comments_valorations_type_id => CommentsValorationsType.find_by_name('Divertido').id)
      assert cv.save, cv.errors.full_messages_html
      User.db_query("UPDATE comments_valorations SET created_on = created_on - '1 hour'::interval")
    end
  end
  
  test "give_emblems_profoundest" do
    assert_gives_emblem('profoundest') do
      cv = CommentsValoration.new(:weight => 1.0, :comment_id => 1, :user_id => 3, :comments_valorations_type_id => CommentsValorationsType.find_by_name('Profundo').id)
      assert cv.save, cv.errors.full_messages_html
      User.db_query("UPDATE comments_valorations SET created_on = created_on - '1 hour'::interval")
    end
  end
  
  test "give_emblems_most_informational" do
    assert_gives_emblem('most_informational') do
      cv = CommentsValoration.new(:weight => 1.0, :comment_id => 1, :user_id => 3, :comments_valorations_type_id => CommentsValorationsType.find_by_name('Informativo').id)
      assert cv.save, cv.errors.full_messages_html
      User.db_query("UPDATE comments_valorations SET created_on = created_on - '1 hour'::interval")
    end
  end
  
  test "give_emblems_most_interesting" do
    assert_gives_emblem('most_interesting') do
      cv = CommentsValoration.new(:weight => 1.0, :comment_id => 1, :user_id => 3, :comments_valorations_type_id => CommentsValorationsType.find_by_name('Interesante').id)
      assert cv.save, cv.errors.full_messages_html
      User.db_query("UPDATE comments_valorations SET created_on = created_on - '1 hour'::interval")
    end
  end
  
  test "give_emblems_wealthiest" do
    assert_gives_emblem('wealthiest') do
      User.db_query("UPDATE users SET cash = (SELECT max(cash) + 1 FROM users) WHERE id = #{@u.id}")
    end
  end
  
  test "give_emblems_webmaster" do
    assert_gives_emblem('webmaster') do
      assert @u.update_attributes(:is_superadmin => true)
    end
  end
  
  test "give_emblems_boss" do
    assert_gives_emblem('boss') do
      f1 = Faction.find(1)
      assert f1.update_boss(@u)
    end
  end
  
  test "give_emblems_underboss" do
    assert_gives_emblem('underboss') do
      assert Faction.find(1).update_underboss(User.find(1))
    end
  end
  
  test "give_emblems_don" do
    assert_gives_emblem('don') do
      d1 = BazarDistrict.find(1)
      assert d1.update_don(@u)
    end
  end
  
  test "give_emblems_mano_derecha" do
    assert_gives_emblem('mano_derecha') do
      d1 = BazarDistrict.find(1)
      assert d1.update_mano_derecha(@u)
    end
  end
  
  test "give_emblems_sicario" do
    User.db_query("DELETE from users_roles WHERE role = 'Sicario'")
    assert_gives_emblem('sicario') do
      d1 = BazarDistrict.find(1)
      d1.add_sicario(@u)
    end
  end
  
  test "give_emblems_editor" do
    assert_gives_emblem('editor') do
      assert_count_increases(UsersRole) do
        Faction.find(1).add_editor(@u, ContentType.find(:first))
      end
    end
  end
  
  test "give_emblems_editor_if_not_already_boss" do
    test_give_emblems_boss
    ue_count = UsersEmblem.count
    assert_count_increases(UsersRole) { UsersRole.create(:user_id => @u.id, :role => 'Editor', :role_data => {:faction_id => 1, :content_type_id => 1}.to_yaml) }
    assert_equal ue_count, UsersEmblem.count
  end
  
  test "give_emblems_moderator" do
    User.db_query("DELETE FROM users_roles WHERE role = 'Moderator'")
    assert_gives_emblem('moderator') do
      assert_count_increases(UsersRole) { UsersRole.create(:user_id => @u.id, :role => 'Moderator', :role_data => '1') }
    end
  end
  
  test "give_emblems_karma_fury" do
    assert_gives_emblem('karma_fury') do
      c_count = Comment.count
      Comment.create(:user_id => @u.id, :comment => 'holaaa', :content_id => 1, :host => '127.0.0.1')
      Comment.create(:user_id => @u.id, :comment => 'holaaa jajajaja', :content_id => 1, :host => '127.0.0.1')
      Comment.create(:user_id => @u.id + 1, :comment => 'holooo', :content_id => 1, :host => '127.0.0.1')
      User.db_query("UPDATE comments SET created_on = created_on - '10 minutes'::interval")
      User.db_query("UPDATE contents SET created_on = now()")
      assert_equal c_count + 3, Comment.count 
    end
  end
  
  test "give_emblems_faith_avalanche" do
    assert_gives_emblem('faith_avalanche') do
      cv = CommentsValoration.new(:weight => 1.0, :comment_id => 2, :user_id => 1, :comments_valorations_type_id => CommentsValorationsType.find_by_name('Divertido').id)
      assert cv.save, cv.errors.full_messages_html
      User.db_query("UPDATE comments_valorations SET created_on = now() - '3 days'::interval WHERE id = #{cv.id}")
    end
  end
  
  test "give_emblems_oldest_faction_member" do
    assert_gives_emblem('oldest_faction_member') do
      Factions.user_joins_faction(@u, 1)
      Factions.user_joins_faction(User.find(@u.id + 1), 1)
      
      assert @u.update_attributes(:lastseen_on => Time.now)
      assert User.find(@u.id+1).update_attributes(:lastseen_on => Time.now)
    end
  end
    
  test "give_emblems_best_blogger" do
      assert Blogentry.find(1).update_attributes(:created_on => Time.now)
    assert_gives_emblem('best_blogger') do
      sym_pageview({:user_id => @u.id, :url => '/dadadd/adsdasd/1', :controller => 'blogs', :action => 'blogentry', :model_id => '1', :portal_id => nil})
      sym_pageview({:user_id => @u.id, :url => '/dadadd/adsdasd/1', :controller => 'blogs', :action => 'blogentry', :model_id => '1', :portal_id => nil})
      sym_pageview({:user_id => @u.id, :url => '/dadadd/adsdasd/1', :controller => 'blogs', :action => 'blogentry', :model_id => '2', :portal_id => nil})
      User.db_query("UPDATE stats.pageviews SET created_on = now() - '1 minute'::interval")
    end
  end  
end

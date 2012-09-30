# -*- encoding : utf-8 -*-
require 'test_helper'

class FaithTest < ActiveSupport::TestCase

  def setup
    @u1 = User.find(1)
    @initial_fp = @u1.faith_points
  end

  test "calculate_faith_points_should_consider_competitions_matches" do
    initial_matches = CompetitionsMatch.count
    c = Ladder.find(:first, :conditions => "competitions_participants_type_id = #{Competition::USERS} AND state = 3")
    assert_not_nil c
    initial_participants = CompetitionsParticipant.count
    p1 = c.competitions_participants.create({:participant_id => @u1.id, :name => @u1.login, :competitions_participants_type_id => c.competitions_participants_type_id, :roster => ''})
    p2 = c.competitions_participants.create({:participant_id => 3, :name => 'periko', :competitions_participants_type_id => c.competitions_participants_type_id, :roster => ''})
    assert_equal initial_participants + 2, CompetitionsParticipant.count
    cm = c.competitions_matches.create({:participant1_id => p1.id, :participant2_id => p2.id})
    cm.result = 1
    cm.admin_confirmed_result = true
    cm.completed_on = Time.now
    assert_equal true, cm.save
    @u1.cache_faith_points = nil
    @u1.save
    @u1.reload
    assert_equal @initial_fp + Faith::FPS_ACTIONS['competitions_match'], @u1.faith_points
  end

  test "calculate_faith_points_should_consider_content_ratings" do
    initial_cr = ContentRating.count
    @u1.content_ratings.create({
        :ip => '0.0.0.0',
        :content_id => Content.find(:first, :conditions => 'id NOT IN (SELECT content_id from content_ratings where user_id = 1)', :order => 'id').id,
        :rating => 1,
    })
    assert_equal initial_cr + 1, ContentRating.count
    @u1.cache_faith_points = nil
    @u1.save
    @u1.reload
    assert_equal @initial_fp + Faith::FPS_ACTIONS['rating'], @u1.faith_points
  end

  test "should_give_faith_points_if_valid" do
    u = User.find(1)
    kp_initial = u.faith_points
    Faith.give(u, 1)
    assert_equal kp_initial + 1, u.faith_points
    u.reload
    assert_equal kp_initial + 1, u.faith_points
  end

  test "should_take_faith_points_if_valid" do
    test_should_give_faith_points_if_valid
    u = User.find(1)
    kp_initial = u.faith_points
    Faith.take(u, 1)
    assert_equal kp_initial - 1, u.faith_points
    u.reload
    assert_equal kp_initial - 1, u.faith_points
  end

  test "should_not_corrupt_faith_points_cache_due_to_concurrency" do
    u_a = User.find(1)
    u_b = User.find(1)
    kp_initial = u_a.faith_points
    Faith.give(u_a, 1)
    Faith.give(u_b, 1)
    assert_equal kp_initial + 1, u_a.faith_points # la primera instancia no tiene los datos frescos, ok, para eso usamos la cache
    assert_equal kp_initial + 2, u_b.faith_points
    u_a.reload
    u_b.reload
    assert_equal kp_initial + 2, u_a.faith_points
    assert_equal kp_initial + 2, u_b.faith_points
  end

  test "level_should_work_correctly" do
    i = 0
    Faith::POINTS_PER_LEVEL.each do |kp|
      assert_equal i, Faith::level(kp)
      assert_equal((i-1), Faith::level(kp-1)) if kp > 0
      i += 1
    end
  end

  test "kp_for_level_should_work_correctly" do
    i = 0
    Faith::POINTS_PER_LEVEL.each do |kp|
      assert_equal kp, Faith::kp_for_level(i)
      i += 1
    end
  end

  test "pc_done_should_work" do
    assert_equal 0, Faith::pc_done_for_next_level(0)
    assert_equal 50, Faith::pc_done_for_next_level(Faith::POINTS_PER_LEVEL[1] / 2)
    assert_equal 99, Faith::pc_done_for_next_level(Faith::POINTS_PER_LEVEL[1] -1)
  end

  test "update_ranking" do
    User.db_query("UPDATE users SET cache_faith_points = id")
    Faith.update_ranking
    users_count = User.can_login.count
    assert_equal users_count, User.find(1).ranking_faith_pos
    assert_equal users_count - 1, User.find(2).ranking_faith_pos
    assert_equal users_count - 2, User.find(3).ranking_faith_pos
  end
end

# -*- encoding : utf-8 -*-
require 'test_helper'

class UserEmblemObserverTest < ActiveSupport::TestCase
  def post_comment(user, opts={})
    default_opts = {
          :comment => "foo",
          :content_id => 1,
          :host => "127.0.0.1",
    }
    comment = user.comments.create(default_opts)
    assert comment.update_attributes(opts)
    comment
  end

  test "comments nothing" do
    u1 = User.find(1)
    self.override_threshold("T_COMMENTS_COUNT_1", 10) do
      self.post_comment(u1)
    end
    assert !u1.has_emblem?("comments_count_1")
  end

  test "comments_valorations_received_divertido_1" do
    self.ensure_comments_valorations_received("Divertido", 1)
  end

  test "comments_valorations_received_divertido_2" do
    self.ensure_comments_valorations_received("Divertido", 2)
  end

  test "comments_valorations_received_divertido_3" do
    self.ensure_comments_valorations_received("Divertido", 3)
  end

  test "comments_valorations_received_interesante_1" do
    self.ensure_comments_valorations_received("Interesante", 1)
  end

  test "comments_valorations_received_interesante_2" do
    self.ensure_comments_valorations_received("Interesante", 2)
  end

  test "comments_valorations_received_interesante_3" do
    self.ensure_comments_valorations_received("Interesante", 3)
  end

  test "comments_valorations_received_profundo_1" do
    self.ensure_comments_valorations_received("Profundo", 1)
  end

  test "comments_valorations_received_profundo_2" do
    self.ensure_comments_valorations_received("Profundo", 2)
  end

  test "comments_valorations_received_profundo_3" do
    self.ensure_comments_valorations_received("Profundo", 3)
  end

  test "comments_valorations_received_informativo_1" do
    self.ensure_comments_valorations_received("Informativo", 1)
  end

  test "comments_valorations_received_informativo_2" do
    self.ensure_comments_valorations_received("Informativo", 2)
  end

  test "comments_valorations_received_informativo_3" do
    self.ensure_comments_valorations_received("Informativo", 3)
  end

  def ensure_comments_valorations_received(type_name, level)
    cvt = CommentsValorationsType.find_by_name(type_name)
    User.db_query("DELETE FROM comments_valorations")
    u1 = User.find(1)
    emblem_name = "comments_valorations_received_#{cvt.name.downcase}_#{level}"
    assert !u1.has_emblem?(emblem_name)
    self.override_threshold(
        "T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_#{level}", 1) do
      self.override_threshold(
          "T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_#{level}", 1) do
        self.override_threshold(
            "T_COMMENT_VALORATIONS_RECEIVED_USERS_#{level}", 1) do
          comment = self.post_comment(u1)
          u2 = User.find(2)
          assert_difference("comment.comments_valorations.count") do
            comment.comments_valorations.create({
              :user_id => u2.id,
              :weight => 0.5,
              :comments_valorations_type_id => cvt.id,
            })
          end
        end
      end
    end
    assert u1.has_emblem?(emblem_name)
  end

  test "comments comments_count_1" do
    self.ensure_comments_count_given(1)
  end

  test "comments comments_count_2" do
    self.ensure_comments_count_given(2)
  end

  test "comments comments_count_3" do
    self.ensure_comments_count_given(3)
  end

  def ensure_comments_count_given(level)
    u1 = User.find(1)
    current = u1.comments.karma_eligible.count
    self.override_threshold("T_COMMENTS_COUNT_#{level}", current + 1) do
      self.post_comment(u1)
    end
    assert u1.has_emblem?("comments_count_#{level}")
  end

  def override_threshold(threshold, value, &block)
    old_value = UsersEmblem.const_get(threshold)
    UsersEmblem.const_set(threshold, value)
    begin
      block.call
    rescue
      UsersEmblem.const_set(threshold, old_value)
      raise
    else
      UsersEmblem.const_set(threshold, old_value)
    end
  end

  test "the_beast" do
    u1 = User.find(1)
    assert !u1.has_emblem?("the_beast")
    u1.update_attribute(
        :cache_karma_points, UsersEmblem::T_THE_BEAST_KARMA_POINTS)
    u1.reload
    UserEmblemObserver::Emblems.the_beast(u1)
    assert u1.has_emblem?("the_beast")
  end

  test "comments_valorations_1" do
    u2 = User.find(56)
    assert !u2.has_emblem?("comments_valorations_1")
    assert_difference("u2.comments_valorations.count") do
      u2.comments_valorations.create(
          :comment_id => 1, :comments_valorations_type_id => 1, :weight => 0.3)
    end
    u2.reload
    assert u2.has_emblem?("comments_valorations_1")
  end

  test "comments_valorations_2" do
    self.ensure_comments_valorations_given(2)
  end

  test "comments_valorations_3" do
    self.ensure_comments_valorations_given(3)
  end

  def ensure_comments_valorations_given(level)
    # 3 people, u1 and u2 rate same comments as u3 will vote
    u1 = User.find(1)
    u2 = User.find(3)
    u3 = User.find(56)
    [u1, u2].each do |u|
      [1, 2].each do |comment_id|
        u.comments_valorations.create(
            :comment_id => comment_id,
            :comments_valorations_type_id => 1,
            :weight => 0.3)
      end
    end

    u3.comments_valorations.create(
        :comment_id => 1, :comments_valorations_type_id => 1, :weight => 0.3)

    assert !u3.has_emblem?("comments_valorations_#{level}")
    assert_difference("u3.comments_valorations.count") do
      self.override_threshold("T_COMMENT_VALORATIONS_#{level}", 2) do
        self.override_threshold(
            "T_COMMENT_VALORATIONS_#{level}_MATCHING_USERS", 2) do
          u3.comments_valorations.create(
              :comment_id => 2,
              :comments_valorations_type_id => 1,
              :weight => 0.3)
        end
      end
    end
    u3.reload
    assert u3.has_emblem?("comments_valorations_#{level}")
  end

  test "user_referers nothing" do
    assert_difference("UsersEmblem.count", 0) do
      UserEmblemObserver::Emblems.check_user_referers_candidates
    end
  end

  test "user_referers 1" do
    self.ensure_user_referer(1)
  end

  test "user_referers 2" do
    self.ensure_user_referer(2)
  end

  test "user_referers 3" do
    self.ensure_user_referer(3)
  end

  def ensure_user_referer(level)
    u2 = User.find(2)
    u2.update_attributes({
        :comments_count => 1,
        :created_on => 1.year.ago,
        :lastseen_on => 1.day.ago,
        :referer_user_id => 1,
    })
    u1 = User.find(1)

    self.override_threshold("T_REFERER_#{level}", 1) do
      assert_difference(
          "u1.users_emblems.emblem('user_referer_#{level}').count") do
        UserEmblemObserver::Emblems.check_user_referers_candidates
      end
    end
  end

  test "karma_rage 1" do
    self.ensure_karma_rage(1)
  end

  test "karma_rage 2" do
    self.ensure_karma_rage(2)
  end

  test "karma_rage 3" do
    self.ensure_karma_rage(3)
  end

  def ensure_karma_rage(level)
    u1 = User.find(1)
    User.db_query("UPDATE comments SET karma_points = 0 WHERE user_id = 1")
    User.db_query("UPDATE contents SET karma_points = 0 WHERE user_id = 1")
    self.post_comment(
        u1,
        :created_on => Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS.days.ago,
        :karma_points => 1)
    self.post_comment(
        u1,
        :created_on => (Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS + 1).days.ago,
        :karma_points => 1)
    self.post_comment(
        u1,
        :created_on => (Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS + 2).days.ago,
        :karma_points => 1)
    self.override_threshold("T_KARMA_RAGE_#{level}", 3) do
      assert_difference(
          "u1.users_emblems.emblem('karma_rage_#{level}').count") do
        UserEmblemObserver::Emblems.check_karma_rage
      end
    end
  end

  test "ensure_no_karma_rage_if_not_enough 1" do
    u1 = User.find(1)
    User.db_query("UPDATE comments SET karma_points = 0 WHERE user_id = 1")
    User.db_query("UPDATE contents SET karma_points = 0 WHERE user_id = 1")
    self.post_comment(u1, :created_on => 14.days.ago, :karma_points => 1)
    self.post_comment(u1, :created_on => 16.days.ago, :karma_points => 1)
    self.post_comment(u1, :created_on => 17.days.ago, :karma_points => 1)
    self.override_threshold("T_KARMA_RAGE_1", 3) do
      assert_difference(
          "u1.users_emblems.emblem('karma_rage_1').count", 0) do
        UserEmblemObserver::Emblems.check_karma_rage
      end
    end
  end

  test "rockefeller with U2U transfers" do
    u1 = User.find(1)
    User.db_query("UPDATE users SET cash = #{UsersEmblem::T_ROCKEFELLER} where id = #{u1.id}")
    u2 = User.find(2)
    assert !u2.has_emblem?("rockefeller")
    Bank.transfer(u1, u2, UsersEmblem::T_ROCKEFELLER, "rockefeller!")
    UserEmblemObserver::Emblems.rockefeller(u2)
    assert !u2.has_emblem?("rockefeller")
  end

  test "rockefeller without U2U transfers" do
    u2 = User.find(2)
    assert !u2.has_emblem?("rockefeller")
    Bank.transfer(:bank, u2, UsersEmblem::T_ROCKEFELLER, "rockefeller!")
    UserEmblemObserver::Emblems.rockefeller(u2)
    assert u2.has_emblem?("rockefeller")
  end

  test "first content published" do
    u1 = User.find(1)
    assert !u1.has_emblem?("first_content")
    n = News.create({
      :title => "foo",
      :description => "bar",
      :user_id => u1.id,
    })
    Content.publish_content_directly(n, u1)
    n.reload
    assert_equal Cms::PUBLISHED, n.state
    assert u1.has_emblem?("first_content")
  end

  test "suv" do
    u1 = User.find(1)
    assert !u1.has_emblem?("suv")
    ContentType.find(:all).each do |ct|
      assert !u1.has_emblem?("suv")
      self.publish_content_of_type(ct, u1)
      content = u1.contents.find(:first, :order => 'id DESC')
      assert content.update_attribute(
          :karma_points, UsersEmblem::T_SUV_MIN_KARMA_POINTS)
    end
    assert u1.has_emblem?("suv")
  end

  def publish_content_of_type(content_type, author)
    cls = Object.const_get(content_type.name)
    new_content = cls.new({
        :user_id => author.id,
    })

    if content_type.name == "Bet"
      new_content.closes_on = 3.days.since
    end

    if content_type.name == "Coverage"
      new_content.event_id = Event.published.first.id
    end

    if %w(Poll Event).include?(content_type.name)
      new_content.starts_on = 3.days.since
      new_content.ends_on = 10.days.since
    end

    if !%w(Blogentry Poll RecruitmentAd Topic).include?(content_type.name)
      new_content.description = "foo #{cls.name}"
    elsif content_type.name != "Poll"
      new_content.main = "foo #{cls.name}"
    end

    if content_type.name == "Demo"
      new_content.games_mode_id = GamesMode.first.id
      new_content.entity1_local_id = 1
      new_content.entity2_local_id = 2
    end

    if content_type.name == "RecruitmentAd"
      new_content.game_id = 1
    end

    if %w(Tutorial Column Interview Review Funthing).include?(content_type.name)
      new_content.main = "foo article"
    end

    if content_type.name != "Image"
      new_content.title = "foo #{cls.name}"
    end
    new_content.terms = 1
    assert new_content.save, new_content.errors.full_messages_html
    Content.publish_content_directly(new_content, author)
    assert_equal(Cms::PUBLISHED, new_content.state)
  end
end

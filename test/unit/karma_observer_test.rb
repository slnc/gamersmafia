# -*- encoding : utf-8 -*-
require 'test_helper'

class KarmaObserverTest < ActiveSupport::TestCase
  # COMMENTS
  test "should_give_karma_from_author_when_comment_is_created" do
    u = User.find(1)
    kp_initial = u.karma_points
    c = Comment.new({
        :content_id => 1,
        :user_id => 1,
        :host => '127.0.0.1',
        :comment => 'comentario de prueba',
        :created_on => Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS.days.ago,
    })
    assert c.save
    c.comments_valorations.create(
        :user_id => 2,
        :comments_valorations_type_id => CommentsValorationsType.positive.find(
          :first).id,
        :weight => 0.5,
    )
    u.reload
    assert_equal kp_initial + Karma.comment_karma(c), u.karma_points
  end

  test "should_take_karma_from_author_when_comment_deleted" do
    test_should_give_karma_from_author_when_comment_is_created
    u = User.find(1)
    kp_initial = u.karma_points
    c = Comment.find(:first, :order => 'id DESC')
    original_kp = Karma.comment_karma(c)
    c.mark_as_deleted
    u.reload
    assert_equal kp_initial - original_kp, u.karma_points
  end

  # CONTENTS
  test "should_give_karma_when_content_is_published" do
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = self.create_some_news
    u2.reload
    assert_equal u2_kp_initial, u2.karma_points
    n.reload

    # publicamos
    Cms::publish_content(n, User.find(1))
    assert n.is_public?
    u2.reload
    assert_equal u2_kp_initial + n.unique_content.karma_points, u2.karma_points
  end

  test "should_give_reduced_karma_when_copypaste_content_is_published" do
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = self.create_some_news(:source => 'http://google.com/')
    u2.reload
    assert_equal u2_kp_initial, u2.karma_points
    n.reload

    # publicamos
    Cms::publish_content(n, User.find(1))
    original_kp = n.unique_content.karma_points
    assert n.is_public?
    u2.reload
    assert_equal u2_kp_initial + original_kp, u2.karma_points
  end

  test "should give reduced karma when copypaste after publication" do
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = self.create_some_news
    u2.reload
    assert_equal u2_kp_initial, u2.karma_points
    n.reload

    # publicamos
    Cms::publish_content(n, User.find(1))
    original_kp = n.unique_content.karma_points
    assert n.is_public?
    u2.reload
    assert_equal u2_kp_initial + original_kp, u2.karma_points
    assert original_kp > 0

    # change source
    assert n.update_attributes(:source => 'http://google.com')

    u2.reload
    assert u2.karma_points < u2_kp_initial + original_kp
  end

  test "should_take_karma_when_content_is_unpublished" do
    test_should_give_karma_when_content_is_published
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.find(:first, :order => 'id DESC')
    assert_equal true, n.is_public?
    original_kp = n.unique_content.karma_points
    Cms::deny_content(n, User.find(1), 'foo')
    u2.reload
    assert_equal u2_kp_initial - original_kp, u2.karma_points
  end

  test "should_delete_karma_to_owner_when_content_is_marked_as_deleted" do
    test_should_give_karma_when_content_is_published
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.find(:first, :order => 'id DESC')
    assert n.is_public?
    n.change_state(Cms::DELETED, User.find(1))
    u2.reload
    assert_equal u2_kp_initial - Karma.contents_karma(n.unique_content)[0], u2.karma_points
  end

  test "should_take_karma_from_owner_when_content_is_directly_deleted_and_was_published" do
    test_should_give_karma_when_content_is_published
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.find(:first, :order => 'id DESC')
    assert n.is_public?
    original_kp = n.unique_content.karma_points
    n.destroy
    u2.reload
    assert_equal u2_kp_initial - original_kp, u2.karma_points
  end

  test "should_do_nothing_to_karma_if_content_is_deleted_and_was_previously_marked_as_deleted" do
    test_should_delete_karma_to_owner_when_content_is_marked_as_deleted
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.find(:first, :order => 'id DESC')
    assert_equal Cms::DELETED, n.state
    n.destroy
    u2.reload
    assert_equal u2_kp_initial, u2.karma_points
  end

  def create_some_news(opts={})
    news = News.new({
        :title => 'noticia foo',
        :description => 'sumario de noticia guay',
        :terms => 1,
        :user_id => 2,
        :created_on => (Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS + 1).days.ago,
    }.merge(opts))
    assert news.save
    news.unique_content.update_attributes(
        :created_on => (Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS + 1).days.ago)

    assert_difference("news.unique_content.comments.count", 3) do
      3.times do |i|
        news.unique_content.comments.create(
          :user_id => news.user_id + i,
          :comment => "hellllo #{i}",
          :host => '127.0.0.1',
          :created_on => Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS.days.ago)
      end
    end
    news
  end

  test "should_do_nothing_to_karma_if_content_is_deleted_and_is_not_public" do
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = self.create_some_news
    n.destroy
    u2.reload
    assert_equal u2_kp_initial, u2.karma_points
  end

  #test "should_do_nothing_to_karma_if_content_has_its_authorship_changed_and_is_not_published" do
  #  u = User.find(2)
  #  kp_initial = u.karma_points
  #  n = self.create_some_news
  #  assert_equal true, n.save
  #  u1 = User.find(1)
  #  n.change_authorship(u1, u1)
  #  u.reload
  #  assert_equal kp_initial, u.karma_points
  #end

  #test "should_properly_update_karma_when_changing_authorship_and_is_published" do
  #  test_should_give_karma_when_content_is_published
  #  n = News.find(:first, :order => 'id DESC')
  #  assert_equal true, n.is_public?

  #  u2 = User.find(2) # author
  #  kp_u2_initial = u2.karma_points
  #  u1 = User.find(1) # new author
  #  kp_u1_initial = u1.karma_points
  #  n.change_authorship(u1, u1)
  #  u1.reload
  #  u2.reload
  #  assert_equal kp_u2_initial - Karma::KPS_CREATE['News'], u2.karma_points
  #  assert_equal kp_u1_initial + Karma::KPS_CREATE['News'], u1.karma_points
  #end
end

# -*- encoding : utf-8 -*-
require 'test_helper'

class KarmaObserverTest < ActiveSupport::TestCase
  # COMMENTS
  test "should_give_karma_from_author_when_comment_is_created" do
    u = User.find(1)
    kp_initial = u.karma_points
    c = Comment.new({:content_id => 1, :user_id => 1, :host => '127.0.0.1', :comment => 'comentario de prueba'})
    assert_equal true, c.save
    u.reload
    assert_equal kp_initial + Karma::KPS_CREATE['Comment'], u.karma_points
  end

  test "should_take_karma_from_author_when_comment_deleted" do
    test_should_give_karma_from_author_when_comment_is_created
    u = User.find(1)
    kp_initial = u.karma_points
    Comment.find(:first, :order => 'id DESC').mark_as_deleted
    u.reload
    assert_equal kp_initial - Karma::KPS_CREATE['Comment'], u.karma_points
  end

  # CONTENTS
  test "should_give_karma_when_content_is_published" do
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.new({:title => 'noticia foo', :description => 'sumario de noticia guay', :terms => 1, :user_id => 2})
    assert_equal true, n.save
    u2.reload
    assert_equal u2_kp_initial, u2.karma_points
    n.reload

    # publicamos
    Cms::publish_content(n, User.find(1))
    assert n.is_public?
    u2.reload
    assert_equal u2_kp_initial + Karma::KPS_CREATE['News'], u2.karma_points
  end

  test "should_give_reduced_karma_when_copypaste_content_is_published" do
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.new({:title => 'noticia foo', :description => 'sumario de noticia guay', :terms => 1, :user_id => 2, :source => 'http://google.com' })
    assert_equal true, n.save
    u2.reload
    assert_equal u2_kp_initial, u2.karma_points
    n.reload

    # publicamos
    Cms::publish_content(n, User.find(1))
    assert n.is_public?
    u2.reload
    assert_equal u2_kp_initial + Karma::KPS_CREATE['Copypaste'], u2.karma_points
  end

  test "should_take_karma_when_content_is_unpublished" do
    test_should_give_karma_when_content_is_published
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.find(:first, :order => 'id DESC')
    assert_equal true, n.is_public?
    Cms::deny_content(n, User.find(1), 'foo')
    u2.reload
    assert_equal u2_kp_initial - Karma::KPS_CREATE['News'], u2.karma_points
  end

  test "should_delete_karma_to_owner_when_content_is_marked_as_deleted" do
    test_should_give_karma_when_content_is_published
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.find(:first, :order => 'id DESC')
    assert_equal true, n.is_public?
    n.change_state(Cms::DELETED, User.find(1))
    u2.reload
    assert_equal u2_kp_initial - Karma::KPS_CREATE['News'], u2.karma_points
  end

  test "should_take_karma_from_owner_when_content_is_directly_deleted_and_was_published" do
    test_should_give_karma_when_content_is_published
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.find(:first, :order => 'id DESC')
    assert_equal true, n.is_public?
    n.destroy
    u2.reload
    assert_equal u2_kp_initial - Karma::KPS_CREATE['News'], u2.karma_points
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

  test "should_do_nothing_to_karma_if_content_is_deleted_and_is_not_public" do
    u2 = User.find(2)
    u2_kp_initial = u2.karma_points
    n = News.new({:title => 'noticia foo', :description => 'sumario de noticia guay', :terms => 1, :user_id => 2})
    assert_equal true, n.save
    n.destroy
    u2.reload
    assert_equal u2_kp_initial, u2.karma_points
  end

  test "should_do_nothing_to_karma_if_content_has_its_authorship_changed_and_is_not_published" do
    u = User.find(2)
    kp_initial = u.karma_points
    n = News.new({:title => 'noticia foo', :description => 'sumario de noticia guay', :terms => 1, :user_id => 2})
    assert_equal true, n.save
    u1 = User.find(1)
    n.change_authorship(u1, u1)
    u.reload
    assert_equal kp_initial, u.karma_points
  end

  test "should_properly_update_karma_when_changing_authorship_and_is_published" do
    test_should_give_karma_when_content_is_published
    n = News.find(:first, :order => 'id DESC')
    assert_equal true, n.is_public?

    u2 = User.find(2) # author
    kp_u2_initial = u2.karma_points
    u1 = User.find(1) # new author
    kp_u1_initial = u1.karma_points
    n.change_authorship(u1, u1)
    u1.reload
    u2.reload
    assert_equal kp_u2_initial - Karma::KPS_CREATE['News'], u2.karma_points
    assert_equal kp_u1_initial + Karma::KPS_CREATE['News'], u1.karma_points
  end
end

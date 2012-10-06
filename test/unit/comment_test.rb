# -*- encoding : utf-8 -*-
require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  COPYRIGHT = Comment::MODERATION_REASONS[:copyright]

  test "moderate should work" do
    comment = create_a_comment
    comment.moderate(User.find(1), COPYRIGHT)
    assert_equal 1, comment.lastedited_by_user_id
    assert_equal Comment::MODERATED, comment.state
    assert_equal COPYRIGHT, comment.moderation_reason
  end

  test "don't moderate self" do
    comment = create_a_comment
    assert_raises(RuntimeError) do
      comment.moderate(comment.user, COPYRIGHT)
    end
  end

  test "don't moderate twice" do
    comment = create_a_comment
    comment.moderate(User.find(1), COPYRIGHT)
    assert_raises(RuntimeError) do
      comment.moderate(User.find(1), COPYRIGHT)
    end
  end

  test "superadmin reporting a comment triggers automatic removal" do
    u1 = User.find(1)
    comment = create_a_comment
    comment.report_violation(u1, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, u1)
  end

  test "normal user reporting a comment does not trigger automatic removal" do
    user = User.find(4)
    comment = create_a_comment
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_not_moderated(comment)
  end

  test "capo reporting a comment triggers automatic removal" do
    user = User.find(4)
    give_skill(user.id, "Capo")
    comment = create_a_comment
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  test "faction moderator reporting a comment triggers automatic removal" do
    user = User.find(4)
    comment = create_a_comment
    user.users_skills.create(
        :role => "Moderator",
        :role_data => comment.content.my_faction.id.to_s)
    assert user.is_moderator?
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  test "faction boss reporting a comment triggers automatic removal" do
    user = User.find(4)
    comment = create_a_comment
    faction = comment.content.my_faction
    user.users_skills.create(
        :role => "Boss",
        :role_data => faction.id.to_s)
    assert faction.user_is_moderator(user)
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  test "don reporting a comment triggers automatic removal" do
    user = User.find(4)
    comment = create_a_comment(:content_id => 1113)
    bazar_district = comment.content.bazar_district
    user.users_skills.create(
        :role => "Don",
        :role_data => bazar_district.id.to_s)
    assert bazar_district.user_is_moderator(user)
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  test "sicario reporting a comment triggers automatic removal" do
    user = User.find(4)
    comment = create_a_comment(:content_id => 1113)
    bazar_district = comment.content.bazar_district
    user.users_skills.create(
        :role => "Sicario",
        :role_data => bazar_district.id.to_s)
    assert bazar_district.user_is_moderator(user)
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  def assert_comment_not_moderated(comment)
    assert_not_equal Comment::MODERATED, comment.state
  end

  def assert_comment_moderated(comment, moderator)
    assert_equal Comment::MODERATED, comment.state
    assert_equal moderator.id, comment.lastedited_by_user_id
  end

  def create_a_comment(opts={})
    final_opts = {
      :user_id => 2,
      :comment => "hola #{User.find(2).login}",
      :content_id => 1,
      :host => '127.0.0.1',
    }.merge(opts)
    Comment.create(final_opts)
  end

  test "refered_people_should_work" do
    c = create_a_comment
    assert c.save
    references = c.regenerate_ne_references
    assert_equal 'User', references[0].entity_class
    assert_equal 'Comment', references[0].referencer_class
    assert_equal 2, references[0].entity_id
    assert_equal c.id, references[0].referencer_id

    assert_equal references[0].id, c.content.ne_references[0].id
    assert_equal references[0].id, User.find(2).ne_references[0].id
  end


  test "should_create_comment_if_valid" do
    content = Content.find(1)
    content.url = nil
    content.portal_id = nil
    Routing.gmurl(content)
    assert_not_nil content.portal_id
    c = Comment.new({
        :user_id => 1,
        :comment => 'hola mundo!',
        :content_id => 1,
        :host => '127.0.0.1',
    })
    assert c.save
    c.reload
    assert_not_nil c.portal_id
    c.reload
    u = User.find(1)
    assert_equal u.lastcommented_on.to_i, c.created_on.to_i
  end

  test "should_properly_save_copy_when_being_moderated" do
    c = Comment.new({:user_id => 1, :comment => 'u1', :content_id => 1, :host => '127.0.0.1'})
    assert_equal true, c.save
    assert_nil c.lastowner_version
    assert_nil c.lastedited_by_user_id
    assert c.update_attributes(:lastedited_by_user_id => 2, :comment => 'u2')
    assert_equal 'u1', c.lastowner_version
    assert_equal 2, c.lastedited_by_user_id

    # lo edita otra vez el mismo moderadors
    assert c.update_attributes(:lastedited_by_user_id => 2, :comment => 'u22')
    assert_equal 'u1', c.lastowner_version
    assert_equal 2, c.lastedited_by_user_id

    # ahora lo edita un segundo moderador
    assert c.update_attributes(:lastedited_by_user_id => 3, :comment => 'u3')
    assert_equal 'u1', c.lastowner_version
    assert_equal 3, c.lastedited_by_user_id

    # ahora lo vuelve a editar el propietario
    assert c.update_attributes(:lastedited_by_user_id => 1, :comment => 'u1b')
    assert_nil c.lastowner_version
    assert_equal 1, c.lastedited_by_user_id
  end

  test "should_not_create_comment_if_duplicated" do
  end

  test "should_properly_update_lastcommented_on_from_author_when_destroying_comments" do
    # caso 1: existen comentarios anteriormente
    test_should_create_comment_if_valid
    c2 = Comment.new(:user_id => 1, :comment => 'hola mundo2!', :content_id => 1, :host => '127.0.0.1')
    assert_equal true, c2.save
    c2.reload
    assert_not_nil c2.mark_as_deleted
    u = User.find(1)
    last_c = Comment.find(:first, :conditions => 'user_id = 1', :order => 'id DESC')
    assert_equal u.lastcommented_on.to_i, last_c.created_on.to_i

    # caso 2: no existen comentarios anteriormente
    Comment.find(:all, :conditions => 'user_id = 1').each { |comment| comment.mark_as_deleted }
    u.reload
    assert_nil u.lastcommented_on
  end
end

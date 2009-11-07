require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  
  test "refered_people_should_work" do
    c = Comment.new({:user_id => 1, :comment => "hola #{User.find(2).login}", :content_id => 1, :host => '127.0.0.1'})
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
    ApplicationController.gmurl(content) # TODO temp make sure the fixture has portal_id set
    assert_not_nil content.portal_id
    c = Comment.new({:user_id => 1, :comment => 'hola mundo!', :content_id => 1, :host => '127.0.0.1'})
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

  test "should_not_create_comment_if_last_comment_is_from_the_same_user_and_is_too_soon" do
    # TODO
  end

  test "should_properly_update_lastcommented_on_from_author_when_destroying_comments" do
    # caso 1: existen comentarios anteriormente
    test_should_create_comment_if_valid
    c2 = Comment.new({:user_id => 1, :comment => 'hola mundo2!', :content_id => 1, :host => '127.0.0.1'})
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

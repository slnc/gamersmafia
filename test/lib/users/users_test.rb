require File.dirname(__FILE__) + '/../../../test/test_helper'

class UsersTestController < ActionController::Base
  include Users::Authentication
  
  public
  def action_user_is_authed
    user_is_authed
  end
  
  def action_require_user_is_staff
    require_user_is_staff
  end
  
  def action_require_user_can_edit(content)
    require_user_can_edit(content)
  end
  
  def action_require_auth_users
    require_auth_users
  end
  
  def action_require_admin_permission_faq
    require_admin_permission_faq
  end
  
  def action_require_auth_admins
    require_auth_admins
  end
  
  def action_ident
    ident
  end
end

class UsersTest < ActiveSupport::TestCase
  def setup
    @inst = UsersTestController.new
  end
  
  test "user_is_authed" do
    assert_equal false, @inst.action_user_is_authed
    @inst.user = User.find(1)
    assert_equal true, @inst.action_user_is_authed
  end
  
  # TODO faltan tests
  #
  test "should_add_to_tracker_if_existing_user_id_and_content_id" do
    TrackerItem.db_query("DELETE FROM tracker_items")
    u = User.find(1)
    c = Content.find(1)
    Users.add_to_tracker(u, c)
    assert_equal 1, TrackerItem.count
    assert_equal true, u.using_tracker
    ti = TrackerItem.find(:first, :order => 'id DESC')
    assert_equal true, ti.is_tracked?
  end
  
  test "should_remove_from_tracker_if_existing_user_id_and_content_id" do
    test_should_add_to_tracker_if_existing_user_id_and_content_id
    u = User.find(1)
    c = Content.find(1)
    Users.remove_from_tracker(u, c)
    assert_equal false, u.using_tracker
    ti = TrackerItem.find(:first, :order => 'id DESC')
    assert_equal false, ti.is_tracked?
  end
end

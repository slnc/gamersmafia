# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::TagsControllerTest < ActionController::TestCase
  test "index" do
    sym_login 1
    c1 = Content.find(1)
    UsersContentsTag.tag_content(c1, User.find(1), 'hola tio')
    uct = UsersContentsTag.find_by_original_name('tio')
    get :index
    assert_response :success
  end

  test "destroy should work" do
    sym_login 1
    c1 = Content.find(1)
    UsersContentsTag.tag_content(c1, User.find(1), 'hola tio')
    uct = UsersContentsTag.find_by_original_name('tio')
    assert_not_nil uct
    assert_not_nil uct.term
    delete :destroy, :id => uct.id
    assert_response :success
    assert_nil UsersContentsTag.find_by_id(uct.id)
    # assert_nil Term.find_by_id(uct.term_id)
  end
end

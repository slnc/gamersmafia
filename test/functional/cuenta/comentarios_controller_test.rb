# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::ComentariosControllerTest < ActionController::TestCase

  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "save" do
    User.db_query("UPDATE users SET enable_comments_sig = 't' WHERE id = 1")

    sym_login 1
    assert_difference("UsersPreference.count", 2) do
      post :save, {
          :user => {
              :comments_sig => 'Foo',
              :comment_show_sigs => true,
              :pref_comments_autoscroll => '0',
              :pref_show_all_comments => '0',
          }
      }
    end

    assert_response :redirect

    u1 = User.find(1)
    assert_equal '0', u1.pref_comments_autoscroll
    assert_equal '0', u1.pref_show_all_comments
    assert_equal 'Foo', u1.comments_sig
    assert u1.comment_show_sigs
  end
end

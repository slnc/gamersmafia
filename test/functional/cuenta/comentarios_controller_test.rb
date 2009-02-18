require File.dirname(__FILE__) + '/../../test_helper'

class Cuenta::ComentariosControllerTest < ActionController::TestCase
  
  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_save
    User.db_query("UPDATE users SET enable_comments_sig = 't' WHERE id = 1")
    sym_login 1
    assert_count_increases(UsersPreference) do
      post :save, {:user => { :comments_sig => 'Foo', :comment_show_sigs => true, :pref_comments_autoscroll => '0'}}
    end
    
    assert_response :redirect
    u1 = User.find(1)
    assert_equal 0, u1.pref_comments_autoscroll
    assert_equal 'Foo', u1.comments_sig
    assert u1.comment_show_sigs
    assert_response :redirect
  end
end

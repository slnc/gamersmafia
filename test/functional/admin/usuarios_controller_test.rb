require File.dirname(__FILE__) + '/../../test_helper'

class Admin::UsuariosControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :edit, :update, :destroy, :check_registered_on, :check_karma, :check_faith ]
  
  def test_index
    sym_login :superadmin
    get :index, {}
    assert_response :success
    assert_template 'index'
  end
  
  def test_search
    sym_login :superadmin
    get :index, {:s => 'panzer'}
    assert_response :success
    assert_template 'index'
    assert_not_nil @response.body =~ /panzer/
  end
  
  #  def test_should_not_destroy_non_superadmin_user_if_get
  #    get :destroy, :id => 2
  #    assert_redirected_to '/admin/usuarios'
  #  end
  
  def test_check_registered_on
    sym_login 1
    post :check_registered_on, { :id => 1}
    assert_response :success
  end
  
  def test_check_karma
    sym_login 1
    post :check_karma, { :id => 1}
    assert_response :success
  end
  
  def test_send_hq_invitation
    sym_login 1
    assert_count_increases(Message) do
      post :send_hq_invitation, { :id => 2}
      assert_response :redirect
    end
  end
  
  def test_check_faith
    sym_login 1
    post :check_karma, { :id => 1}
    assert_response :success
  end
  
  def test_check_gmf
    sym_login 1
    post :check_karma, { :id => 1}
    assert_response :success
  end
  
  
  
  def test_should_not_destroy_superadmin_user
    sym_login :superadmin
    assert_raises(ActiveRecord::RecordNotFound) { post :destroy, :id => 1 }
  end
  
  def test_del_comments_should_work
    sym_login :superadmin
    post :del_comments, { :comments => ['1']}
    assert Comment.find(1).deleted?
    assert_response :redirect
  end
  
  def test_should_destroy_non_superadmin_user
    sym_login :superadmin
    assert_not_nil User.find_by_id(3)
    post :destroy, :id => 3
    assert_redirected_to '/admin/usuarios'
    assert_nil User.find_by_id(3)
  end
  
  def test_should_edit_existing_user
    sym_login :superadmin
    get :edit, :id => 2
    assert_response :success
    assert_template 'edit'
  end
  
  def test_should_update_existing_user
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    post :update, { :id => 2, :edituser => { :login => 'panzerito' } }
    assert_redirected_to :action => 'edit', :id => panzer.id
    panzer.reload
    assert_equal 'panzerito', panzer.login
  end
  
  def test_should_update_existing_user_without_changing_faction_if_nil_faction
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    old_faction_id = panzer.faction_id
    old_last_changed_faction = panzer.faction_last_changed_on
    post :update, { :id => 2, :edituser => { :login => 'panzerito', :faction_id => panzer.faction_id.to_s } }
    assert_redirected_to :action => 'edit', :id => panzer.id
    panzer.reload
    assert_equal old_faction_id, panzer.faction_id
    assert_equal old_last_changed_faction, panzer.faction_last_changed_on
  end
  
  def test_should_update_existing_user_without_changing_faction_if_not_nil_faction
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    panzer.faction_id = 1
    panzer.faction_last_changed_on = 3.months.ago
    panzer.save
    panzer.reload
    old_faction_id = panzer.faction_id
    old_last_changed_faction = panzer.faction_last_changed_on
    post :update, { :id => 2, :edituser => { :login => 'panzerito', :faction_id => panzer.faction_id.to_s } }
    assert_redirected_to :action => 'edit', :id => panzer.id
    panzer.reload
    assert_equal old_faction_id, panzer.faction_id
    assert_equal old_last_changed_faction.to_i, panzer.faction_last_changed_on.to_i
  end
  
  def test_should_update_existing_users_new_state_deleted
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    post :update, { :id => 2, :edituser => { :login => 'panzer', :state => User::ST_DISABLED } }
    assert_redirected_to :action => 'edit', :id => panzer.id
    panzer.reload
    assert panzer.state == User::ST_DISABLED
  end
  
  # TODO faltan tests de check_*
  #
  def test_should_fix_gmf_ammount_if_incorrect
    sym_login :superadmin
    User.db_query("UPDATE users SET cash = cash + 50 WHERE login = 'panzer'")
    panzer = User.find_by_login(:panzer)
    post :check_gmf, { :id => 2 }
    assert_response :success
    assert_template 'check_gmf_fixed'
  end
  
  def test_should_do_nothing_if_gmf_ammount_is_correct
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    Bank.transfer(:bank, panzer, 10, 'test')
    panzer.reload
    post :check_gmf, { :id => 2 }
    assert_response :success
    assert_template 'check_gmf_ok'
  end
  
  def test_reset_avatar_should_reset_avatar
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    panzer.avatar_id = 1
    assert_equal true, panzer.save
    post :reset_avatar, { :id => panzer.id}
    assert_redirected_to "/admin/usuarios/edit/#{panzer.id}"
    panzer.reload
    assert_equal nil, panzer.avatar_id
  end
  
  def test_ban_should_work
    sym_login :superadmin
    u2 = User.find(2)
    assert_not_equal User::ST_BANNED, u2.state
    post :ban, { :id => 2 }
    u2.reload
    assert_equal User::ST_BANNED, u2.state
  end
  
  def test_ban_request_shouldnt_work_for_normal_user
    assert_raises(AccessDenied) { get :ban_request }  
  end
  
  def test_ban_request_should_work_for_capo
    u2 = User.find(2)
    u2.give_admin_permission(:capo)
    sym_login 2
    @u3 = User.find(3)
    get :ban_request, :login => @u3.login 
    assert_response :success
  end
  
  
  def test_confirmar_ban_request_should_work_for_capo
    u2 = User.find(2)
    u2.give_admin_permission(:capo)
    sym_login 2
    get :confirmar_ban_request, :id => 1 
    assert_response :success
  end
  
  def test_confirmar_ban_request_should_work_for_hq
    u2 = User.find(2)
    u2.is_hq = true
    u2.save
    sym_login 2
    get :confirmar_ban_request, :id => 1 
    assert_response :success
  end
  
  def test_create_ban_request_should_work_for_capo
    u2 = User.find(2)
    u2.give_admin_permission(:capo)
    @u3 = User.find(3)
    sym_login 2
    assert_count_increases(BanRequest) do
      post :create_ban_request, {:login => @u3.login, :reason => "Reiteradas violaciones del código de conducta." }
      assert_redirected_to "/miembros/#{@u3.login}"
    end
  end
  
  def test_confirm_ban_request_should_work_for_capo
    test_create_ban_request_should_work_for_capo
    @u4 = User.find(56)
    @u4.give_admin_permission(:capo)
    sym_login @u4
    last = BanRequest.find(:first, :order => 'id desc')
    post :confirm_ban_request, {:id => last.id }
    last.reload
    assert_equal @u4.id, last.confirming_user_id
    assert_redirected_to "/site/slog"
  end
  
  def test_create_unban_request_should_work_for_capo
    test_confirm_ban_request_should_work_for_capo
    sym_login 2
    post :create_unban_request, {:login => @u3.login, :reason_unban => "ahora es buen chico" }
    @br = BanRequest.find_by_banned_user_id(@u3.id)
    assert_equal 2, @br.unban_user_id
  end
  
  def test_confirm_unban_request_should_work_for_capo
    test_create_unban_request_should_work_for_capo
    sym_login @u4.id
    post :confirm_unban_request, {:id => @br.id }
    @br.reload
    assert_equal @u4.id, @br.unban_confirming_user_id
    @u3.reload
    assert_not_equal User::ST_BANNED, @u3.state
  end
  
  def test_cancel_ban_request_should_work_for_owner
    test_create_ban_request_should_work_for_capo
    last = BanRequest.find(:first, :order => 'id desc')
    assert_count_decreases(BanRequest) { post :cancel_ban_request, {:id => last.id } }
    assert_redirected_to "/site/slog"
  end
  
  def test_should_set_antiflood_level_if_capo
    @u4 = User.find(56)
    @u4.give_admin_permission(:capo)
    sym_login @u4
    u2 = User.find(2)
    assert_equal -1, u2.antiflood_level
    post :set_antiflood_level, {:user_id => 2, :antiflood_level => '5'}
    assert_redirected_to "/miembros/#{u2.login}"
    u2.reload
    assert_equal 5, u2.antiflood_level
  end
  
  def test_should_set_antiflood_max_if_hq
    @u4 = User.find(56)
    @u4.is_superadmin = false
    @u4.save
    assert @u4.take_admin_permission(:capo)
    assert !@u4.has_admin_permission?(:capo)
    @u4.reload
    @u4.is_hq = true
    assert @u4.save
    
    
    sym_login @u4
    u2 = User.find(2)
    assert_equal -1, u2.antiflood_level
    assert_count_increases(SlogEntry) do
      post :set_antiflood_level, {:user_id => 2, :antiflood_level => '5'}
    end
    assert_redirected_to "/miembros/#{u2.login}"
    u2.reload
    assert_equal 5, u2.antiflood_level
  end
  
  def test_clear_description
    @u4 = User.find(56)
    @u4.give_admin_permission(:capo)
    sym_login @u4
    @u2 = User.find(2)
    @u2.description = "I rock"
    assert @u2.save
    post :clear_description, :id => @u2.id
    assert_response :redirect
    assert_redirected_to "/miembros/#{@u2.login}"
    @u2.reload
    assert_nil @u2.description
  end
  
  def test_clear_photo
    @u4 = User.find(56)
    @u4.give_admin_permission(:capo)
    sym_login @u4
    @u2 = User.find(2)
    User.db_query("UPDATE users SET photo = 'asdadad' WHERE id = #{@u2.id}")
    post :clear_photo, :id => @u2.id
    assert_response :redirect
    assert_redirected_to "/miembros/#{@u2.login}"
    @u2.reload
    assert_nil @u2.photo
  end
  
  def test_report
    @u4 = User.find(56)
    @u4.is_hq = true
    assert @u4.save
    sym_login @u4.id
    assert_count_increases(SlogEntry) do
      post :report, :id => User.find(:first)
    end
    assert_response :success
  end
end

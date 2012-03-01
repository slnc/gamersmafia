require 'test_helper'

class SlogControllerTest < ActionController::TestCase

  test "submenu shouldnt crash if 401 error" do
    assert_raises(AccessDenied) { get :index }
    exception = AccessDenied.new
    @request.remote_addr = '0.0.0.0'
    @controller.send :render_error, exception
    assert_response 401
    assert_template 'application/http_401'

    sym_login 1
    get :index
    assert_response :success
    assert_template 'slog/webmaster'
    assert_not_nil @response.body.index('Gladiador')
  end

  test "index_should_work" do
    assert_raises(AccessDenied) { get :index }
    sym_login 1
    get :index
    assert_response :success
  end

  test "bazar_manager" do
    sym_login 2
    assert_raises(AccessDenied) { get :bazar_manager }
    @u2 = User.find(2)
    @u2.give_admin_permission(:bazar_manager)
    get :bazar_manager
    assert_response :success
  end

  test "capo" do
    sym_login 2
    assert_raises(AccessDenied) { get :capo }
    @u2 = User.find(2)
    @u2.give_admin_permission(:capo)
    get :capo
    assert_response :success
  end

  test "gladiador" do
    sym_login 2
    assert_raises(AccessDenied) { get :gladiador }
    @u2 = User.find(2)
    @u2.give_admin_permission(:gladiador)
    get :gladiador
    assert_response :success
  end

  test "webmaster" do
    sym_login 2
    assert_raises(AccessDenied) { get :webmaster }
    sym_login 1
    get :webmaster
    assert_response :success
  end

  test "boss" do
    sym_login 2
    assert_raises(AccessDenied) { get :faction_bigboss }
    @u2 = User.find(2)
    @f = Faction.find(1)
    @f.update_boss(@u2)
    get :faction_bigboss
    assert_response :success
  end

  test "underboss" do
    sym_login 2
    assert_raises(AccessDenied) { get :faction_bigboss }
    @u2 = User.find(2)
    @f = Faction.find(1)
    @f.update_underboss(@u2)
    get :faction_bigboss
    assert_response :success
  end

  test "editor" do
    sym_login 2
    @u2 = User.find(2)
    @u2.take_admin_permission(:capo)
    @u2.users_roles.clear

    assert_raises(AccessDenied) { get :editor }

    @f = Faction.find(1)
    @f.add_editor(@u2, ContentType.find(1))
    get :editor
    assert_response :success
  end

  test "moderator" do
    sym_login 2
    assert_raises(AccessDenied) { get :moderator }
    @u2 = User.find(2)
    @u2 = User.find(2)
    @f = Faction.find(1)
    @f.add_moderator(@u2)
    get :moderator
    assert_response :success
    get :index
    assert_response :success
  end

  test "don" do
    sym_login 2
    assert_raises(AccessDenied) { get :bazar_district_bigboss }
    @u2 = User.find(2)
    @bd = BazarDistrict.find(1)
    @bd.update_don(@u2)
    get :bazar_district_bigboss
    assert_response :success
  end

  test "mano_derecha" do
    sym_login 2
    assert_raises(AccessDenied) { get :bazar_district_bigboss }
    @u2 = User.find(2)
    @bd = BazarDistrict.find(1)
    @bd.update_mano_derecha(@u2)
    get :bazar_district_bigboss
    assert_response :success
  end

  test "sicario" do
    sym_login 2
    assert_raises(AccessDenied) { get :sicario }
    @u2 = User.find(2)
    @bd = BazarDistrict.find(1)
    @bd.add_sicario(@u2)
    get :sicario
    assert_response :success
  end

  test "competition_admin" do
    sym_login 2
    assert_raises(AccessDenied) { get :competition_admin }
    @u2 = User.find(2)
    c = Competition.find(:first, :conditions => 'state = 3')
    c.add_admin(@u2)
    get :competition_admin
    assert_response :success
  end

  test "competition_supervisor" do
    sym_login 2
    assert_raises(AccessDenied) { get :competition_supervisor }
    @u2 = User.find(2)
    c = Competition.find(:first, :conditions => 'state = 3')
    c.add_supervisor(@u2)
    get :competition_supervisor
    assert_response :success
  end

  def atest_slog_entry_reviewed
    assert_raises(AccessDenied) { get :slog_entry_reviewed, :id => 1 }

    sym_login 5
    assert_raises(AccessDenied) { get :slog_entry_reviewed, :id => 1 }

    sym_login 1
    get :slog_entry_reviewed, :id => 1
    assert_response :success
  end

  test "sle_assigntome_all_combinations" do
    # TODO faltan tests
    @f = Faction.find(1)
    @bd = BazarDistrict.find(1)
    @editor_scope = 1 * SlogEntry::EDITOR_SCOPE_CONTENT_TYPE_ID_MASK + 1
    [
    [:test_sicario, :bazar_district_content_report, :@bd, :id],
    [:test_don, :bazar_district_content_report, :@bd, :id],
    [:test_bazar_manager, :bazar_district_content_report, :@bd, :id],

    [:test_moderator, :faction_comment_report, :@f, :id],
    [:test_boss, :faction_comment_report, :@f, :id],
    [:test_capo, :faction_comment_report, :@f, :id],


    [:test_editor, :faction_content_report, :@editor_scope, :to_i],
    [:test_boss, :faction_comment_report, :@f, :id],
    [:test_capo, :faction_content_report, :@editor_scope, :to_i],
    ].each do |t, type_id_sym, obj, meth|
      # puts "#{t} #{type_id_sym} #{obj} #{meth}"
      User.db_query("DELETE FROM users_roles")
      # UsersRole.find(:all).each do |ur| ur.destroy end
      User.db_query("UPDATE users SET is_superadmin = 'f', cache_is_faction_leader = 'f' AND admin_permissions = '0'")
      self.send t
      # @f.reload
      sle = SlogEntry.create(:type_id => SlogEntry::TYPES[type_id_sym], :headline => 'foo', :scope => instance_variable_get(obj).send(meth))
      get :slog_entry_assigntome, :id => sle.id
      assert_response :success

      get :slog_entry_reviewed, :id => sle.id
      assert_response :success
    end
  end
end

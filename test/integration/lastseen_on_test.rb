require 'test_helper'


class UsersLastseenOnTest < ActionController::IntegrationTest
  def setup
    host! App.domain
  end

  test "should_set_lastseen_on_user_hit" do
    User.db_query('UPDATE users SET lastseen_on = now() - \'1 hour\'::interval WHERE id = 1')
    before = Time.now.to_f.floor
    sym_login :superadmin, :lalala
    get '/site/x'
    after = Time.now.to_f.ceil
    u = User.find(1)
    assert_not_nil u
    assert before <= u.lastseen_on.to_i && u.lastseen_on.to_i <= after
  end
end

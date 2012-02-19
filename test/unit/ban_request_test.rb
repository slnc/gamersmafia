require 'test_helper'

class BanRequestTest < ActiveSupport::TestCase

  test "should_send_email_to_banned_user_after_confirmation" do
    u2 = User.find(2)
    assert_not_equal u2.state, User::ST_BANNED
    br = BanRequest.find(1)
    br.confirm(2)
    assert_email_with_text("Tu cuenta ha sido baneada permanentemente")
    u2.reload
    assert_equal User::ST_BANNED, u2.state
  end

  test "should_send_email_after_unban_process_initiated" do
    test_should_send_email_to_banned_user_after_confirmation
    u2 = User.find(2)
    assert_equal User::ST_BANNED, u2.state
    br = BanRequest.find(1)
    br.unban_user_id = 1
    br.reason_unban = "feo"
    assert_equal true, br.save
    #assert_count_increases(ActionMailer::Base.deliveries) do
    br.confirm_unban(2)
    u2.reload
    assert_not_equal User::ST_BANNED, u2.state
    #end
  end

  test "no_crear_dos_iguales" do
    br1 = BanRequest.new(:user_id => 1, :banned_user_id => 4, :reason => 'mas feo')
    assert br1.save
    br1 = BanRequest.new(:user_id => 2, :banned_user_id => 4, :reason => 'mas feo')
    assert !br1.save
  end
end

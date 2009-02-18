require File.dirname(__FILE__) + '/../test_helper'

class ProfileSignatureTest < Test::Unit::TestCase

  def test_should_send_email_notification_of_new_profile_signature
    prev = ActionMailer::Base.deliveries.size
    @p = User.find_by_login(:panzer)
    ps = ProfileSignature.new({:user => @p, :signer => User.find(1), :signature => 'foocaca'})
    assert_equal true, ps.save
    assert_equal prev + 1, ActionMailer::Base.deliveries.size
  end
end

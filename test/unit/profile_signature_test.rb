# -*- encoding : utf-8 -*-
require 'test_helper'

class ProfileSignatureTest < ActiveSupport::TestCase

  test "should_send_email_notification_of_new_profile_signature" do
    prev = ActionMailer::Base.deliveries.size
    @p = User.find_by_login(:panzer)
    ps = ProfileSignature.new({:user => @p, :signer => User.find(1), :signature => 'foocaca'})
    assert ps.save
    assert_equal prev + 1, ActionMailer::Base.deliveries.size
  end

  test "should_sanitize" do
    @p = User.find_by_login(:panzer)
    ps = ProfileSignature.new({:user => @p, :signer => User.find(1), :signature => "foocaca\n\n\na"})
    assert ps.save
    assert_equal  "foocaca\na", ps.signature
  end
end

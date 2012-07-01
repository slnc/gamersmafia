require 'test_helper'

class GmSysTest < ActiveSupport::TestCase
  test "should send warning if queue is too big" do
    User.expects(:db_query).returns([{"count" => GmSys::TOO_MANY_JOBS}])
    assert_difference("ActionMailer::Base.deliveries.size") do
      GmSys.warn_if_big_queue
    end
  end

  test "should not send warning if queue is not too big" do
    User.expects(:db_query).returns([{"count" => GmSys::TOO_MANY_JOBS - 1}])
    assert_difference("ActionMailer::Base.deliveries.size", 0) do
      GmSys.warn_if_big_queue
    end
  end
end

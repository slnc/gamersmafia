require 'test_helper'

class ChatlineTest < ActiveSupport::TestCase

  def setup
    @chatline = Chatline.find(1)
  end

  test "truth" do
    assert_kind_of Chatline,  @chatline
  end
end

require 'test_helper'

class ChatlineTest < ActiveSupport::TestCase

  def setup
    @chatline = Chatline.find(1)
  end

  # Replace this with your real tests.
  test "truth" do
    assert_kind_of Chatline,  @chatline
  end
end

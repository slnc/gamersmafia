require 'test_helper'
require File.dirname(__FILE__) + '/../test_script_helper'

class ScriptAlarikoBroadcastTest < ActiveSupport::TestCase
  test "sanity" do
    l = Chatline.count
    assert true
  end
end

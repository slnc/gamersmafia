require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_script_helper'

class ScriptAlarikoBroadcastTest < ActiveSupport::TestCase
  def test_sanity
    l = Chatline.count
    assert true
    # TODO
    # assert_script_exit_status 'alariko_broadcast.rb'
    # last = Chatline.find(:first, :order => 'id DESC')
    # assert last
    # assert_equal 'foobar', last.line
    # assert_equal User.find_by_login('MrAlariko').id, last.user_id
  end

  # TODO testear que hacen lo que debe hacer
end

require File.dirname(__FILE__) + '/../test_helper'

class AdvertiserTest < Test::Unit::TestCase

  # Replace this with your real tests.
  def test_del_roles
    adv = Advertiser.new(:name => 'foo adv', :due_on_day => 15, :email => 'money@me.com')
    assert adv.save
    ur = UsersRole.new(:role => 'Advertiser', :user_id => 1, :role_data => adv.id.to_s)
    assert ur.save
    adv.destroy
    assert_nil UsersRole.find_by_id(ur.id)
  end
end

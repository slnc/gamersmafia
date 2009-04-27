require 'test_helper'

class SlogEntryTest < ActiveSupport::TestCase

  # Replace this with your real tests.
  test "decode_editor_scope" do
    assert_equal [50, 1], SlogEntry.decode_editor_scope(50001) 
  end
  
  test "encode_editor_scope" do
    assert_equal 50001, SlogEntry.encode_editor_scope(50, 1)
  end
  
  test "can_create_entries_of_each_type" do
     
  end

  # TODO falta testear todas las scopes
  test "competition supervisor scope must inherit competition_admin scope" do
    u2 = User.find(2)
    c = Ladder.find(:first, :conditions => ['state > ?', Competition::STARTED])
    assert c
    u2.users_roles.create(:role => 'CompetitionAdmin', :role_data => "#{c.id}")
    assert_equal c.id, SlogEntry.scopes(:competition_admin, u2)[0].id
    assert_equal c.id, SlogEntry.scopes(:competition_supervisor, u2)[0].id
  end
end

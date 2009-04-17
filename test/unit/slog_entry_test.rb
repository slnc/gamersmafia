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
end

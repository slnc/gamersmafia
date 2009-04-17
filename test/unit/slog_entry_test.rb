require 'test_helper'

class SlogEntryTest < ActiveSupport::TestCase

  # Replace this with your real tests.
  def test_decode_editor_scope
    assert_equal [50, 1], SlogEntry.decode_editor_scope(50001) 
  end
  
  def test_encode_editor_scope
    assert_equal 50001, SlogEntry.encode_editor_scope(50, 1)
  end
  
  def test_can_create_entries_of_each_type
     
  end
end

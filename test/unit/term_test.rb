require File.dirname(__FILE__) + '/../test_helper'

class TermTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_scopes
    t = Term.new(:name => 'foo', :slug => 'bar')
    assert t.save
    
    t = Term.new(:name => 'foo', :slug => 'bar', :game_id => 1)
    assert t.save, t.errors.full_messages_html
    
    t = Term.new(:name => 'foo', :slug => 'bar', :platform_id => 1)
    assert t.save
    
    t = Term.new(:name => 'foo', :slug => 'bar', :bazar_district_id => 1)
    assert t.save
    
    tc = Term.new(:name => 'foo', :slug => 'bar', :clan_id => 1)
    assert tc.save
    
    t = Term.new(:name => 'foo', :slug => 'bar', :clan_id => 1, :parent_id => tc.id)
    assert t.save    
  end
end

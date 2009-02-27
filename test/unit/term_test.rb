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
  
  def test_mirror_category
    dc1 = DownloadsCategory.find(1)
    dcs1 = dc1.children.create(:name => 'subhijo1')
    dcss1 = dcs1.children.create(:name => 'subhijo11')
    dcsss1 = dcss1.children.create(:name => 'subhijo111')
    assert !dcsss1.new_record?
    t = Term.new(:name => 'foo', :slug => 'bar')
    assert t.save
    
    t.mirror_category_tree(dcsss1, 'DownloadsCategory')
 
    ndcs1 = t.children.find(:first, :conditions => 'name = \'subhijo1\' AND taxonomy = \'DownloadsCategory\'')
    assert ndcs1
    ndcss1 = ndcs1.children.find(:first, :conditions => 'name = \'subhijo11\' AND taxonomy = \'DownloadsCategory\'')
    assert ndcss1
    ndcsss1 = ndcss1.children.find(:first, :conditions => 'name = \'subhijo111\' AND taxonomy = \'DownloadsCategory\'')
    assert ndcsss1
  end
  
  def test_link
    t = Term.new(:name => 'foo', :slug => 'bar')
    assert t.save
    c = Content.find(:first)
    assert_count_increases(ContentsTerm) do
      t.link(c)
    end
    ct = ContentsTerm.find(:first, :order => 'id desc')
    assert_equal t.id, ct.term_id
    assert_equal c.id, ct.content_id
  end
end

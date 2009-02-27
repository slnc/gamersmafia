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
    @t = Term.new(:name => 'foo', :slug => 'bar')
    assert @t.save
    
    @t.mirror_category_tree(dcsss1, 'DownloadsCategory')
 
    ndcs1 = @t.children.find(:first, :conditions => 'name = \'subhijo1\' AND taxonomy = \'DownloadsCategory\'')
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
  
  def test_all_children_ids
    test_mirror_category
    expected = Term.find(:all, :conditions => ['root_id = ? ', @t.id]).collect { |t| t.id }.sort
    assert_equal expected, @t.all_children_ids
  end
  
  def test_all_children_ids_taxonomy
    test_mirror_category
    t2 = @t.children.create(:name => "oniris", :taxonomy => "fulanito")
    assert !t2.new_record?
    expected = Term.find(:all, :conditions => "root_id = #{@t.id} AND id <> #{t2.id}").collect { |t| t.id }.sort
    assert_equal expected, @t.all_children_ids(:taxonomy => 'DownloadsCategory')
  end
  
  def test_last_published_content
    test_mirror_category
    @lasttc = Term.find(:first, :order => 'id DESC')
    @content = Content.find(:first, :conditions => "state = #{Cms::PUBLISHED}", :order => 'id DESC')
    @lasttc.link(@content)
    assert_equal @content.id, @lasttc.last_published_content('Download').id
    assert_equal @content.id, @lasttc.root.last_published_content('Download').id
    assert_equal @content.id, @lasttc.parent.last_published_content('Download').id
  end
  
  def test_last_published_content_by_user_id
    test_last_published_content
    assert_equal @content.id, @lasttc.last_published_content('Download', :user_id => @content.user_id).id
    assert_nil @lasttc.last_published_content('Download', :user_id => (@content.user_id + 1))
  end
  
  def test_recalculate_count_works
    test_mirror_category
    @lasttc = Term.find(:first, :order => 'id DESC')
    @content = Content.find(:first, :conditions => "state = #{Cms::PUBLISHED}", :order => 'id DESC')
    @lasttc.link(@content)
    assert_equal 1, @lasttc.count
    @lasttc.update_attributes(:count => 0)
    @lasttc.recalculate_count
    assert_equal 1, @lasttc.count
  end
end

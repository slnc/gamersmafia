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
  
  
  def test_find_by_id
    n = News.find(1)
    t = n.terms[0]
    res = t.news.find(1)
    assert_equal 'News', res.class.name
    assert_equal 1, res.id
  end

  def test_mirror_category
    dc1 = DownloadsCategory.find(1)
    dcs1 = dc1.children.create(:name => 'subhijo1')
    @dcss1 = dcs1.children.create(:name => 'subhijo11')
    dcsss1 = @dcss1.children.create(:name => 'subhijo111')
    assert !dcsss1.new_record?
    @t = Term.new(:name => 'foo', :slug => 'bar')
    assert @t.save
    
    @t.mirror_category_tree(dcsss1, 'DownloadsCategory')
    
    @ndcs1 = @t.children.find(:first, :conditions => 'name = \'subhijo1\' AND taxonomy = \'DownloadsCategory\'')
    assert @ndcs1
    @ndcss1 = @ndcs1.children.find(:first, :conditions => 'name = \'subhijo11\' AND taxonomy = \'DownloadsCategory\'')
    assert @ndcss1
    @ndcsss1 = @ndcss1.children.find(:first, :conditions => 'name = \'subhijo111\' AND taxonomy = \'DownloadsCategory\'')
    assert @ndcsss1
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
    assert_equal expected, @t.all_children_ids.sort
    
    expected2 = Term.find(:all, :conditions => ['parent_id = ? ', @ndcss1.id]).collect { |t| t.id }.sort
    assert_equal (expected2 + [@ndcss1.id]).sort, @ndcss1.all_children_ids
  end
  
  def test_all_children_ids_taxonomy
    test_mirror_category
    t2 = @t.children.create(:name => "oniris", :taxonomy => "fulanito")
    assert !t2.new_record?
    expected = Term.find(:all, :conditions => "root_id = #{@t.id} AND id <> #{t2.id}").collect { |t| t.id }.sort
    assert_equal expected, @t.all_children_ids(:taxonomy => 'DownloadsCategory').sort
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
  
  def test_recalculate_contents_count_works
    test_mirror_category
    @lasttc = Term.find(:first, :order => 'id DESC')
    @content = Content.find(:first, :conditions => "state = #{Cms::PUBLISHED}", :order => 'id DESC')
    @lasttc.link(@content)
    assert_equal 1, @lasttc.contents_count
    @lasttc.update_attributes(:contents_count => 0)
    @lasttc.recalculate_contents_count
    assert_equal 1, @lasttc.contents_count
  end
  
  def test_should_automatically_create_slug
    @n1 = Term.create({:name => 'Hola Mundo!!'})
    assert_not_nil @n1
    assert_equal 'hola-mundo', @n1.slug
  end
  
  def test_should_creating_a_root_category_should_properly_initialize_attributes
    @n1 = Term.create({:name => 'cacttest1'})
    assert_not_nil @n1
    assert_equal @n1.id, @n1.root_id
    assert_nil @n1.parent_id
  end
  
  def test_find_contents_should_work
    root_term = Term.single_toplevel(:slug => 'ut')
    nlist = root_term.find(:all, :content_type => 'News')
    assert nlist.size > 0
    assert_equal 'News', nlist[0].class.name
    assert_equal root_term.id, nlist[0].terms[0].id
  end
  
  def test_find_contents_through_shortcut_should_work
    root_term = Term.single_toplevel(:slug => 'ut')
    nlist = root_term.news.find(:all)
    assert nlist.size > 0
    assert_equal 'News', nlist[0].class.name
    assert_equal root_term.id, nlist[0].terms[0].id
  end
  
  def test_should_properly_create_children
    test_should_creating_a_root_category_should_properly_initialize_attributes
    @n1child = @n1.children.create({:name => 'first_child'})
    assert_not_nil @n1child
    assert_equal @n1.id, @n1child.root_id
  end
  
  def test_should_properly_update_root_id_when_moving_a_category_from_one_root_to_another
    test_should_properly_create_children
    @n2 = Term.create({:name => 'cacttest2'})
    assert_not_nil @n2
    @n1child.parent_id = @n2.id
    @n1child.save
    assert_equal @n2.id, @n1child.root_id
  end
  
  def test_should_properly_update_root_id_when_moving_a_category_from_one_root_to_another_and_it_has_subcategories
    test_should_properly_create_children
    @n2 = Term.create({:name => 'cacttest2'})
    assert_not_nil @n2
    @n1.parent_id = @n2.id
    @n1.save
    assert_equal @n2.id, @n1.root_id
    @n1child.reload
    assert_equal @n2.id, @n1child.root_id
  end
  
  def test_should_properly_return_related_portals_if_not_matching_a_factions_code
    nc = Term.new({:name => 'catnonfaction'})
    assert_equal true, nc.save
    assert_equal (FactionsPortal.count + BazarDistrictPortal.count + 1), nc.get_related_portals.size
    assert_equal 'GmPortal', nc.get_related_portals[0].class.name
  end
  
  def test_should_properly_return_related_portals_if_not_matching_a_factions_code_and_child
    nc = Term.new({:name => 'catnonfaction'})
    assert nc.save
    ncchild = nc.children.create({:name => 'subcat'})
    assert_equal true, ncchild.save
    assert_equal (FactionsPortal.count + BazarDistrictPortal.count + 1), ncchild.get_related_portals.size
    assert_equal 'GmPortal', ncchild.get_related_portals[0].class.name
  end
  
  def test_should_properly_return_related_portals_if_matching_a_factions_code
    nc = Term.single_toplevel(:slug => 'ut')
    assert_not_nil nc 
    assert_equal 3, nc.get_related_portals.size, nc.get_related_portals
  end
  
  def test_all_children_ids_should_properly_return_if_root_id_given
    @nc = Term.create({:name => 'catnonfaction'})
    @ncchild = @nc.children.create({:name => 'subcat'})
    @cats = @nc.all_children_ids
    assert_equal 2, @cats.size
    @cats.each { |catid| assert_equal true, catid.kind_of?(Fixnum)}
    assert_equal true, @cats.include?(@nc.id)
    assert_equal true, @cats.include?(@ncchild.id)
  end
  
  # TODO
  def atest_all_children_ids_should_return_the_same_if_same_cat_asked_in_different_ways
    test_all_children_ids_should_properly_return_if_root_id_given
    cats2 = @nc.all_children_ids(@nc)
    assert_equal true, @cats == cats2
  end
  
  # TODO
  def atest_all_children_ids_should_properly_work_if_asking_for_non_root_id_cat
    @nc = Term.create({:name => 'catnonfaction'})
    @ncchild = @nc.children.create({:name => 'subcat'})
    @ncsubchild = @ncchild.children.create({:name => 'subsubcat'})
    @cats = @ncchild.all_children_ids
    assert_equal 2, @cats.size
    assert_equal true, @cats.include?(@ncchild.id)
    assert_equal true, @cats.include?(@ncsubchild.id)
  end
  
  def test_reset_contents_urls
    topic = Topic.find(1)
    User.db_query("UPDATE contents SET url = 'fuuck yu' WHERE id = #{topic.unique_content_id}")
    topic.reload
    topic.main_category.reset_contents_urls
    topic.reload
    assert_equal 'http://ut.gamersmafia.dev/foros/topic/1', topic.unique_content.url 
  end
  
  def test_get_last_updated_item_id
    t = Term.single_toplevel(:slug => 'ut')
    it = t.get_last_updated_item
    
    assert_equal 1, it.id
    Cms::modify_content_state(it, User.find(1), Cms::DELETED)
    t.reload
    it.reload
    assert_equal Cms::DELETED, it.state
    assert_equal Cms::DELETED, it.unique_content.state
    
    newit = t.get_last_updated_item
    
    assert it != newit
  end
  
  def test_get_ancestors
    
  end
  
  def test_should_update_parent_categories_counter
    @cat1 = Term.new(:name => 'pelopincho')
    assert @cat1.save
    @subcat1 = @cat1.children.create(:name => 'catsubfather', :taxonomy => 'TopicsCategory')
    assert @subcat1.save
    @topic = Topic.new(:user_id => 1, :title => 'topic 1', :main => 'topic1')
    assert @topic.save, @topic.errors
    assert_equal Cms::PUBLISHED, @topic.state
    assert_equal Cms::PUBLISHED, @topic.unique_content.state
    @subcat1.link(@topic.unique_content)
    rtoutside = Term.find(17)
    rtoutside.link(@topic.unique_content)
    @cat1.reload
    @subcat1.reload
    assert_equal 1, @subcat1.contents_count(:cls_name => 'Topic')
    assert_equal 1, @cat1.contents_count(:cls_name => 'Topic')
  end
  
  def test_should_update_parent_categories_counter_after_marking_as_deleted_topic
    test_should_update_parent_categories_counter  
    Cms::modify_content_state(@topic, User.find(1), Cms::DELETED)
    @topic.reload
    assert_equal Cms::DELETED, @topic.state
    @cat1.reload
    @subcat1.reload
    assert_equal 0, @subcat1.contents_count(:cls_name => 'Topic', :conditions => "contents.state = #{Cms::PUBLISHED}")
    assert_equal 0, @cat1.contents_count(:cls_name => 'Topic', :conditions => "contents.state = #{Cms::PUBLISHED}")
  end
  

  def test_should_update_parent_categories_counter_after_moving_to_new_category
    test_should_update_parent_categories_counter
    
    @cat2 = Term.new(:name => 'eunuco')
    assert @cat2.save
    @subcat2 = @cat2.children.create(:name => 'catsubfather', :taxonomy => 'TopicsCategory')
    assert @subcat2.save
    
    @subcat1.unlink(@topic.unique_content)
    @subcat2.link(@topic.unique_content)
    
    @cat1.reload
    @subcat1.reload
    @cat2.reload
    @subcat2.reload
    assert_equal 0, @cat1.contents_count(:cls_name => 'Topic')
    assert_equal 0, @subcat1.contents_count(:cls_name => 'Topic')
    assert_equal 1, @cat2.contents_count(:cls_name => 'Topic')
    assert_equal 1, @subcat2.contents_count(:cls_name => 'Topic')
  end
  
  def test_last_updated_children_should_work
    test_should_update_parent_categories_counter
    @subcat1.link(@topic.unique_content)
    catz = @cat1.last_updated_children(:limit => 5)
    assert catz.collect { |luc| luc.name }.include?(@subcat1.name)
  end

  def test_should_update_categories_comments_count_after_commenting
    test_should_update_parent_categories_counter
    @comment = Comment.new({:content_id => @topic.unique_content.id, 
      :user_id => 1, 
      :host => '0.0.0.0', 
      :comment => 'holitas vecinito'})
    assert @comment.save
    @topic.reload
    assert_equal 1, @topic.cache_comments_count
    assert_equal 1, @topic.unique_content.comments_count
    @cat1.reload
    @subcat1.reload
    assert_equal 1, @subcat1.comments_count
    assert_equal 1, @cat1.comments_count
  end
  
  def test_should_update_categories_comments_count_after_deleting_commenting
    test_should_update_categories_comments_count_after_commenting
    init_ccount = @subcat1.comments_count
    
    @comment.mark_as_deleted
    @topic.reload
    assert_equal 0, @topic.cache_comments_count
    @cat1.reload
    @subcat1.reload
    
    assert_equal 0, @cat1.comments_count
    assert_equal 0, @subcat1.comments_count, @subcat1.comments_count
  end
end
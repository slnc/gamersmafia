require File.dirname(__FILE__) + '/../../../test/test_helper'
require 'RMagick'

class ActsAsContentTest < ActiveSupport::TestCase
  
  def test_no_null_title_in_content
    n = News.new({:title => '', :terms => 1, :user_id => 1, :description => 'foojahaha'})
    assert !n.save
  end
  
  def test_should_link_if_terms_given_as_param
    @n = News.create({:title => 'foo title ibernews', :terms => 1, :user_id => 1, :description => 'foojahaha', :terms => 1})
    assert_not_nil @n
    assert_not_nil @n.log
    assert_equal 1, @n.terms.size
    assert_equal 1, @n.terms[0].id
  end
  
  def test_should_delete_old_terms_if_new_terms_doesnt_include_them
    test_should_link_if_terms_given_as_param
    @n.root_terms_ids = 2
    assert_equal 1, @n.terms.size
    assert_equal 2, @n.terms[0].id
  end
  
  def test_should_allow_array_formats_of_terms
    test_should_link_if_terms_given_as_param
    @n.root_terms_ids = [2]
    assert_equal 1, @n.terms.size
    assert_equal 2, @n.terms[0].id
  end
  
  def test_should_allow_to_add_without_deleting
    test_should_link_if_terms_given_as_param
    @n.root_terms_add_ids([2])
    assert_equal 2, @n.terms.size
    assert_equal 1, @n.terms[0].id
    assert_equal 2, @n.terms[1].id
  end
  
  def test_should_not_allow_to_link_to_child_term_if_content_is_categorizable_and_root_term_given
    @tut = Tutorial.new(:user_id => 1, :title => 'footapang', :description => 'bartapang', :main => 'aaa', :terms => 1)
    assert @tut.save, @tut.errors.full_messages_html
    @tut.reload
    assert @tut.terms.size == 0
  end
  
  def test_should_allow_two_root_terms_if_not_categorizable
    test_should_link_if_terms_given_as_param
    @n.root_terms_ids = [1, 2]
    assert_equal 2, @n.terms.size
    assert_equal 1, @n.terms[0].id
    assert_equal 2, @n.terms[1].id
  end
  
  def test_should_allow_two_categories_terms_if_categorizable
    test_should_not_allow_to_link_to_child_term_if_content_is_categorizable_and_root_term_given
    @tut.categories_terms_ids = [[19, 28], 'TutorialsCategory']
    p @tut.terms
    assert_equal 2, @tut.terms.size
    assert_equal 19, @tut.terms[0].id
    assert_equal 28, @tut.terms[1].id
  end
  
  def test_should_add_log_entry_on_creation
    n = News.create({:title => 'foo title ibernews', :terms => 1, :user_id => 1, :description => 'foojahaha'})
    assert_not_nil n
    assert_not_nil n.log
    last_entry = n.log.pop
    assert last_entry[0] = 'creado'
    assert last_entry[1] = 'superadmin'
    assert last_entry[2] > 5.seconds.ago
  end
  
  def test_should_add_log_entry_on_modification
    test_should_add_log_entry_on_creation
    n = News.find(:first, :order => 'id DESC')
    assert_not_nil n.update_attributes({:cur_editor => 1})
    assert_not_nil n.log
    last_entry = n.log.pop
    assert last_entry[0] = 'modificado'
    assert last_entry[1] = 'superadmin'
    assert last_entry[2] > 5.seconds.ago
  end
  
  def test_should_add_log_entry_on_publication
    test_should_add_log_entry_on_creation
    n = News.find(:first, :order => 'id DESC')
    n.change_state(Cms::PUBLISHED, User.find(1))
    assert_not_nil n.log
    last_entry = n.log.pop
    assert last_entry[0] = 'publicado'
    assert last_entry[1] = 'superadmin'
    assert last_entry[2] > 5.seconds.ago
  end
  
  def test_should_add_log_entry_on_unpublish_a_published_item
    test_should_add_log_entry_on_publication
    n = News.find(:first, :order => 'id DESC')
    n.change_state(Cms::DELETED, User.find(1))
    assert_not_nil n.log
    last_entry = n.log.pop
    assert last_entry[0] = 'despublicado'
    assert last_entry[1] = 'superadmin'
    assert last_entry[2] > 5.seconds.ago
  end
  
  def test_should_add_log_entry_on_sent_to_trash
    test_should_add_log_entry_on_creation
    n = News.find(:first, :order => 'id DESC')
    n.change_state(Cms::DELETED, User.find(1))
    assert_not_nil n.log
    last_entry = n.log.pop
    assert last_entry[0] = 'eliminado'
    assert last_entry[1] = 'superadmin'
    assert last_entry[2] > 5.seconds.ago
  end
  
  def test_should_add_log_entry_on_change_authorship
    test_should_add_log_entry_on_creation
    n = News.find(:first, :order => 'id DESC')
    n.change_authorship(User.find(2), User.find(1))
    assert_not_nil n.log
    last_entry = n.log.pop
    assert last_entry[0] = 'cambiada autoría'
    assert last_entry[1] = 'superadmin'
    assert last_entry[2] > 5.seconds.ago
  end
  
  def test_should_add_log_entry_on_recover
    test_should_add_log_entry_on_creation
    n = News.find(:first, :order => 'id DESC')
    n.recover(User.find(1))
    assert_not_nil n.log
    last_entry = n.log.pop
    assert last_entry[0] = 'recuperado'
    assert last_entry[1] = 'superadmin'
    assert last_entry[2] > 5.seconds.ago
  end
  
  def test_shouldnt_touch_karma_when_changing_state_from_pending_to_deleted
    @u = User.find(1)
    @n = News.create({:terms => 1, :title => 'mi titulito', :description => 'mi sumarito', :user_id => @u.id, :state => Cms::PENDING})
    assert_not_nil @n
    k = @u.karma_points
    Cms::deny_content(@n, @u, 'ffff')
    @u.reload
    assert_equal k, @u.karma_points
  end
  
  def test_shouldnt_touch_karma_when_changing_state_from_draft_to_deleted
    @u = User.find(1)
    @n = News.create({:terms => 1, :title => 'mi titulito', :description => 'mi sumarito', :user_id => @u.id, :state => Cms::DRAFT})
    assert_not_nil @n
    k = @u.karma_points
    Cms::deny_content(@n, @u, 'ffff')
    @u.reload
    assert_equal k, @u.karma_points
  end
  
  def test_shouldnt_send_msg_when_changing_state_from_draft_to_deleted
    m = Message.count    
    test_shouldnt_touch_karma_when_changing_state_from_draft_to_deleted
    assert_equal m, Message.count
  end
  
  def test_should_give_karma_when_changing_state_from_draft_to_published
    @u = User.find(1)
    @n = News.create({:terms => 1, :title => 'mi titulito', :description => 'mi sumarito', :user_id => @u.id, :state => Cms::DRAFT})
    assert_not_nil @n
    k = @u.karma_points
    Cms::publish_content(@n, @u)
    @u.reload
    assert_equal k + Karma::KPS_CREATE['News'], @u.karma_points
  end
  
  def test_should_give_karma_when_changing_state_from_pending_to_published
    @u = User.find(1)
    @n = News.create({:terms => 1, :title => 'mi titulito', :description => 'mi sumarito', :user_id => @u.id, :state => Cms::PENDING})
    assert_not_nil @n
    k = @u.karma_points
    Cms::publish_content(@n, @u)
    @u.reload
    assert_equal k + Karma::KPS_CREATE['News'], @u.karma_points
  end
  
  def test_should_take_karma_when_changing_state_from_published_to_deleted
    test_should_give_karma_when_changing_state_from_pending_to_published
    k = @u.karma_points
    Cms::modify_content_state(@n, @u, Cms::DELETED)
    @u.reload
    assert_equal k - Karma::KPS_CREATE['News'], @u.karma_points
  end
  
  def test_should_add_to_tracker_of_creator
    # TODO y si cambiamos la autoría qué pasa con el tracker?
    @u = User.find(1)
    @n = News.create({:terms => 1, :title => 'mi titulito', :description => 'mi sumarito', :user_id => @u.id, :state => Cms::PENDING})
    assert_not_nil @n
    assert_equal true, @u.tracker_has?(@n.unique_content.id)
  end
  
  def test_shouldnt_appear_as_updated_in_tracker_after_publishing
    test_should_add_to_tracker_of_creator
    ti = TrackerItem.find(:first, :order => 'id DESC')
    assert_not_nil ti
    assert_equal Cms::PENDING, @n.state
    assert_equal @n.unique_content.id, ti.content_id
    @n.created_on = 1.day.since
    assert_equal true, @n.save
    User.db_query("UPDATE tracker_items SET lastseen_on = now() - '23 hours'::interval WHERE content_id = #{@n.unique_content.id}")
    ti.reload
    assert_equal true, ti.lastseen_on < 1.hour.ago
    Cms::publish_content(@n, @u)
    ti.reload
    assert_equal true, ti.lastseen_on > 1.hour.ago
  end
  
  def test_unique_attributes_should_work
    o1 = News.find(1)
    uattrs = [:title, :description, :main, :clan_id]
    uattrs_received = o1.unique_attributes
    assert_equal uattrs.size, uattrs_received.size
    uattrs.each do |uattr|
      assert_equal o1[uattr], uattrs_received[uattr]
    end
  end
  
  def test_related_portals_of_district_proper_district
    n = News.new(:title => 'Noticia 1', :description => 'sumario', :user_id => 1)
    assert n.save
    Term.single_toplevel(:slug => 'anime').link(n.unique_content)
    relportals = n.get_related_portals
    assert_equal 4, relportals.size
    assert_equal 'anime', relportals[3].code
  end
end

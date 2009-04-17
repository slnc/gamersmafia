require 'test_helper'

class ContentTest < ActiveSupport::TestCase
  
  def setup
    @content = Content.find(1)
  end
  
  def test_locked_for_user_when_unlocked
    c = Content.find(1)
    assert !c.locked_for_user?(User.find(1))
  end
  
  def test_locked_for_user_when_locked
    assert_not_nil ContentsLock.create({:content_id => 1, :user_id => 1})
    c = Content.find(1)
    assert c.locked_for_user?(User.find(2))
  end
  
  def test_locked_for_user_when_lock_expired
    lock = ContentsLock.create({:content_id => 1, :user_id => 1})
    assert_not_nil lock
    ContentsLock.db_query("UPDATE contents_locks set updated_on = now() - '1 minute'::interval WHERE id = #{lock.id}")
    c = Content.find(1)
    assert !c.locked_for_user?(User.find(2))
  end
  
  
  def test_del_recommendations_after_delete_content
    c = Content.find(:first, :conditions => "state = #{Cms::PUBLISHED}")
    cr = ContentsRecommendation.create(:sender_user_id => 1, :content_id => c.id, :receiver_user_id => 3)
    assert !cr.new_record?
    assert c.update_attributes(:state => Cms::DELETED)
    assert ContentsRecommendation.find_by_id(cr.id).nil?
  end
  
  def test_linked_terms
    c = Content.find(1)
    assert_equal 'News', c.content_type.name
    lterms = c.linked_terms
    assert_equal 1, lterms.size
    assert_nil lterms[0].taxonomy
    assert_equal 1, lterms[0].id
  end
  
  def test_linked_terms_taxonomy
    c = Content.find(5)
    lterms = c.linked_terms('DownloadsCategory')
    assert_equal 1, lterms.size
    assert_equal 16, lterms[0].id
  end
  
  def test_linked_terms_null
    c = Content.find(1)
    lterms = c.linked_terms('NULL')
    assert_equal 1, lterms.size
    assert_equal 1, lterms[0].id
  end
end

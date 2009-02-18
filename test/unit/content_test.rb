require File.dirname(__FILE__) + '/../test_helper'

class ContentTest < Test::Unit::TestCase

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
end

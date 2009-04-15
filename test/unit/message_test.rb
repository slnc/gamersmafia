require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < ActiveSupport::TestCase
  
  def setup
    @message = Message.find(1)
  end
  
  def test_should_properly_set_the_has_replies_of_replied_message
    @m1 = Message.find(1)
    assert_not_nil @m1
    @m = Message.create({:user_id_to => @m1.sender.id, :user_id_from => @m1.recipient.id, :title => 'foo message to you', :message => 'mwahahaha', :in_reply_to => @m1.id})
    assert_not_nil @m
    @m1.reload
    assert_equal true, @m1.has_replies
  end
  
  def test_message_preview_should_show_lines_of_answers_and_not_quoted
    m = Message.new({:message => "foo\nbar\n> baz"})
    assert_equal "foo bar", m.preview
  end
  
  def test_should_properly_set_thread_id_if_in_reply_to_is_not_null
    test_should_properly_set_the_has_replies_of_replied_message
    assert_equal @m1.id, @m.thread_id
  end
  
  def test_should_properly_set_thread_id_if_in_reply_to_is_null
    @m = Message.create({:user_id_to =>1, :user_id_from => 2, :title => 'foo message to you', :message => 'mwahahaha'})
    assert_not_nil @m.id
    assert_equal @m.id, @m.thread_id
  end
  
  def test_should_properly_update_unread_after_creating_message
    u1 = User.find(1)
    u1_init = u1.unread_messages
    test_should_properly_set_thread_id_if_in_reply_to_is_null
    u1.reload
    assert_equal u1_init + 1, u1.unread_messages
  end
  
  def test_should_properly_update_unread_after_reading_message
    test_should_properly_set_thread_id_if_in_reply_to_is_null
    u1 = User.find(1)
    u1_init = u1.unread_messages
    assert !@m.is_read
    @m.is_read = true
    assert @m.save
    u1.reload
    assert_equal u1_init - 1, u1.unread_messages
  end
  
  def test_should_properly_update_unread_after_deleting_unread_message_from_receiver
    test_should_properly_set_thread_id_if_in_reply_to_is_null
    u1 = User.find(1)
    u1_init = u1.unread_messages
    assert !@m.receiver_deleted
    @m.receiver_deleted = true
    assert @m.save
    u1.reload
    assert_equal u1_init - 1, u1.unread_messages
  end
end

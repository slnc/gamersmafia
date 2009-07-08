require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  
  def setup
    @message = Message.find(1)
  end

  test "should properly escape javascript" do
    bad_txt = '</strong><img src="http://tbn3.google.com/images?q=tbn:tijzzbMzPpPJRM:http://galerie.antonindanek.cz/obrazky/owned.gif"><script>alert(\'jefe dentro tambien puedo hacer que salte,la vez anterior lo hice fuera,esta vez debería saltar dentro y fuera.\')</script>'

    @m = Message.create({:user_id_to => 1, :user_id_from => 2, :title => bad_txt, :message => bad_txt})
    assert @m.title.index('<').nil?
    assert @m.message.index('<').nil?
  end
  
  test "should_properly_set_the_has_replies_of_replied_message" do
    @m1 = Message.find(1)
    assert_not_nil @m1
    @m = Message.create({:user_id_to => @m1.sender.id, :user_id_from => @m1.recipient.id, :title => 'foo message to you', :message => 'mwahahaha', :in_reply_to => @m1.id})
    assert_not_nil @m
    @m1.reload
    assert_equal true, @m1.has_replies
  end
  
  test "message_preview_should_show_lines_of_answers_and_not_quoted" do
    m = Message.new({:message => "foo\nbar\n> baz"})
    assert_equal "foo bar", m.preview
  end
  
  test "should_properly_set_thread_id_if_in_reply_to_is_not_null" do
    test_should_properly_set_the_has_replies_of_replied_message
    assert_equal @m1.id, @m.thread_id
  end
  
  test "should_properly_set_thread_id_if_in_reply_to_is_null" do
    @m = Message.create({:user_id_to =>1, :user_id_from => 2, :title => 'foo message to you', :message => 'mwahahaha'})
    assert_not_nil @m.id
    assert_equal @m.id, @m.thread_id
  end
  
  test "should_properly_update_unread_after_creating_message" do
    u1 = User.find(1)
    u1_init = u1.unread_messages
    test_should_properly_set_thread_id_if_in_reply_to_is_null
    u1.reload
    assert_equal u1_init + 1, u1.unread_messages
  end
  
  test "should_properly_update_unread_after_reading_message" do
    test_should_properly_set_thread_id_if_in_reply_to_is_null
    u1 = User.find(1)
    u1_init = u1.unread_messages
    assert !@m.is_read
    @m.is_read = true
    assert @m.save
    u1.reload
    assert_equal u1_init - 1, u1.unread_messages
  end
  
  test "should_properly_update_unread_after_deleting_unread_message_from_receiver" do
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

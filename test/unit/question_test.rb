require 'test_helper'

class QuestionTest < ActiveSupport::TestCase

  def setup
    Bank::transfer(:bank, User.find(2), 100, 'test')
  end

  test "should_be_able_to_create_question_with_min_ammount" do
    @bt = Question.create({
        :user_id => 2,
        :title => "should_be_able_to_create_question_with_min_ammount",
        :ammount => Question::MIN_AMMOUNT,
    })
    Term.find(20).link(@bt.unique_content)
    assert !@bt.new_record?
    assert_equal Question::MIN_AMMOUNT.to_i, @bt.ammount.to_i
  end

  test "should_return_money_to_owner_if_no_best_answer" do
    @q = Question.find(1)
    @q.ammount = Question::MIN_AMMOUNT
    assert @q.save, @q.errors.full_messages_html
    @u_cash = @q.user.cash
    assert_count_increases(Message) do
      assert @q.set_no_best_answer(User.find(1))
    end
    assert @q.reload
    assert_equal sprintf("%.2f", @q.user.cash), sprintf("%.2f", (@u_cash + Question::MIN_AMMOUNT))
  end

  test "set_set_best_answer" do
    @q = Question.find(1)
    @c = @q.unique_content.comments.find(:first, :conditions => 'deleted = \'f\'')
    baid = @c.id
    @u_cash = @c.user.cash
    assert_nil @q.best_answer
    assert !@q.set_best_answer(1, @q.user)
    assert @q.set_best_answer(baid, @q.user)
    assert_equal baid, @q.accepted_answer_comment_id
    assert_not_nil @q.best_answer
    assert_not_nil @q.answered_on
    assert_equal @q.user.id, @q.answer_selected_by_user_id
    assert_equal @q.user.id, @q.answer_selected_by_user.id
    @c.user.reload
    assert_equal ("%.2f" % (@u_cash + @q.prize)), ("%.2f" % @c.user.cash)
  end

  test "should_send_message_when_best_answer_is_selected" do
    assert_count_increases(Message) do
      test_set_set_best_answer
    end
    assert_equal @c.id, Message.find(:first, :order => 'id DESC').user_id_to
  end

  test "should_be_able_to_revert" do
    test_set_set_best_answer
    init_cash = @c.user.cash
    assert @q.revert_set_best_answer(User.find(1))
    assert_nil @q.best_answer
    assert_nil @q.answered_on
    assert_nil @q.answer_selected_by_user_id
    @c.user.reload
    assert_equal ("%.2f" % (init_cash - @q.prize)), ("%.2f" % @c.user.cash)
  end

  test "should_be_able_to_create_question_with_0_ammount" do
    @bt = Question.create({:user_id => 2, :title => "fooafoasofd osadka", :ammount => 0, :terms => 1})
    assert_equal false, @bt.new_record?, @bt.errors.full_messages_html
  end

  test "shouldnt_be_able_to_create_question_with_less_than_min_ammount" do
    @bt = Question.create({:user_id => 2, :title => "fooafoasofd osadka", :ammount => Question::MIN_AMMOUNT - 1, :terms => 1})
    assert_equal true, @bt.new_record?
  end

  test "should_be_able_to_increase_ammount_of_question_if_prev_was_0_and_new_ammount_min_or_more" do
    test_should_be_able_to_create_question_with_0_ammount
    assert_equal true, @bt.update_ammount(Question::MIN_AMMOUNT), @bt.errors.full_messages_html
  end

  test "shouldnt_be_able_to_increase_ammount_of_question_if_prev_was_0_and_new_ammount_less_than_min" do
    test_should_be_able_to_create_question_with_0_ammount
    assert_raises(TooLateToLower) { @bt.update_ammount(Question::MIN_AMMOUNT - 1) }
  end

  test "should_be_able_to_increase_ammount_of_question_if_prev_was_min" do
    test_should_be_able_to_create_question_with_min_ammount
    assert_equal true, @bt.update_ammount(@bt.ammount + 1.0)
  end

  test "shouldnt_be_able_to_decrease_ammount" do
    test_should_be_able_to_create_question_with_min_ammount
    assert_raises(TooLateToLower) { @bt.update_ammount(@bt.ammount - 1.0) }
  end

  test "shouldnt_be_able_to_create_if_too_many_open_questions" do
    u1 = User.find(3)

    Question.max_open(u1).times do |t|
      assert_count_increases(Question) do
        @bt = Question.create({:user_id => u1.id, :title => "fooafoasofd osadka#{t}", :ammount => 0, :terms => 1})
      end
    end
    @bt = Question.new({:user_id => u1.id, :title => "fooafoasofd osadka#{Question.max_open(u1) + 1}", :ammount => 0, :terms => 1})
    assert !@bt.save
  end

  test "should_get_back_the_money_if_changed_from_published" do
    test_should_be_able_to_create_question_with_min_ammount
    # @u2.reload
    Cms::deny_content(@bt, User.find(1), "fuck you")
    assert_equal Cms::DELETED, @bt.state
    assert_equal 0.0, @bt.ammount
  end

  test "should_get_back_the_money_if_deleted" do
    @u2 = User.find(2)
    initial_cash = @u2.cash
    test_should_get_back_the_money_if_changed_from_published
    @u2.reload
    assert_equal @u2.cash, initial_cash

  end
end

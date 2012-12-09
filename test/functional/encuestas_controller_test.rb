# -*- encoding : utf-8 -*-
require 'test_helper'
require 'test_functional_content_helper'

class EncuestasControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Poll', :form_vars => {:title => 'footapang', :starts_on => 2.days.since, :ends_on => 9.days.since}, :root_terms => 1

  test "should_create_with_options" do
    post :create, {:poll => {:title => 'footapang', :starts_on => 2.days.since, :ends_on => 9.days.since, :options_new => ['opcion1', 'opcion2']}, :root_terms => [1] }, { :user => 1}
    assert_response :redirect
    b = Poll.find_by_title('footapang')
    assert_not_nil b
    assert_equal 2, b.polls_options.count
    assert_not_nil b.polls_options.find_by_name('opcion1')
    assert_not_nil b.polls_options.find_by_name('opcion2')
  end

  test "should work on bazar" do
    @request.host = App.domain_bazar
    get :index
    assert_response :success
  end

  test "should_publish_as_is" do
    test_should_create_with_options
    b = Poll.find_by_title('footapang')
    post :update, {:id => b.id }
    b.reload
    assert_equal 2, b.polls_options.count
    assert_not_nil b.polls_options.find_by_name('opcion1')
    assert_not_nil b.polls_options.find_by_name('opcion2')
  end

  test "should_allow_to_change_options_if_not_published" do
    test_should_create_with_options
    b = Poll.find_by_title('footapang')

    post :update, {:id => b.id,
                  :poll => {:options => { b.polls_options.find_by_name('opcion1').id => 'opcion1_mod',
                                              b.polls_options.find_by_name('opcion2').id => 'opcion2_mod'}, # lo hacemos a propósito porque primero se borra y luego se actualiza, para comprobar que no se intenta actualizar una opción borrada
                           :options_delete => [b.polls_options.find_by_name('opcion2').id],
                           :options_new => ['opcion3', 'opcion4']},
                  }
    b.reload

    assert_equal 3, b.polls_options.count
    assert_nil b.polls_options.find_by_name('opcion1')
    assert_not_nil b.polls_options.find_by_name('opcion1_mod')
    assert_nil b.polls_options.find_by_name('opcion2')
    assert_not_nil b.polls_options.find_by_name('opcion3')
    assert_not_nil b.polls_options.find_by_name('opcion4')
  end

  test "vote" do
    poll = Poll.published.find(:all)[0]
    assert poll.update_attributes(:starts_on => 1.day.ago, :ends_on => 7.days.since)
    orig = poll.polls_votes_count
    assert_count_increases(PollsVote) do
      post :vote, { :id => poll.id, :poll_option => poll.polls_options.find(:first).id }
    end
    assert_response :redirect
    poll.reload
    assert_equal orig + 1, poll.polls_votes_count
  end
end

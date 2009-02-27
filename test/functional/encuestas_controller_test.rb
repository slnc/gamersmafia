require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'encuestas_controller'

# Re-raise errors caught by the controller.
class EncuestasController; def rescue_action(e) raise e end; end

class EncuestasControllerTest < Test::Unit::TestCase
  test_common_content_crud :name => 'Poll', :form_vars => {:title => 'footapang', :starts_on => 2.days.since, :ends_on => 9.days.since}, :root_terms => 1

  def setup
    @controller = EncuestasController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_create_with_options
    post :create, {:poll => {:title => 'footapang', :terms => 1, :starts_on => 2.days.since, :ends_on => 9.days.since, :options_new => ['opcion1', 'opcion2']}, 
                  }, { :user => 1 }
    assert_response :redirect
    b = Poll.find_by_title('footapang')
    assert_not_nil b
    assert_equal 2, b.polls_options.count
    assert_not_nil b.polls_options.find_by_name('opcion1')
    assert_not_nil b.polls_options.find_by_name('opcion2')
  end

  def test_should_publish_as_is
    test_should_create_with_options
    b = Poll.find_by_title('footapang')
    post :update, {:id => b.id,
                   :poll => {:approved_by_user_id => 1}
                  }
    b.reload
    assert_equal 2, b.polls_options.count
    assert_not_nil b.polls_options.find_by_name('opcion1')
    assert_not_nil b.polls_options.find_by_name('opcion2')
  end

  def test_should_allow_to_change_options_if_not_published
    test_should_create_with_options
    b = Poll.find_by_title('footapang')
    post :update, {:id => b.id,
                   :options => {b.polls_options.find_by_name('opcion1').id => 'opcion1_mod',
                     b.polls_options.find_by_name('opcion2').id => 'opcion2_mod'}, # lo hacemos a propósito porque primero se borra y luego se actualiza, para comprobar que no se intenta actualizar una opción borrada
                   :options_delete => [b.polls_options.find_by_name('opcion2').id],
                   :options_new => ['opcion3', 'opcion4']
                  }
    b.reload
    assert_equal 3, b.polls_options.count
    assert_nil b.polls_options.find_by_name('opcion1')
    assert_not_nil b.polls_options.find_by_name('opcion1_mod')
    assert_nil b.polls_options.find_by_name('opcion2')
    assert_not_nil b.polls_options.find_by_name('opcion3')
    assert_not_nil b.polls_options.find_by_name('opcion4')
  end
end

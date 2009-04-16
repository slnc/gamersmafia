require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'apuestas_controller'

class ApuestasControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Bet', :form_vars => {:title => 'footapang', :closes_on => 1.week.since, :options_new => ['opcion1', 'opcion2']}, :root_terms => 1
  
  # TODO más tests
  #
  def test_should_create_with_options
    sym_login 1
    post :create, :bet => {:title => 'footapang', :closes_on => 1.week.since, :options_new => ['opcion1', 'opcion2']}, :root_terms => 1
    assert_response :redirect
    @b = Bet.find_by_title('footapang')
    assert_not_nil @b
    assert_equal 2, @b.bets_options.count
    assert_not_nil @b.bets_options.find_by_name('opcion1')
    assert_not_nil @b.bets_options.find_by_name('opcion2')
  end
  
  #  def test_should_publish_as_is
  #    test_should_create_with_options
  #    
  #    @b = Bet.find_by_title('footapang')
  #    post :update, {:id => @b.id,
  #                   :bet => {:approved_by_user_id => 1}
  #                  }
  #    @b.reload
  #    assert_equal Cms::PUBLISHED, @b.state
  #    assert_equal 2, @b.bets_options.count
  #    assert_not_nil @b.bets_options.find_by_name('opcion1')
  #    assert_not_nil @b.bets_options.find_by_name('opcion2')
  #  end
  
  def test_should_allow_to_change_options_if_not_published
    test_should_create_with_options
    b = Bet.find_by_title('footapang')
    post :update, {:id => b.id,
      :bet => { :options => {b.bets_options.find_by_name('opcion1').id => 'opcion1_mod',
        b.bets_options.find_by_name('opcion2').id => 'opcion2_mod'}, # lo hacemos a propósito porque primero se borra y luego se actualiza, para comprobar que no se intenta actualizar una opción borrada
      :options_delete => [b.bets_options.find_by_name('opcion2').id],
      :options_new => ['opcion3', 'opcion4'] }
    }
    b.reload
    assert_equal 3, b.bets_options.count
    assert_nil b.bets_options.find_by_name('opcion1')
    assert_not_nil b.bets_options.find_by_name('opcion1_mod')
    assert_nil b.bets_options.find_by_name('opcion2')
    assert_not_nil b.bets_options.find_by_name('opcion3')
    assert_not_nil b.bets_options.find_by_name('opcion4')
  end
  
  # TODO faltan tests
  def test_shouldnt_allow_to_reduce_bet_for_option_after_15min
    test_should_create_with_options
    sym_login 1
    Bank.transfer(:bank, User.find(1), 100, "Asuntos sucios")
    Cms::publish_content(@b, User.find_by_login('mrman'))
    assert_equal Cms::PUBLISHED, @b.state
    bop1 = @b.bets_options.find(:first)
    post :update_cash_for_bet, {:id => @b.id, :bet_options => {bop1.id.to_s => '10'}}
    assert_response :redirect
    
    bt = bop1.bets_tickets.find(:first, :order => 'id DESC')
    # test that it works if within time limit
    post :update_cash_for_bet, {:id => @b.id, :bet_options => {bop1.id.to_s => '9'}}
    assert_response :redirect
    assert_nil flash[:error], flash[:error]
    bt.reload
    assert_equal 9, bt.ammount.to_i
    
    
    bt.created_on = 2.weeks.ago
    assert_equal true, bt.save
    
    # out of time limit
    post :update_cash_for_bet, {:id => @b.id, :bet_options => {bop1.id.to_s => '5'}}
    assert_response :redirect
    assert_not_nil flash[:error]
    bt.reload
    assert_equal 9, bt.ammount.to_i 
  end
  
  def test_complete_should_work
    test_should_create_with_options
    Cms::modify_content_state(@b, User.find(1), Cms::PUBLISHED)
    @b.reload
    @b.closes_on = 1.week.ago
    assert @b.save
    post :complete, { :id => @b.id, :winner => @b.bets_options.find(:first).id }
    assert_response :redirect
    assert !@b.completed?
    @b.reload
    assert @b.completed?
  end
  
  def test_resolve_should_work
    test_should_create_with_options
    Cms::modify_content_state(@b, User.find(1), Cms::PUBLISHED)
    @b.reload
    @b.closes_on = 1.week.ago
    assert @b.save
    get :resolve, { :id => @b.id }
    assert_response :success
  end
  
  def test_cambiar_resultado_should_work
    test_complete_should_work
    post :cambiar_resultado, :id => @b.id
    assert_redirected_to "/apuestas/resolve/#{@b.id}"
    @b.reload
    assert !@b.completed?
  end
end

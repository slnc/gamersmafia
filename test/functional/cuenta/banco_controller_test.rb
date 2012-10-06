# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::BancoControllerTest < ActionController::TestCase

  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end
  test "transfer_should_redirect_if_all_missing" do
    give_skill(1, "Bank")
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    assert_raises(ActiveRecord::RecordNotFound) do
      post :confirmar_transferencia, {}
    end
  end

  test "transfer_should_redirect_if_recipient_class_empty" do
    give_skill(1, "Bank")
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    assert_raises(ActiveRecord::RecordNotFound) do
      post :confirmar_transferencia, {:recipient_class => ''}
    end
  end

  test "transfer_should_redirect_if_not_found_recipient" do
    give_skill(1, "Bank")
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {
        :sender_class => 'User',
        :sender_id => 1,
        :recipient_class => 'User',
        :recipient_user_login => 'bananito',
        :description => 'foo',
        :ammount => '500',
    }
    assert_redirected_to '/'
  end

  test "transfer_should_redirect_if_no_description" do
    give_skill(1, "Bank")
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {
        :sender_class => 'User',
        :sender_id => 1,
        :recipient_class => 'User',
        :recipient_user_login => 'panzer',
        :description => '',
        :ammount => '500',
    }
    assert_redirected_to '/'
  end

  test "transfer_should_redirect_if_no_ammount" do
    give_skill(1, "Bank")
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {
        :sender_class => 'User',
        :sender_id => 1,
        :recipient_class => 'User',
        :recipient_user_login => 'panzer',
        :description => 'foobar',
        :ammount => '',
    }
    assert_redirected_to '/'
  end

  test "transfer_should_redirect_if_same_sender_and_recipient" do
    give_skill(1, "Bank")
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {
        :sender_class => 'User',
        :sender_id => 1,
        :recipient_class => 'User',
        :recipient_user_login => 'superadmin',
        :description => 'foobar',
        :ammount => '500',
    }
    assert_redirected_to '/'
  end

  test "shouldn't transfer if one party doesn't have the skill" do
    give_skill(1, "Bank")
    Bank.transfer(:bank, User.find(1), 10, 'f')
    User.db_query(
        "UPDATE users
         SET created_on = now() - '1 day'::interval
         WHERE login = 'panzer'")
    sym_login(1)
    post :confirmar_transferencia, {
        :sender_class => 'User',
        :sender_id => 1,
        :recipient_class => 'User',
        :recipient_user_login => 'panzer',
        :description => 'foobar',
        :ammount => '1',
    }
    assert_response :redirect
  end

  test "transfer_should_show_confirm_dialog_if_all_existing" do
    give_skill(1, "Bank")
    give_skill(User.find_by_login("panzer").id, "Bank")
    Bank.transfer(:bank, User.find(1), 10, 'f')
    User.db_query(
        "UPDATE users
         SET created_on = now() - '2 months'::interval
         WHERE login = 'panzer'")
    sym_login(1)
    post :confirmar_transferencia, {
        :sender_class => 'User',
        :sender_id => 1,
        :recipient_class => 'User',
        :recipient_user_login => 'panzer',
        :description => 'foobar',
        :ammount => '1',
    }
    assert_response :success
    assert_template 'cuenta/banco/confirmar_transferencia'
  end

  test "transferencia_confirmada" do
    test_transfer_should_show_confirm_dialog_if_all_existing
    assert_count_increases(CashMovement) do
      post :transferencia_confirmada, {
          :redirto => '/',
          :sender_class => 'User',
          :sender_id => 1,
          :recipient_class => 'User',
          :recipient_id => User.find_by_login('panzer').id,
          :description => 'foobar',
          :ammount => '1',
      }
    end
    assert_response :redirect
  end
end

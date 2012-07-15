# -*- encoding : utf-8 -*-
require 'test_helper'

class FaccionControllerTest < ActionController::TestCase
  test "index" do
    @request.host = "ut.#{App.domain}"
    get :index
    assert_response :success
  end

  test "miembros" do
    @request.host = "ut.#{App.domain}"
    get :miembros
    assert_response :success
  end

  test "clanes" do
    @request.host = "ut.#{App.domain}"
    get :clanes
    assert_response :success
  end

  test "staff" do
    @request.host = "ut.#{App.domain}"
    get :staff
    assert_response :success
  end
end

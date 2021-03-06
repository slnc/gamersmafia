# -*- encoding : utf-8 -*-
require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  test "all products should have can_be_bought_by_user" do
    u1 = User.find(1)
    Product.find(:all).each do |product|
      product.can_be_bought_by_user(u1)
    end
  end

  test "can_only_have_one_reason" do
    u1 = User.find(1)
    Product::CAN_ONLY_HAVE_ONE.each do |name|
      reason = Product.find_by_cls(name).cant_be_bought_by_user_reason(u1)
      assert_not_nil reason.index(Product::REASON_CAN_ONLY_HAVE_ONE)
    end
  end

  test "all products should have cant_be_bought_user_reason" do
    u1 = User.find(1)
    Product.find(:all).each do |product|
      product.cant_be_bought_by_user_reason(u1)
    end
  end
end

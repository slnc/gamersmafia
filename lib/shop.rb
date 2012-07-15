# -*- encoding : utf-8 -*-
module Shop
  def self.buy(product, user)
    raise AccessDenied if user.cash < product.price or not product.can_be_bought_by_user(user)
    prod = Object.const_get(product.cls).create({:user_id => user.id, :product_id => product.id, :price_paid => product.price})
    Bank.transfer(user, :bank, product.price, "Compra de un \"#{product.name}\"")
    prod
  end
end

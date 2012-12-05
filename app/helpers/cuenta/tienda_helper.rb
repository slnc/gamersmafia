# -*- encoding : utf-8 -*-
module Cuenta::TiendaHelper
  def product_img(product, link=true)
    if link
      "<div class=\"product-img #{product.cls}\"><a href=\"/cuenta/tienda/#{product.id}\"><img src=\"/images/dot.gif\" /></a></div>"
    else
      "<div class=\"product-img #{product.cls}\"><img src=\"/images/dot.gif\" /></div>"
    end
  end

  def product_line(product)
    "<div class=\"product-line\">#{product.price.to_i}#{gm_icon("gmf", "small")}</div>"
  end
end

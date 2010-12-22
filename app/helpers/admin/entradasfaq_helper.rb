module Admin::EntradasfaqHelper
  def submenu
    'faq'
  end
  
  def submenu_items
    [['Entradas', '/admin/entradasfaq'],
    ['Categorías', '/admin/categoriasfaq']]
  end
end

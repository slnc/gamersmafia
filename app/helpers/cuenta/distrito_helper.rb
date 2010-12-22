module Cuenta::DistritoHelper
  def submenu
    'Distrito'
  end
  
  def submenu_items
    l = [] 
    
    l<<['Staff', '/cuenta/distrito/staff']
    l<<['Categorías de contenidos', '/cuenta/distrito/categorias']
    
    l
  end
end

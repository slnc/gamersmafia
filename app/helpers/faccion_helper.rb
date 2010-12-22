module FaccionHelper    
  def submenu
    'Facción'
  end
  
  def submenu_items
    [['Información', '/faccion'],
    ['Miembros', '/faccion/miembros'],
    ['Clanes', '/faccion/clanes'],
    ['Staff', '/faccion/staff']]
  end
end

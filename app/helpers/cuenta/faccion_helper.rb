module Cuenta::FaccionHelper
  def submenu
    if @faction and (user_is_boss(@user, @faction) or @faction.is_editor?(@user)) then
      return 'Facción'
    else
      return nil
    end
  end
  
  def submenu_items
    l = [] 
    if @faction and (user_is_boss(@user, @faction) or @user.is_superadmin) then
      l<<['Información', '/cuenta/faccion/informacion']
      l<<['Staff', '/cuenta/faccion/staff']
      l<<['Cabeceras', '/cuenta/faccion/cabeceras']
      l<<['Links', '/cuenta/faccion/links']
      l<<['Mapas del juego', '/cuenta/faccion/mapas_juegos']
      l<<['Bans', '/cuenta/faccion/bans']
      l<<['Juego', '/cuenta/faccion/juego'] if @faction.game # TODO save this on the model
    end
    
    if @faction and @faction.is_editor?(@user) then
      l<<['Categorías', '/cuenta/faccion/categorias']
    end
    
    l
  end
end

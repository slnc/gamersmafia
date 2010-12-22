module ClanesHelper
  def submenu
    'Clan' if curclan 
  end
  
  def submenu_items
    l =  []
    
    if curclan then
      l<< ['General', "/clanes/clan/#{@clan.id}"]
      l<< ['Competición', "/clanes/clan/#{@clan.id}/competicion"]
    end
    
    l
  end
end

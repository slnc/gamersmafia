ImagesCategory.find(:all, :conditions => 'id = root_id and clan_id IS NULL').each do |imc|
  child = imc.children.find(:first)
  Image.find(:all, :conditions => ['images_category_id = ?', imc.id]).each do |im|
    puts imc.name
    if child.nil?
      puts "no hay categoria hija pero hay imagenes aqui " << imc.id.to_s
      break
    end

    puts im.id.to_s
    im.update_attributes(:images_category_id => child.id)
  end
end


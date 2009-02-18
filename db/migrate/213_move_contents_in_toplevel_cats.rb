class MoveContentsInToplevelCats < ActiveRecord::Migration
  def self.up
    # Cms::BAZAR_DISTRICTS_VALID.each do |ct|
    # busca topics publicados en un foro de primer nivel y los corrige
      %w(Topic).each do |ct|
      cls = Object.const_get(ct)
      BazarDistrict.find(:all).each do |bd|
        tld = bd.top_level_category(cls)
        next unless tld
        items = cls.find(:all, :conditions => "topics_category_id = " << tld.id.to_s)
        if items.size > 0
          child = tld.children.find_by_name('General')
          child = tld.children.create(:name => 'General') if child.nil?
          puts "hay items en cat de primer nivel"
          puts bd.name
          puts ct
          puts items.size
          puts "\n"
          items.each do |i|
            i.update_attributes(:topics_category_id => child.id)
          end
        end
      end
    end
    
    
    # revisa que todas las categorías tengan el root_id correcto
    Cms::CONTENTS_WITH_CATEGORIES.each do |cname|
      puts cname
      cclass = Object.const_get(cname)
      cclass = cclass.category_class
      cclass.find(:all).each do |cat|
        next if cat.id == cat.root_id
        if cat.ancestors.last.id != cat.root_id
          puts "CATEGORIA ERRONEA"
          p cat
          cat.update_attributes(:root_id => cat.ancestors.last.id)
        end
      end
    end
    
    # unrelated script
    UsersPreference.find(:all, :conditions => 'name = \'quicklinks\'').each do |up|
      if up.value && up.value.size > 8 then
        puts up.user.login
        Personalization.clear_quicklinks(up.user)
        Message.create(:user_id_from => 1, :user_id_to => up.user_id, :title => 'Iconos de acceso directo', :message => 'Hola, estoy intentando corregir un problema con los accesos directos que se reproducen como lemmings en algunas cuentas y para eso he reseteado tus accesos directos. Por favor, si te vuelven a dar problemas avísame. Un saludo y siento las molestias')
      end
    end
    
  end
  
  def self.down
  end
end

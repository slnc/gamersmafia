class Potd < ActiveRecord::Base
  belongs_to :image
  
  def Potd.choose_one_portal(portal)
    # selecciona una imagen apta para aparecer como imagen del día
    # Algoritmo:
    #
    # 1º mejor valorada que no haya aparecido en portada desde hace más de 1 año
    #
    # 2º aleatoria de una facción aleatoria que no haya sido elegida para potd en
    #    los últimos 7 días (se ordenan por número de visitas desc)
    #
    # 3º una imagen aleatoria cualquiera
    gm_cat = ImagesCategory.find(:first, :conditions => 'code = \'bazar\' and id = root_id')
    invalid_categories = [0]
    
    if gm_cat then
      invalid_categories<< gm_cat.get_all_children
    end
    is_general_portal = portal.kind_of?(GmPortal) || portal.kind_of?(BazarPortal) || portal.kind_of?(ArenaPortal) 
    q_portal1 = is_general_portal ? "AND clan_id IS NULL" : "AND images_category_id IN (#{portal.get_categories(ImagesCategory).join(',')})" 
    
    invalid_categories2 = [] + invalid_categories
    
    q_7days = "= #{portal.id} and images_category_id is null"
    
    
    
      for p in Potd.find(:all, :conditions => "date > now() - \'5 days\'::interval and portal_id #{q_7days}")
        for c in p.image.images_category.root.get_all_children
          invalid_categories2<< c
        end
      end
      
      invalid_categories2.uniq!
      
      if invalid_categories2.size == 0 then
        invalid_categories2 = [0]
      end
      
      invalid_categories3 = invalid_categories # necesario para portales de facciones
      if is_general_portal then  # nos aseguramos de que no se repita facción
        invalid_categories3 = invalid_categories2
        # invalid_categories = invalid_categories2
      end
    
    im = Image.find_by_sql("SELECT * 
                              FROM images 
                             WHERE state = #{Cms::PUBLISHED}
                               AND images_category_id NOT IN (#{invalid_categories3.join(',')}) 
                               #{q_portal1}
                               AND id NOT IN (select distinct(image_id) from potds WHERE portal_id #{q_7days})
                               AND cache_weighted_rank > 5 and cache_rated_times > 1 
                          ORDER BY cache_weighted_rank DESC LIMIT 1")
    
    if im.size == 0 then
      invalid_categories3 = invalid_categories2 # para portales de facciones
      # averiguar categorías de las imgs de los últimos 7 días
      im = Image.find_by_sql("SELECT * 
                                FROM images 
                               WHERE state = #{Cms::PUBLISHED}
                               #{q_portal1}
                                 AND images_category_id <> #{gm_cat.id} 
                                 AND id NOT IN (select distinct(image_id) from potds WHERE portal_id #{q_7days}) 
                                 AND images_category_id NOT IN (#{invalid_categories3.join(',')}) 
                            ORDER BY random() LIMIT 1")
      
      if im.size == 0 then
        im = Image.find_by_sql("SELECT * 
                                  FROM images 
                                 WHERE state = #{Cms::PUBLISHED}
                                   #{q_portal1}
                                   AND images_category_id NOT IN (#{invalid_categories.join(',')}) 
                              ORDER BY random() LIMIT 1")
      end
    end
    
    if !is_general_portal && im.size > 0
      begin
        Potd.create({:date => Date.today, :image_id => im[0].id, :portal_id => portal.id})
      rescue ActiveRecord::StatementInvalid # necesario por si dos usuarios visitan la web a la vez
      end
    end
  end
  
  def Potd.choose_one_category(category_id, d=Date.today)
    # selecciona una imagen apta para aparecer como imagen del día
    # Algoritmo:
    #
    # 1º mejor valorada que no haya aparecido en portada 
    #
    # 2º aleatoria
    
    q_category = category_id ? " images_category_id = #{category_id}" : '' 
    
    im = Image.find_by_sql("SELECT * 
                              FROM images 
                             WHERE state = #{Cms::PUBLISHED}
                               AND #{q_category}
                               AND id NOT IN (select distinct(image_id) from potds WHERE #{q_category})
                               AND cache_weighted_rank > 5 and cache_rated_times > 1 
                          ORDER BY cache_weighted_rank DESC LIMIT 1")
    
    if im.size == 0 then
      # averiguar categorías de las imgs de los últimos 7 días
      im = Image.find_by_sql("SELECT * 
                                FROM images 
                               WHERE state = #{Cms::PUBLISHED}
                               AND #{q_category}
                            ORDER BY random() LIMIT 1")
    end
    
    if im.size > 0
      begin
        Potd.create({:date => d, :image_id => im[0].id, :images_category_id => category_id})
      rescue ActiveRecord::StatementInvalid # necesario por si dos usuarios visitan la web a la vez
      end
    end
  end
  
  
  def Potd.current_portal(portal = nil)
    is_general_portal = portal.kind_of?(GmPortal)
    #if is_general_portal
    #  potd = Potd.find(:first, :conditions => ['date = ? and portal_id IS NULL', Date.today])
    #else
      potd = Potd.find(:first, :conditions => ['date = ? AND portal_id = ?', Date.today, portal.id])
    #end
    
    potd = Potd.choose_one_portal(portal) if potd.nil?
    potd
  end
  
  def Potd.current_category(category_id, d=Date.today)
    potd = Potd.find(:first, :conditions => ['date = ? AND images_category_id = ?', d, category_id])
    potd = Potd.choose_one_category(category_id, d) if potd.nil?
    potd
  end
end

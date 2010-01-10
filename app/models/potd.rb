require "date"
class Potd < ActiveRecord::Base
  belongs_to :image
  
  def Potd.current_portal(portal = nil)
    potd = Potd.find(:first, :conditions => ['date = ? AND portal_id = ?', Date.today, portal.id])
    potd = Potd.choose_one_portal(portal) if potd.nil?
    potd
  end
  
  def Potd.current_category(term_id, d=Date.today)
    potd = Potd.find(:first, :conditions => ['date = ? AND term_id = ?', d, term_id])
    potd = Potd.choose_one_category(term_id, d) if potd.nil?
    potd
  end
  
  def Potd.choose_one_portal(portal)
    terms = portal.images_categories
    term = terms[0]
    if portal.code == 'gm'
	    term = Term.single_toplevel(:slug => 'gm')
    end
    (terms - [term]).each { |t| term.add_sibling(t) unless portal.code == 'gm' && (t.game_id.nil? && t.platform_id.nil?) }
    
    im = select_from_term(term, "images.clan_id IS NULL AND images.id NOT IN (select distinct(image_id) from potds WHERE portal_id = #{portal.id})")
    
    if im
      begin
        Potd.create({:date => Date.today, :image_id => im.id, :portal_id => portal.id})
      rescue ActiveRecord::StatementInvalid # necesario por si dos usuarios visitan la web a la vez
      end
    end
  end
  
  def Potd.choose_one_category(term_id, d=Date.today)
    term = Term.find(term_id)
    im = select_from_term(term, "images.clan_id IS NULL AND images.id NOT IN (select distinct(image_id) from potds WHERE term_id = #{term_id})")
    if im
      begin
        Potd.create({:date => d, :image_id => im.id, :term_id => term_id})
      rescue ActiveRecord::StatementInvalid # necesario por si dos usuarios visitan la web a la vez
      end
    end
  end
  
  # elige una imagen del term especificado
  # selecciona una imagen apta para aparecer como imagen del día
  # Algoritmo:
  #
  # 1º mejor valorada que no haya aparecido en portada 
  #
  # 2º aleatoria
  def self.select_from_term(term, conditions)
    im = term.image.find(:first, 
                         :conditions => "contents.state = #{Cms::PUBLISHED}
                                       AND #{conditions}
                                       AND cache_weighted_rank > 5 
                                       AND cache_rated_times > 1", 
    :order => 'cache_weighted_rank DESC')
    
    if im.nil? then
      # averiguar categorías de las imgs de los últimos 7 días
      im = term.image.find(:first, 
                           :conditions => "#{conditions} AND contents.state = #{Cms::PUBLISHED}", 
      :order => 'random()')
    end
    im
  end
end

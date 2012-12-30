# -*- encoding : utf-8 -*-
class Potd < ActiveRecord::Base
  MIN_RANK_FOR_POTD = 5
  MIN_RATINGS_FOR_POTD = 1

  belongs_to :image

  def self.current
    Potd.find(:first, :conditions => ['date = ?', Date.today])
  end

  def self.current_category(term_id, date=Date.today)
    potd = Potd.find(:first,
                     :conditions => ['date = ? AND term_id = ?', date, term_id])
    potd || Potd.choose_one_category(term_id, date)
  end

  def self.choose_one_category(term_id, d=Date.today)
    im = select_from_term(
      Term.find(term_id),
      "clan_id IS NULL
       AND id NOT IN (SELECT distinct(content_id)
                      FROM potds
                      WHERE term_id = #{term_id})")
    if im
      begin
        Potd.create({:date => d, :content_id => im.id, :term_id => term_id})
      rescue ActiveRecord::StatementInvalid
        # Necesario por si dos usuarios visitan la web a la vez
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
    image_proxy = term.images

    if image_proxy.nil?
      Rails.logger.error("Term #{term} has no image proxy to select potd from.")
      return
    end

    im = Image.in_term(term).published.find(
      :first,
      :conditions => "#{conditions}
                      AND cache_weighted_rank >= #{MIN_RANK_FOR_POTD}
                      AND cache_rated_times > #{MIN_RANK_FOR_POTD}",
      :order => "cache_weighted_rank DESC")

    if im.nil? then
      # averiguar categorías de las imgs de los últimos 7 días
      im = Image.in_term(term).published.find(
        :first,
        :conditions => conditions,
        :order => 'RANDOM()')
    end
    im
  end
end

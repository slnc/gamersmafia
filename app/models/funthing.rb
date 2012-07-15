# -*- encoding : utf-8 -*-
class Funthing < ActiveRecord::Base
  YOUTUBE_EMBED = /^http:\/\/([a-z.]*)youtube.com\/watch\?v=([a-zA-Z0-9]+)/
  # http://       www.youtube.com/v/6-ecf9_X_Dk&hl=es&fs=1
  YOUTUBE_EMBED2 = /http:\/\/([a-z.]*)youtube.com\/v\/([a-zA-Z0-9_-]+)/

  acts_as_content
  before_validation :check_youtube_embed
  before_validation :filter_main

  validates_presence_of [ :title, :main ], :message => 'no pueden estar vacíos con este campo'
  validates_uniqueness_of [ :title, :main ], :message => 'ya existe otra curiosidad con este campo'


  def filter_main
    if self.main.to_s.downcase.include?('<script')
      self.errors.add('main', 'No se pueden enviar curiosidades que contengan iframes o código JavaScript.')
      false
    else
      true
    end
  end

  def content
    main =~ Cms::URL_REGEXP_FULL ? "<a href=\"#{main}\">#{main.gsub(/http:\/\//, '')}</a>"  : main
  end

  def check_youtube_embed
    if YOUTUBE_EMBED =~ self.main
      info = self.main.match(YOUTUBE_EMBED)
      self.main = "<object width=\"425\" height=\"355\"><param name=\"movie\" value=\"http://www.youtube.com/v/#{info[2]}&rel=1\"></param><param name=\"wmode\" value=\"transparent\"></param><embed src=\"http://www.youtube.com/v/#{info[2]}&rel=1\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"425\" height=\"355\"></embed></object>"
    end
    q_id = self.new_record? ? nil : "id <> #{self.id} AND"
    Funthing.count(:conditions => ["#{q_id} main = ?", self.main]) == 0
  end

  def thumbnail
    if YOUTUBE_EMBED2 =~ self.main
      info = self.main.match(YOUTUBE_EMBED2)
      "http://img.youtube.com/vi/#{info[2]}/2.jpg"
    end
  end
end

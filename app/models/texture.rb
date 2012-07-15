# -*- encoding : utf-8 -*-
class Texture < ActiveRecord::Base
  has_many :skin_textures
  file_column :screenshot


  def markers
    ["/* CSS_TEXTURE_#{self.name}_START */", "/* CSS_TEXTURE_#{self.name}_END */"]
  end

  def dir
    "#{Rails.root}/config/skins/textures/#{self.name}"
  end

  def screenshot
    "<img src=\"/skins_textures/#{name}.png\" />"
  end

  def texture_attrs
    # Devuelve los atributos de esta textura
    HashWithIndifferentAccess.new(YAML::load(File.open("#{dir}/config.yml") { |f| f.read }))
  end
end

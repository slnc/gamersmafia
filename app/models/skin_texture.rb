class SkinTexture < ActiveRecord::Base
  # representa una instancia de una textura final asociada a una skin
  serialize :user_config
  belongs_to :skin
  belongs_to :texture
  before_create :set_position
  validates_presence_of :skin_id, :texture_id, :element
  before_save :check_element
  before_save :check_user_config


  def process
    # Llamamos al generador con los atributos del usuario, los de la textura los puede coger él solito
    Skins::TexturesGenerators.const_get(self.texture.generator).new.process(self.texture, self.user_config.merge({:element_selector => self.element}))
  end

  def initialize_user_attributes
    # Rellena los valores de usuario por defecto que pueda
    # TODO self.user_config.merge
  end

  private
  def set_position
    # textured_element_posicion es la posición del elemento texturizado: body es el primero, los modules en general van antes que los mf, etc
    # texture_skin_position es la posición de la texture_skin aplicada a la skin actual, se usa para ordenar las texturas aplicadas a un mismo elemento
    self.textured_element_position = Skins::TexturesGenerators.get_priority_for_element(element)
    self.texture_skin_position = User.db_query("SELECT coalesce(max(texture_skin_position),0) as max from skin_textures WHERE skin_id = #{skin_id.to_i} and textured_element_position = #{textured_element_position}")[0]['max'].to_i + 1
  end

  def check_user_config
    self.user_config ||= begin
      attrs = {}
      Skins::TexturesGenerators.const_get(self.texture.generator)::USER_OPTIONS.each do |k, v|
        attrs[k] = v.to_s
      end
      attrs
    end
    true
  end

  def check_element
    begin
      Skins::TexturesGenerators.get_priority_for_element(self.element.gsub("'", ''))
    rescue
      self.errors.add('element', "El elemento #{self.element} no está reconocido")
      false
    else
      true
    end
  end
end

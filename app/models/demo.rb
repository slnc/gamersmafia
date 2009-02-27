class Demo < ActiveRecord::Base
  POVS = {:freeflight => 0, :chase => 1, :in_eyes => 2, :server => 3}
  DEMOTYPES = {:official => 0, :friendly => 1, :tutorial => 2 }
  

  before_save :check_model # order is important
  before_save :set_name
  
  acts_as_content
  acts_as_categorizable
  
  belongs_to :games_mode
  belongs_to :games_version
  belongs_to :event
  belongs_to :games_map
  
  file_column :file
  has_many :demo_mirrors, :dependent => :destroy

  validates_presence_of :games_mode_id
  
  
  
  attr_accessor :entity1_is_local, :entity2_is_local
  
  public
  def entity1
    # PERF esto puede ralentizar, a lo mejor es más rápido con 4 columnas (user1_id, user2_id, clan1_id, clan2_id)
    # No, definitivamente no, habría que hacer un join con 4 columnas, no puede ser más rápido
    entity1_local_id ? Object.const_get(games_mode.entity_type == Game::ENTITY_USER ? 'User' : 'Clan').find(entity1_local_id) : entity1_external
  end
  
  def entity2
    # PERF esto puede ralentizar, a lo mejor es más rápido con 4 columnas (user1_id, user2_id, clan1_id, clan2_id)
    # No, definitivamente no, habría que hacer un join con 4 columnas, no puede ser más rápido
    entity2_local_id ? Object.const_get(games_mode.entity_type == Game::ENTITY_USER ? 'User' : 'Clan').find(entity2_local_id) : entity2_external
  end  
  
  private
  def set_name
    # autoset name based on entities
    self.title = (demotype != DEMOTYPES[:tutorial]) ? "#{self.entity1.to_s} - #{self.entity2.to_s}" : "#{self.entity1.to_s}"
    true
  end
  
  def check_model
    if self.main_category && self.games_mode.game.code != self.main_category.root.code then
      self.errors.add('games_mode', 'El modo de juego especificado no se corresponde con el juego elegido.')
      return false
    end
    # Comprueba que el modelo es congruente con los datos introducidos
    if pov_type && !POVS.values.include?(self.pov_type.to_i) then
      self.errors.add('pov_type', 'El POV introducido no es correcto.')
      return false
    end
    
    if demotype && !DEMOTYPES.values.include?(self.demotype.to_i) then
      self.errors.add('demotype', 'El tipo de demo introducido no es correcto.')
      return false
    end
    
    # Si entity1_is_local o entity2_is_local buscamos users por login o clanes por nombre/tag
    if @entity1_is_local # está poniendo en entity1_external el login/name o tag de un user/clan
      if games_mode.entity_type == Game::ENTITY_USER
        e1 = User.find_by_login(self.entity1_external)
        if e1.nil? then
          self.errors.add('entity1', "El usuario \"#{self.entity1_external}\" especificado como primer participante no está registrado en Gamersmafia.")
          return false
        end
      elsif games_mode.entity_type == Game::ENTITY_CLAN # entity1, clan
        e1 = Clan.find(:first, :conditions => ['lower(name) = lower(?)', self.entity1_external])
        e1 = Clan.find(:first, :conditions => ['lower(tag) = lower(?)', self.entity1_external]) if e1.nil?
        
        if e1.nil? then
          self.errors.add('entity1', "El clan \"#{self.entity1_external}\" especificado como primer participante no está registrado en Gamersmafia.")
          return false
        end
      end
      self.entity1_local_id = e1.id
      self.entity1_external = nil
    end
    
    # TODO copypaste
    if @entity2_is_local # está poniendo en entity2_external el login/name o tag de un user/clan
      if games_mode.entity_type == Game::ENTITY_USER
        e2 = User.find_by_login(self.entity2_external)
        if e2.nil? then
          self.errors.add('entity2', "El usuario \"#{self.entity2_external}\"especificado como segundo participante no está registrado en Gamersmafia.")
          return false
        end
        self.entity2_external = nil
      elsif games_mode.entity_type == Game::ENTITY_CLAN # entity2, clan
        e2 = Clan.find(:first, :conditions => ['lower(name) = lower(?)', self.entity2_external])
        e2 = Clan.find(:first, :conditions => ['lower(tag) = lower(?)', self.entity2_external]) if e2.nil?
        
        if e2.nil? then
          self.errors.add('entity2', "El clan \"#{self.entity2_external}\" especificado como segundo participante no está registrado en Gamersmafia.")
          return false
        end
      end
      self.entity2_local_id = e2.id
      self.entity2_external = nil
    end
    
    # TODO chequear games_mode y games_version
    

    # check_entities
    # 1º comprobamos que si han especificado entidades locales de gm éstas existen
    case games_mode.entity_type
      when Game::ENTITY_USER:
      the_what = 'usuario'
      if entity1_local_id && User.find_by_id(entity1_local_id).nil? then
        self.errors.add('entity1', 'El usuario especificado como primer participante no está registrado en Gamersmafia.')
        return false
      end
      
      if entity2_local_id && User.find_by_id(entity2_local_id).nil? then
        self.errors.add('entity2', 'El usuario especificado como segundo participante no está registrado en Gamersmafia.')
        return false
      end
      
      when Game::ENTITY_CLAN:
      the_what = 'clan'
      if entity1_local_id && Clan.find_by_id(entity1_local_id).nil? then
        self.errors.add('entity1', 'El clan especificado como primer participante no está registrado en Gamersmafia.')
        return false
      end
      
      if entity2_local_id && Clan.find_by_id(entity2_local_id).nil? then
        self.errors.add('entity2', 'El clan especificado como segundo participante no está registrado en Gamersmafia.')
        return false
      end
    else
      raise 'Unknown entity type'
    end
    
    if entity1_local_id && entity1_external then
      self.errors.add('entity1', "El #{the_what} se ha especificado tanto registrado en GM como externo.")
      return false
    end
    
    if entity2_local_id && entity2_external then
      self.errors.add('entity2', "El #{the_what} se ha especificado tanto registrado en GM como externo.")
      return false
    end
    
    # 2º comprobamos si han especificado las entidades necesarias según el tipo de demo (tutorial u otras)
    # si el tipo de demo es tutorial no es necesario haber especificado un segundo participante
    if !(entity1_local_id || entity1_external)
      self.errors.add('entity1', "No ha especificado un #{the_what}.")
      return false
    end
    
    if demotype != DEMOTYPES[:tutorial] && !(entity2_local_id || entity2_external)
      self.errors.add('entity2', "No ha especificado un #{the_what}.")
      return false
    end
  end
end

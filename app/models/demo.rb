# -*- encoding : utf-8 -*-
class Demo < ActiveRecord::Base
  POVS = {:freeflight => 0, :chase => 1, :in_eyes => 2, :server => 3}
  DEMOTYPES = {:official => 0, :friendly => 1, :tutorial => 2 }

  before_save :check_model # order is important
  before_save :set_name

  acts_as_content
  acts_as_categorizable

  belongs_to :event
  belongs_to :games_map
  belongs_to :games_mode
  belongs_to :games_version

  file_column :file
  has_many :demo_mirrors, :dependent => :destroy

  validates_presence_of :games_mode_id

  attr_accessor :entity1_is_local, :entity2_is_local

  after_save :process_demo_mirrors

  def mirrors_new=(opts_new)
    @_tmp_mirrors_new = opts_new
    self.attributes.delete :mirrors_new
  end

  def mirrors_delete=(opts_new)
    @_tmp_mirrors_delete = opts_new
    self.attributes.delete :mirrors_delete
  end

  def mirrors=(opts_new)
    @_tmp_mirrors = opts_new
    self.attributes.delete :mirrors
  end

  def process_demo_mirrors
    if @_tmp_mirrors_new
      @_tmp_mirrors_new.each { |s| self.demo_mirrors.create({:url => s.strip}) unless s.strip == ''  }
      @_tmp_mirrors_new = nil
    end

    if @_tmp_mirrors_delete
      @_tmp_mirrors_delete.each { |id| self.demo_mirrors.find(id).destroy if self.demo_mirrors.find_by_id(id) }
      @_tmp_mirrors_delete = nil
    end

    if @_tmp_mirrors
      @_tmp_mirrors.keys.each do |id|
        mirror = self.demo_mirrors.find_by_id(id.to_i)
        if mirror && mirror.url != @_tmp_mirrors[id]
          mirror.url = @_tmp_mirrors[id].strip
          mirror.save
        end
      end
      @_tmp_mirrors = nil
    end
    true
  end

  public
  def entity1
    self.resolve_entity("entity1")
  end

  def entity2
    self.resolve_entity("entity2")
  end

  def resolve_entity(field)
    # PERF esto puede ralentizar, a lo mejor es más rápido con 4 columnas
    # (user1_id, user2_id, clan1_id, clan2_id) No, definitivamente no, habría
    # que hacer un join con 4 columnas, no puede ser más rápido
    attr = self.send("#{field}_local_id".to_sym)
    if attr
      if games_mode.entity_type == Game::ENTITY_USER
        User.find(attr)
      else
        Clan.find(attr)
      end
    else
      self.send("#{field}_external")
    end
  end

  private
  def set_name
    # autoset name based on entities
    self.title = (demotype != DEMOTYPES[:tutorial]) ? "#{self.entity1.to_s} - #{self.entity2.to_s}" : "#{self.entity1.to_s}"
    true
  end

  def check_model
    if self.main_category && self.games_mode.game.slug != self.main_category.root.code then
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
      when Game::ENTITY_USER
      the_what = 'usuario'
      if entity1_local_id && User.find_by_id(entity1_local_id).nil? then
        self.errors.add('entity1', 'El usuario especificado como primer participante no está registrado en Gamersmafia.')
        return false
      end

      if entity2_local_id && User.find_by_id(entity2_local_id).nil? then
        self.errors.add('entity2', 'El usuario especificado como segundo participante no está registrado en Gamersmafia.')
        return false
      end

      when Game::ENTITY_CLAN
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

  scope :of_clan, lambda { |clan| { :conditions => "games_mode_id IN (SELECT id
                                                                             FROM games_modes
                                                                             WHERE entity_type = #{Game::ENTITY_CLAN})
                                                      AND (entity1_local_id = #{clan.id} OR entity2_local_id = #{clan.id})" } }

  def self.find_from_user(u, opts={})
    opts = {:limit => 5}.merge(opts)

    # buscamos clanes a los que pertenezca
    conds = []
    conds << opts[:conditions] if opts[:conditions]
    clans_ids = [0] + u.clans_ids
    conds <<  <<-END
    ((games_mode_id IN (SELECT id
                          FROM games_modes
                         WHERE entity_type = #{Game::ENTITY_USER})
      AND (entity1_local_id = #{u.id} OR entity2_local_id = #{u.id}))
     OR (games_mode_id IN (SELECT id
                             FROM games_modes
                            WHERE entity_type = #{Game::ENTITY_CLAN})
      AND (entity1_local_id IN (#{clans_ids.join(',')})
        OR entity2_local_id IN (#{clans_ids.join(',')}))))
    END
    opts[:conditions] = conds.join(' AND ')
    Rails.logger.warn("opts: #{opts}")
    self.published.find(:all, opts)
  end
end

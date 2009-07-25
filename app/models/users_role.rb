class UsersRole < ActiveRecord::Base
  VALID_ROLES = %w(Advertiser Don ManoDerecha Sicario GroupMember GroupAdministrator Moderator Editor Boss Underboss CompetitionAdmin CompetitionSupervisor)
  # role                  | role_data
  # ------------------------------------------
  # Advertiser            | advertiser_id
  # Don                   | bazar_district_id
  # ManoDerecha           | bazar_district_id
  # GroupMember           | group_id
  # GroupAdministrator    | group_id
  # Moderator             | faction_id
  # Editor                | {:content_type_id => 1, :faction_id => 2}.to_yaml
  # Boss                  | faction_id
  # Underboss             | faction_id
  # Sicario               | bazar_district_id
  # CompetitionAdmin      | competition_id
  # CompetitionSupervisor | competition_id
  
  validates_presence_of :role, :user_id
  validates_uniqueness_of :role, :scope => [:user_id, :role_data]
  
  belongs_to :user
  before_save :check_role
  before_save :toyaml_if_role_data_not_basic_type
  
  after_create :check_is_staff
  after_destroy :check_is_staff
  
  def role_data_yaml
    YAML::load(role_data)
  end
  
  def role_data_yaml=(new_role_data)
    
  end
  
  protected
  def check_role
    if VALID_ROLES.include?(self.role)
      true
    else
      self.errors.add('role', "Rol '#{self.role}' invalido.")
      false
    end
  end
  
  def toyaml_if_role_data_not_basic_type
    self.role_data = self.role_data.to_yaml unless %w(NilClass String Fixnum).include?(self.role_data.class.name) 
  end
  
  def check_is_staff
    nagato = User.find_by_login('nagato')
    if self.frozen? # quitando permiso
      Message.create(:title => "Permiso de #{format_scope} eliminado", :message => "Ya no tienes permisos de #{format_scope}", :user_id_from => nagato.id, :user_id_to => self.user_id)
    else
      Message.create(:title => "Recibido permiso de #{format_scope}", :message => "Acabas de recibir permisos de #{format_scope}", :user_id_from => nagato.id, :user_id_to => self.user_id)
    end
    
    self.user.check_is_staff
  end
  
  def format_scope
    # cambiar tb cuenta_helper role_data
    case role
      when 'Advertiser': 
      "Anunciante"
      when 'Don': 
      "Don de #{BazarDistrict.find(self.role_data.to_i).name}"
      when 'ManoDerecha': 
      "Mano derecha de #{BazarDistrict.find(self.role_data.to_i).name}"
      when 'Boss': 
      "Boss de #{Faction.find(self.role_data.to_i).name}"
      when 'Underboss': 
      "Underboss de #{Faction.find(self.role_data.to_i).name}"
      when 'Moderator': 
      "Moderador de #{Faction.find(self.role_data.to_i).name}"
      when 'Sicario': 
      "Sicario de #{BazarDistrict.find(self.role_data.to_i).name}"
      when 'Editor': 
      "Editor de #{ContentType.find(self.role_data_yaml[:content_type_id]).name} en #{Faction.find(self.role_data_yaml[:faction_id].to_i).name}"
      when 'GroupAdministrator':
      "Administrador de #{Group.find(self.role_data.to_i).name}"  
      when 'GroupMember':
      "Miembro de #{Group.find(self.role_data.to_i).name}"
      when 'CompetitionAdmin':
      "Admin de #{Competition.find(self.role_data.to_i).name}"
      when 'CompetitionSupervisor':
      "Supervisor de #{Competition.find(self.role_data.to_i).name}"
    end
  end
end

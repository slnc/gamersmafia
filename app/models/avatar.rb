class Avatar < ActiveRecord::Base
  belongs_to :faction
  belongs_to :clan
  belongs_to :user
  belongs_to :submitter, :class_name => 'User', :foreign_key => 'submitter_user_id'
  has_many :users
  file_column :path, :format => :jpg
  
  observe_attr :path
  
  before_destroy :set_users_avatar_to_nil

  after_create :create_slog_entry
  
  validates_presence_of :name
  def destroy(returning=false)
    if returning
      # buscamos el sold_product y si lo hay le devolvemos el precio que pagó
      type = (self.mode == 'user') ? 'SoldUserAvatar' : "Sold#{self.mode.titleize}Avatar"
      
      sp = SoldProduct.find(:first, :conditions => ['user_id = ? AND created_on <= ? AND type = ? AND used = true', self.submitter_user_id, self.created_on, type])
      if sp
        Bank.transfer(:bank, self.submitter, sp.price_paid, "Devolución por avatar \"#{self.name}\" borrado")
      else
        SlogEntry.create({:type => SlogEntry::TYPES[:info], :headline => ['Al borrar el avatar "?" no se encontró un producto vendido (no se devuelve dinero a ?)', self.name, self.submitter_user_id]})
      end
    end
    super()
  end
  
  def after_save
    if slnc_changed?(:path) && self.path then
      f = "#{RAILS_ROOT}/public/#{self.path}"
      
      if self.path.to_s != '' && !(/\.jpg$/ =~ self.path)
        # TODO: La mejor solución pasa por permitir especificar formatos permitidos al plugin pero aún no podemos hacer esto.
        self.path = nil
        self.save
        return
      end
      
      begin
        img = Cms::read_image(f)
        raise Exception if img.format != 'JPEG'
      rescue Exception
        self.path = nil
        self.errors.add('file', 'La imagen no tiene un formato válido.')
        self.save
        return
      end
      
      raise ActiveRecord::RecordNotFound if img.nil?
      
      if img.columns != 50 or img.rows != 50 then
        Cms.image_thumbnail(f, f, 50, 50, 'f', true)
      end
    end
    
    true
  end
  
  def create_slog_entry
    additional_text = ''
    additional_text << "#{Cms::faction_favicon(self.faction)}" if self.faction_id
    SlogEntry.create(:type_id => SlogEntry::TYPES[:new_avatar], 
                     :reporter_user_id => User.find_by_login('MrAchmed').id, 
    :headline => "#{additional_text} Nuevo avatar de #{mode}: <a href=\"http://#{App.domain}/avatares/edit/#{self.id}\"><img src=\"/cache/thumbnails/f/50x50/#{self.path}\" /></a></strong>")
  end
  
  def mode
    if faction_id 
      'faction'
    elsif clan_id
      'clan'
    else
      'user'
    end
  end
  
  def set_users_avatar_to_nil
    self.users.find(:all).each { |u| u.change_avatar }
  end
  
  def is_available_for_user(u)
    if self.clan_id && u.clans_ids.include?(self.clan_id)
      true
    elsif self.user_id && self.user_id == u.id
      true
    elsif u.faction_id && self.faction_id == u.faction_id && Karma.level(u) >= self.level
      true
    else
      false
    end
    # sql_clans = clans_ids.size > 0 ? "clan_id IN (#{clans_ids.join(',')})" : ''
    # sql_custom = "user_id = #{u.id} AND path is NOT NULL"
    # sql_factions = u.faction_id ? "faction_id = #{u.faction_id} AND path is NOT NULL" : ''
  end
end

class ClansSponsor < ActiveRecord::Base
  belongs_to :clan
  file_column :image

  after_create { |record| record.log_it(:creation) }
  after_destroy { |record| record.log_it(:destruction) }

  validates_presence_of :clan_id

  plain_text :name

  def log_it(what)
    case what
    when :creation
      # Nota: lo hacemos así para evitar cargar clan y para poder testear. 
      # Si lo hacemos así:
      #   self.clan.log("Añadido #{self.name} a la lista de sponsors")
      #
      # Al testear se borra el log al salir y además hacemos una llamada de más.
      ClansLogsEntry.create({:clan_id => self.clan_id, :message => "Añadido #{self.name} a la lista de sponsors"})
    when :destruction
      ClansLogsEntry.create({:clan_id => self.clan_id, :message => "Eliminado #{self.name} de la lista de sponsors"})
    end
  end
end

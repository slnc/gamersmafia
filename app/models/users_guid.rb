class UsersGuid < ActiveRecord::Base
  # TODO validación dependiendo del tipo
  belongs_to :user
  belongs_to :game
  validates_uniqueness_of :guid, :scope => :game_id

  def self.find_last_by(user, game)
    find(:first, :conditions => ['user_id = ? and game_id = ?', user.id, game.id], :order => 'created_on DESC')
  end

  def to_s
    # nos aseguramos de que tenga al menos longitud 4
    # mostramos solo la mitad del guid
    out = guid.ljust(4)
    (out.size / 2).times do |i|
      out[i] = '#'
    end
    out
  end

  validates_each :guid do |record, attr, value|
    record.errors.add attr, "no tiene un formato válido" if (value =~ Regexp.compile(record.game.guid_format)).nil?
  end
end

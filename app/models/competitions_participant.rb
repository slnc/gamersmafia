class CompetitionsParticipant < ActiveRecord::Base
  # result: 0 gana participant1, 1 empate, 2 gana participant2, 3 forfeit (participant1 sí se presentó), 4 forfeit de ambos, 5 forfeit (participant2 sí se presentó)
  has_many :competitions_matches
  belongs_to :competition
  before_create do |c|
    pos = Kernel.rand(999999)
    while CompetitionsParticipant.find(:first, :conditions => ['competition_id = ? and position = ?', c.competition_id, pos])
      pos = Kernel.rand(999999)
    end
    c.position = pos
  end

  def to_s
    name
  end

  def update_indicator
    tr = self.the_real_thing
    case tr.class.name
    when 'User':
      Competition.update_user_indicator(tr)
    when 'Clan':
      tr.admins.each { |user| Competition.update_user_indicator(user) }
    else
      raise "#{tr.class.name} unimplemented"
    end
  end

  def the_real_thing
    case self.competition.competitions_participants_type_id
    when 1:
      User.find(self.participant_id)
    when 2:
      Clan.find(self.participant_id)
    else
      raise 'unimplemented'
    end
  end

  def roster
    if self[:roster].nil?
      tr = self.the_real_thing
      self.roster = tr.competition_roster ? tr.competition_roster : 'images/default_avatar.jpg'
      self.save
    end
    self[:roster]
  end

  # Devuelve todos los usuarios relacionados con este participante
  def users
    if self.competitions_participants_type_id == Competition::USERS
      [self.the_real_thing]
    elsif self.competitions_participants_type_id == Competition::CLANS
      self.the_real_thing.members_of_game(self.competition.game)
    else raise 'unimplemented'
    end
  end
end

# Este módulo contiene clases y métodos para gestión de competiciones
module Competitions
  def self.participants_of_user(u, competition_cls=nil)
    clans = Clan.leaded_by(u.id)
    clans_ids = [0]
    clans.each { |clan| clans_ids<< clan.id }
    q_type = competition_cls ? " AND type = '#{competition_cls}'" : ''
    CompetitionsParticipant.find(:all, :conditions => "competition_id IN (SELECT id
                                                                            FROM competitions
                                                                           WHERE state = 3#{q_type})
                                                   AND ((participant_id = #{u.id}
                                                         AND competitions_participants_type_id = #{Competition::USERS})
                                                     OR (participant_id IN (#{clans_ids.join(',')})
                                                         AND competitions_participants_type_id = #{Competition::CLANS}))")
  end

  def self.k_factor(participant)
    if participant.wins + participant.losses + participant.ties < 16 then
      128
    elsif participant.points < 2100 then
      64
    elsif participant.points < 2800 then
      32
    else
      15
    end
  end


  def self.recalculate_points(competition)
    # TODO esto también se hace en competitions_match.
    # TODO recalcular wins, ties y losses
    competition.db_query("UPDATE competitions_participants SET points = 1000 WHERE competition_id = #{competition.id}")
    points = {}
    for m in competition.matches(:completed, :order => 'completed_on ASC')
      m.update_ladder_points
      points[m.participant1_id] ||= {:wins => 0, :ties => 0, :losses => 0}
      points[m.participant2_id] ||= {:wins => 0, :ties => 0, :losses => 0}

      case m.result
        when CompetitionsMatch::P1_WINS:
        points[m.participant1_id][:wins] += 1
        points[m.participant2_id][:losses] += 1
        when CompetitionsMatch::TIE:
        df = (m.forfeit_participant1 && m.forfeit_participant2) ? :losses : :ties
        points[m.participant1_id][df] += 1
        points[m.participant2_id][df] += 1
        when CompetitionsMatch::P2_WINS:
        points[m.participant1_id][:losses] += 1
        points[m.participant2_id][:wins] += 1
      end
    end

    points.keys.each do |k|
      cp = CompetitionsParticipant.find(k)
      cp.wins = points[k][:wins]
      cp.ties = points[k][:ties]
      cp.losses = points[k][:losses]
      cp.save
    end
  end

  def self.trophies_for_user(u)
    # coger todas las competiciones donde ha participado que esten cerradas y ver los winners
    trophies = []
    Competition.related_with_user(u).find(:all, :conditions => "(state = #{Competition::CLOSED}) OR (type = 'Ladder' AND state = #{Competition::STARTED})", :order => 'lower(name)').each do |c|
      #p c
      participant = c.get_active_participant_for_user(u)
      next if participant.nil?
      # p c.winners(e)
      idx = c.winners(3).collect {|cwn| cwn.id }.index(participant.id)
      if idx
        trophies << [idx, c]
      end
    end
    trophies
  end

  def self.trophies_for_clan(u)
    # coger todas las competiciones donde ha participado que esten cerradas y ver los winners
    trophies = []
    Competition.related_with_clan(u).find(:all, :conditions => "(state = #{Competition::CLOSED}) OR (type = 'Ladder' AND state = #{Competition::STARTED})").each do |c|
      #p c
      participant = c.get_active_participant_for_clan(u)
      next if participant.nil?
      # p c.winners(e)
      idx = c.winners(3).collect {|cwn| cwn.id }.index(participant.id)
      if idx
        trophies << [idx, c]
      end
    end
    trophies
  end

  def self.find_all_matches_from_user(user, conditions=nil, limit=:all)
    participant_ids = [0]
    Competition.related_with_user(user).find(:all, :order => 'lower(name)').each do |c|
      participant = c.get_active_participant_for_user(user)
      participant_ids<< participant.id if participant # TODO si un usuario pertenece a más de un clan apuntado al mismo torneo esto no será correcto
    end
    q_cond = conditions ? "AND #{conditions}" : ''
    CompetitionsMatch.find(:all, :conditions => "(participant1_id IN (#{participant_ids.join(',')}) or participant2_id IN (#{participant_ids.join(',')})) #{q_cond}", :order => 'completed_on DESC', :limit => limit, :include => :competition)
  end

  def self.find_all_matches_from_clan(clan, conditions=nil, limit=:all)
    participant_ids = User.db_query("SELECT id FROM competitions_participants WHERE participant_id = #{clan.id} AND competition_id IN (SELECT id FROM competitions WHERE competitions_participants_type_id = #{Competition::CLANS})").collect {|dbr| dbr['id'].to_i }
    q_cond = conditions ? "AND #{conditions}" : ''
    if participant_ids.size > 0
      CompetitionsMatch.find(:all, :conditions => "(participant1_id IN (#{participant_ids.join(',')}) or participant2_id IN (#{participant_ids.join(',')})) #{q_cond}", :order => 'completed_on DESC', :limit => limit, :include => :competition)
    else
      []
    end
  end

  def self.count_all_matches_from_user(user, conditions=nil)
    # TODO refactor with upper
    participant_ids = [0]
    Competition.related_with_user(user).find(:all, :order => 'lower(name)').each do |c|
      participant = c.get_active_participant_for_user(user)
      participant_ids<< participant.id if participant # TODO si un usuario pertenece a más de un clan apuntado al mismo torneo esto no será correcto
    end
    q_cond = conditions ? "AND #{conditions}" : ''
    CompetitionsMatch.count(:conditions => "(participant1_id IN (#{participant_ids.join(',')}) or participant2_id IN (#{participant_ids.join(',')})) #{q_cond}")
  end

  # Esta clase la utilizamos por comodidad para operar en las vistas de cara al
  # usuario en torneos con ronda clasificatoria
  class TourneyClassifierRound
    def self.find_by_match(cm)
      competition = cm.competition
      # TODO slow
      for g in competition.tourney_classifier_groups
        for cm2 in g.matches
          if cm.id == cm2.id then
            return g # ortodoxo? hawhaw
          end
        end
      end
    end

    attr_accessor :group_id

    def initialize(competition, id)
      @competition = competition
      @group_id = id
      @groups_count = @competition.competitions_types_options[:tourney_groups].to_i
    end

    def participants
      if @groups_count.nil? or @groups_count == 0
        Rails.logger.warn("@groups_count nil or 0, setting to 1")
        @groups_count = 1
      end
      participants = {}
      i = 0
      for p in @competition.competitions_participants.find(:all, :select => '*, (wins * 2 + ties) as points', :order => 'position ASC')
        participants[p.points.to_i * 100000 + p.id] = p if  i % @groups_count == @group_id
        i += 1
      end
      participants_final = []
      participants.keys.sort.reverse.each { |k| participants_final<< participants[k] }
      participants_final
    end

    def matches
      participants_ids = [0] # para casos que no tenga todavía participantes
      for p in self.participants
        participants_ids<< p.id
      end
      # max_stage = @competition.competitions_matches.find(:first, :order => 'stage DESC')
      # TODO cuando generemos las partidas de ronda eliminatoria aquí hay que poner stage < primera_ronda_de_eliminatorias
      @competition.competitions_matches.find(:all,
                                             :conditions => " stage < #{@competition.tourney_rounds_starting_stage}
                                                       AND (participant1_id IN (#{participants_ids.join(',')})
                                                         OR participant2_id IN (#{participants_ids.join(',')}))",
      :order => 'stage ASC')
    end

    def completed?
      participants_ids = []
      for p in self.participants
        participants_ids<< p.id
      end
      # TODO cuando generemos las partidas de ronda eliminatoria aquí hay que poner stage < primera_ronda_de_eliminatorias
      @competition.competitions_matches.find(:all,
                                             :conditions => " stage < #{@competition.tourney_rounds_starting_stage}
                                                       AND (participant1_id IN (#{participants_ids.join(',')})
                                                         OR participant2_id IN (#{participants_ids.join(',')}))
                                                       AND NOT (#{Competition::COMPLETED_ON_SQL})",
      :order => 'stage ASC').size > 0 ? false : true
    end

    def to_s
      "#{@group_id + 1}"
    end
  end



  # Clase helper para calcular las fechas a asignar a las partidas
  class CompetitionsDay
    TIME_PER_MATCH = 60 unless defined? TIME_PER_MATCH # mins

    attr_accessor :date, :slots_used

    # solo se llamará a initialize para el primer día. Para el resto de días
    # clonaremos el objeto y le modificaremos los atributos.
    def initialize(options)
      @date = Time.local(options[:starts_on_year], options[:starts_on_month], options[:starts_on_day])
      @time_start_weekend_hours = (options[:time_start_weekend_hours].to_i == 0) ? 24 : options[:time_start_weekend_hours].to_i
      @time_start_weekend_minutes = options[:time_start_weekend_minutes].to_i
      @time_end_weekend_hours = (options[:time_end_weekend_hours].to_i == 0) ? 24 : options[:time_end_weekend_hours].to_i
      @time_end_weekend_minutes = options[:time_end_weekend_minutes].to_i

      if @time_start_weekend_hours > @time_end_weekend_hours then
        t_end = @time_end_weekend_hours
        @time_end_weekend_hours = @time_start_weekend_hours
        @time_start_weekend_hours = t_end
        @time_end_weekend_minutes = @time_start_weekend_minutes
        @time_start_weekend_minutes = t_end
      end


      @time_start_week_hours = (options[:time_start_week_hours].to_i == 0) ? 24 : options[:time_start_week_hours].to_i
      @time_start_week_minutes = options[:time_start_week_minutes].to_i
      @time_end_week_hours = (options[:time_end_week_hours].to_i == 0) ? 24 : options[:time_end_week_hours].to_i
      @time_end_week_minutes = options[:time_end_week_minutes].to_i

      if @time_start_week_hours > @time_end_week_hours then
        t_end = @time_end_week_hours
        @time_end_week_hours = @time_start_week_hours
        @time_start_week_hours = t_end
        @time_end_week_minutes = @time_start_week_minutes
        @time_start_week_minutes = t_end
      end

      @max_matches_per_day = options[:max_matches_per_day].to_i

      @allowed_dows = []
      7.times do |time|
        @allowed_dows<< time if options["dow_#{time}".to_sym]
      end

      recalculate
    end

    def recalculate
      # calculo máximo de posibles matches para hoy
      if [0,6].include?(@date.strftime('%w').to_i) then
        @timespan = @time_end_weekend_hours * 60 + @time_end_weekend_minutes - @time_start_weekend_hours * 60 - @time_start_weekend_minutes
      else
        @timespan = @time_end_week_hours * 60 + @time_end_week_minutes - @time_start_week_hours * 60 - @time_start_week_minutes
      end

      @max_matches = @timespan / TIME_PER_MATCH
      @max_matches = @max_matches_per_day if @max_matches_per_day < @max_matches # nos quedamos con el más pequeño
      @slots_used = 0
    end

    def full?
      @slots_used >= @max_matches
    end

    def <<(competitions_match)
      # time_offset es el tiempo transcurrido desde time_start
      if [0,6].include?(@date.strftime('%w').to_i) then
        # puts "añadiendo a weekend"
        time_offset = @time_start_weekend_hours * 60 + @time_start_weekend_minutes + @slots_used * TIME_PER_MATCH
      else
        # puts "añadiendo a week"
        time_offset = @time_start_week_hours * 60 + @time_start_week_minutes + @slots_used * TIME_PER_MATCH
      end
      # puts "<< with time offset #{time_offset}"
      competitions_match.play_on = Time.at(Time.local(@date.year, @date.month, @date.day).to_i + time_offset * 60) #time_offset está en min
      competitions_match.save
      @slots_used += 1
    end

    def next
      # hacemos este berenjenal para evitar problema de leap seconds y cambios de mes/año
      tmp = @date.to_i + 86400
      while ! @allowed_dows.include?(Time.at(tmp).strftime('%w').to_i) # buscamos el siguiente día de la semana que tengamos permitido
        tmp += 86400
      end
      tmp = Time.at(tmp)

      next_day = self.clone # clonamos para no perder las variables de la instancia y no tener que pasárselas al constructor
      next_day.date = Time.local(tmp.year, tmp.month, tmp.day)
      next_day.slots_used = 0
      next_day.recalculate
      next_day
    end
  end

  def self.update_user_competitions_indicators
    users_on = [0]
    clans_added = []
    # actualizamos indicadores de competiciones
    # Calculamos usuarios a avisar por retos no aceptados
    for m in CompetitionsMatch.find(:all, :conditions => 'accepted = \'f\'', :include => :participant2)
      if m.participant2.competitions_participants_type_id == 2 and not clans_added.include?(m.participant2.participant_id)
        c = Clan.find(m.participant2.participant_id)
        c.admins.each do |user|
          users_on<< user.id unless users_on.include?(user.id)
        end
        clans_added<< c.id
      elsif m.participant2.competitions_participants_type_id == 1
        users_on<< m.participant2.participant_id
      end
    end

    # Calculamos usuarios a avisar por retos no cerrados cuya fecha de cierre ya ha pasado
    for m in CompetitionsMatch.find(:all, :conditions => "play_on < now() and (accepted = 't' and not #{Competition::COMPLETED_ON_SQL})", :include => [:participant1, :participant2])
      # participant1
      if m.participant1.competitions_participants_type_id == 2 then
        if not clans_added.include?(m.participant1.participant_id)
          c = Clan.find(m.participant1.participant_id)
          c.admins.each do |user|
            users_on<< user.id unless users_on.include?(user.id)
          end
          clans_added<< c.id
        end

        # participant2
        if not clans_added.include?(m.participant2.participant_id)
          c = Clan.find(m.participant2.participant_id)
          c.admins.each do |user|
            users_on<< user.id unless users_on.include?(user.id)
          end
          clans_added<< c.id
        end
      elsif m.participant2.competitions_participants_type_id == 1
        users_on<< m.participant1.participant_id
        users_on<< m.participant2.participant_id
      end
    end

    User.db_query("UPDATE users SET enable_competition_indicator = 't' WHERE id IN (#{users_on.uniq.join(',')}) AND enable_competition_indicator = 'f'")
  end
end

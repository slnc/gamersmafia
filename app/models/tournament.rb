class Tournament < Competition
  def has_options?
    true
  end
  
  def winners(limit=nil)
    self.competitions_participants.find(:all, :conditions => 'wins > 0 or losses > 0 or ties > 0', :order => '(wins * 3 + ties * 1 + losses * 0) DESC, lower(name) ASC', :limit => limit)
  end
  
  def reset_match(cm)
    # se encarga de asegurarse que se deshacen los pasos adecuados después de deshacer una partida cerrada
    # TODO
    if match_stage_is_tourney_rounds_stage?(cm.stage)
      # es partida de fase de árbol
      next_cm = self.get_next_match(cm)
      if next_cm
        # reseteamos la siguiente partida
        self.reset_tourney_match(next_cm)
        next_cm.reload
        # ponemos en blanco el participante de la siguiente partida
        if self.winner_of_tourney_rounds_match_is_participant1?(cm)
          next_cm.participant1_id = nil # TODO no puede ser empate
        else
          next_cm.participant2_id = nil # TODO no puede ser empate
        end
        next_cm.save
      end
    elsif match_stage_is_group_stage?(cm.stage) 
      # si todas las partidas del grupo están completas cogemos a los ganadores
      # y los movemos a la fase de eliminatorias
      g = Competitions::TourneyClassifierRound.find_by_match(cm)
      
      if g.completed?
        # reseteamos todas las partidas de fase árbol ya que el resultado podría estar cambiando quiénes pasan y quienes no a la siguiente fase
        self.competitions_matches.find(:all, :conditions => "stage = #{self.tourney_rounds_starting_stage}", :order => 'id ASC').each do |next_cm|
          self.reset_match(next_cm) # ya se llamará de forma recursiva a las demás partidas
          next_cm.reload
          next_cm.participant1_id = nil
          next_cm.participant2_id = nil
          next_cm.save
        end
      end
    end
    super # reseteamos la partida actual
  end
  
  def winner_of_tourney_rounds_match_is_participant1?(cm)
    prev = self.competitions_matches.count(:conditions => ['stage = ? and id < ?', cm.stage, cm.id])
    
    is_participant1 = (prev % 4 < 2) ? true : false
    #puts "prev: #{prev} #{is_participant1}"
    # TODO hack, arreglar esto
    if self.tourney_rounds_starting_stage > 0 then
      #puts "here"
      is_participant1 = true if (prev % 4 < 2 && cm.stage > self.total_tourney_rounds + self.tourney_rounds_starting_stage - 2) #  la comprobación de stage es para la semifinal
    else
      #puts "horo"
      is_participant1 = true if (prev % 4 < 2 && cm.stage > self.total_tourney_rounds + self.tourney_rounds_starting_stage - 2) #  la comprobación de stage es para la semifinal
    end
    is_participant1 = false if cm.stage == self.total_tourney_rounds - 2 && prev == 1 # para la semifinal del lado derecho
    #puts "final_value: #{is_participant1}"
    is_participant1
  end
  
  def get_next_match(cm)
    prev = self.competitions_matches.count(:conditions => ['stage = ? and id < ?', cm.stage, cm.id])
    next_round_pos = prev / 2 - (prev / 2) % 2
    next_round_pos += 1 if prev % 2 == 1
    # TODO hack
    next_round_pos = 0 if cm.stage == self.total_tourney_rounds - 2 # el algoritmo falla para la semifinal del lado derecho
    
    next_cm = competitions_matches.find(:all, :conditions => "stage = #{cm.stage + 1}", :order => 'id ASC', :limit => 1, :offset => next_round_pos)
    # raise "cannot find next match for #{cm.id}" unless next_cm.size == 1
    next_cm.size > 0 ? next_cm[0] : nil
  end
  
  def match_stage_is_group_stage?(stage)
    self.competitions_types_options[:tourney_use_classifiers] &&
    stage < self.tourney_rounds_starting_stage
  end
  
  def match_stage_is_tourney_rounds_stage?(stage)
    # si la partida es de fase de rounds
    # TODO la segunda condición no la entiendo, es para un caso crítico?
    stage >= self.tourney_rounds_starting_stage
  end
  
  def is_final?(cm)
    # puts "#{cm.stage} == #{self.total_tourney_rounds} + #{self.tourney_rounds_starting_stage} - 1"
    cm.stage == self.total_tourney_rounds - 1
  end
  
  def match_completed(cm)
    if match_stage_is_tourney_rounds_stage?(cm.stage) && !self.is_final?(cm)
      # puts "completing tree stage match (stage: #{cm.stage}  |starting_stage: #{self.tourney_rounds_starting_stage}"
      # p cm
      # es partida de fase de árbol
      is_participant1 = self.winner_of_tourney_rounds_match_is_participant1?(cm) 
      next_cm = self.get_next_match(cm)
      return if next_cm.nil? && self.is_final?(cm)
      if is_participant1 then
        #puts "changing next_cm.participant1_id"
        next_cm.participant1_id = cm.winner.id # TODO no puede ser empate
      else
        #puts "changing next_cm.participant2_id"
        next_cm.participant2_id = cm.winner.id # TODO no puede ser empate
      end
      
      #p next_cm
      next_cm.save
      #puts "\n"
    elsif match_stage_is_group_stage?(cm.stage) 
      # si todas las partidas del grupo están completas cogemos a los ganadores
      # y los movemos a la fase de eliminatorias
      g = Competitions::TourneyClassifierRound.find_by_match(cm)
      
      if g.completed?
        # es la última partida del grupo
        participants = g.participants
        self.competitions_types_options[:tourney_classifiers_rounds].to_i.times do |i|
          if i % 2 == 0 then
            # los primeros van todos por separado
            offset = g.group_id # TODO ahora mismo solo soportamos 2 ganadores por grupo
            is_participant2 = false
            newcm = self.competitions_matches.find(:all, :conditions => "stage = #{self.tourney_rounds_starting_stage}", :order => 'id ASC', :limit => 1, :offset => offset)
          else
            # los segundos van a la inversa
            is_participant2 = true
            offset = g.group_id # lo mandamos a la otra rama
            newcm = self.competitions_matches.find(:all, :conditions => "stage = #{self.tourney_rounds_starting_stage}", :order => 'id DESC', :limit => 1, :offset => offset)
            # offset = g.group_id / 2 + g.group
          end
          newcm = newcm[0]
          if is_participant2 then
            newcm.participant2_id = participants[i].id
          else
            newcm.participant1_id = participants[i].id
          end
          newcm.save
        end
      end
    end
  end
end

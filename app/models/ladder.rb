class Ladder < Competition
  def has_options?
    false
  end
  
  VALID_CHALLENGE_OPTIONS = [:play_on, :servers, :maps, :ladder_rules]
  # challenger challenges challengee. Returns the competition match
  def challenge(challenger, challengee, options={})
    raise "Imposible crear reto en la fase actual de la ladder" unless self.kind_of?(Ladder) && state == Competition::STARTED
    
    if matches(:unapproved, :participants => [challenger, challengee]).size > 0 
      raise "Tienes un reto pendiente de ser aceptado por este participante"
    elsif matches(:result_pending, :participants => [challenger, challengee]).size > 0
      raise "Tienes un reto pendiente de confirmar su resultado contra este participante"
    else
      cm = competitions_matches.create({:participant1_id => challenger.id, :participant2_id => challengee.id, :accepted => false, :play_on => options[:play_on], :servers => options[:servers], :ladder_rules => options[:ladder_rules], :maps => default_maps_per_match})
      if options[:play_maps] && default_maps_per_match > 0
        options[:play_maps].each do |k,game_map_id|
          next unless game_map_id.to_i != 0
          cm.competitions_matches_games_maps.create({:games_map_id => game_map_id})
        end
      end
      log("#{challenger.name} reta a #{challengee.name}")
      Notification.send("deliver_reto_recibido", challengee.the_real_thing, { :participant => challenger})
      cm
    end
  end
end

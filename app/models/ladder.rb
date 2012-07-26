# -*- encoding : utf-8 -*-
class Ladder < Competition
  VALID_CHALLENGE_OPTIONS = [:play_on, :servers, :maps, :ladder_rules]

  def self.check_ladder_matches
    # 1 week old and still unaccepted
    Ladder.find(:all, :conditions => ['state = ?', Competition::STARTED]).each do |l|
      l.matches(:unapproved, :conditions => 'accepted is false and updated_on < now() - \'1 week\'::interval and updated_on > now() - \'3 weeks\'::interval').each do |m|
        rt = m.participant2.the_real_thing
        if rt.class.name == 'User'
          recipients = [rt]
        else
          recipients = rt.admins
        end

        recipients.each do |u|
          Notification.reto_pendiente_1w(
              u, {:match => m, :participant => m.participant2}).deliver
        end
      end

      # 3 weeks old and still unaccepted, 2 warning
      l.matches(:unapproved, :conditions => 'accepted is false and updated_on < now() - \'3 weeks\'::interval and updated_on > now() - \'1 month\'::interval').each do |m|
        rt = m.participant2.the_real_thing
        if rt.class.name == 'User'
          recipients = [rt]
        else
          recipients = rt.admins
        end

        recipients.each do |u|
          # TODO(slnc): temporalmente deshabilitado
          # Notification.deliver_reto_pendiente_2w(u, {:match => m, :participant => m.participant2})
        end
      end


      # cancel older challenges
      l.matches(:unapproved, :conditions => 'accepted is false and updated_on < now() - \'1 month\'::interval').each do |m|
        rt = m.participant2.the_real_thing
        if rt.class.name == 'User'
          recipients = [rt]
        else
          recipients = rt.admins
        end

        recipients.each do |u|
          Notification.reto_cancelado_sin_respuesta(
              u, {:match => m, :participant => m.participant2}).deliver
        end
        m.destroy
      end

      # automatically accept unconfirmed results if older than a month
      l.matches(:result_pending, :conditions => 'updated_on < now() - \'1 month\'::interval').each do |m|
        if !(m.participant1_confirmed_result && m.participant2_confirmed_result) then # double forfeit
          m.complete_match(Ias.MrMan, {}, true)
        else # accept result
          rt = m.participant2.the_real_thing
          if rt.class.name == 'User'
            recipients = [rt]
          else
            recipients = rt.admins
          end

          recipients.each do |u|
            # TODO(slnc): deberíamos habilitar esto de nuevo?
            #Notification.reto_cancelado_sin_respuesta(u, {:match => m, :participant => m.participant2})
          end
          m.complete_match(Ias.MrMan, {}, true)
        end

      end
    end
  end

  def has_options?
    false
  end

  # challenger challenges challengee. Returns the competition match
  def challenge(challenger, challengee, options={})
    if !(self.kind_of?(Ladder) && state == Competition::STARTED)
      raise "Imposible crear reto en la fase actual de la ladder"
    end

    if matches(:unapproved, :participants => [challenger, challengee]).size > 0
      raise "Tienes un reto pendiente de ser aceptado por este participante"
    elsif matches(:result_pending,
                  :participants => [challenger, challengee]).size > 0
      raise ("Tienes un reto pendiente de confirmar su resultado contra este" +
             " participante")
    else
      cm = competitions_matches.create({
        :participant1_id => challenger.id,
        :participant2_id => challengee.id,
        :accepted => false,
        :play_on => options[:play_on],
        :servers => options[:servers],
        :ladder_rules => options[:ladder_rules],
        :maps => default_maps_per_match,
      })
      if options[:play_maps] && default_maps_per_match > 0
        options[:play_maps].each do |k,game_map_id|
          next unless game_map_id.to_i != 0
          cm.competitions_matches_games_maps.create(
            :games_map_id => game_map_id)
        end
      end
      log("#{challenger.name} reta a #{challengee.name}")
      Notification.reto_recibido(
        challengee.the_real_thing, { :participant => challenger}).deliver
      cm
    end
  end
end

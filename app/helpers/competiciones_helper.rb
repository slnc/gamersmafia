# -*- encoding : utf-8 -*-
module CompeticionesHelper
  def match_vs_name(match, left_participant=nil, with_links=false)
    if match.participant1_id then
      if with_links
        p1_name = "<a href=\"/competiciones\/participante\/#{match.participant1_id}\">#{notags(match.participant1.name)}</a>"
      else
        p1_name = notags(match.participant1.name)
      end
      if match.completed? and match.result == 2 then
        p1 = "<span style=\"text-decoration: line-through;\">#{p1_name}</span>"
      else
        p1 = "#{p1_name}"
      end
    else
      p1 = ' '
    end

    if match.participant2_id then
      if with_links
        p2_name = "<a href=\"/competiciones\/participante\/#{match.participant2_id}\">#{notags(match.participant2.name)}</a>"
      else
        p2_name = notags(match.participant2.name)
      end
      if match.completed? and match.result == 0 then
        p2 = "<span style=\"text-decoration: line-through;\">#{p2_name}</span>"
      else
        p2 = "#{p2_name}"
      end
    else
      p2 = ' '
    end

    if left_participant and match.participant2_id == left_participant.id then
      "#{p2} | #{p1}"
    else
      "#{p1} - #{p2}"
    end
  end

  def match_vs_name_tourney(competition, stage, pos)
    # buscamos el match correspondiente
    cm = competition.competitions_matches.find(:first, :conditions => ['stage = ?', stage], :order => "id ASC", :offset => pos)
    if cm then
      "<a href=\"/competiciones/partida/#{cm.id}\">#{match_vs_name(cm)}</a>"
    end
  end

  def participant_roster(p)
    p.roster ? fc_thumbnail(p.roster, 'f', '50x50', false) : '<img class="avatar" src="/images/default_avatar.jpg" />'
  end

  def competition_progress(c)
    total_matches = c.competitions_matches.count
    pc = c.matches(:completed, :count => true) / total_matches.to_f
    draw_pcent_bar(pc)
  end

  def ladder_activity(c)
    total_players = c.competitions_participants.count # TODO cambiar por competitions_participants ACTIVOS
    recent_matches = c.competitions_matches.count(:conditions => 'completed_on > now() - \'1 month\'::interval or created_on > now() - \'1 month\'::interval')
    total_players = 1 if total_players == 0
    pc = recent_matches / total_players.to_f
    pc = 1.0 if pc > 1.0
    if pc > 0.80 then offset = 40
    elsif pc > 0.60 then offset = 30
    elsif pc > 0.40 then offset = 20
    elsif pc > 0.20 then offset = 10
    else offset = 0
    end

    "<img class=\"competition-progress\" src=\"/images/blank.gif\" style=\"background-position: 0 -#{offset}px;\" />"
  end
end

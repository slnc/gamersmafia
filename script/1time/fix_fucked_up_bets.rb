\'October Red Cup II: ambolias vs HFRKT\',
\'3º y 4º Puesto November Cup 5on5: born2kill vs 1Gen\', \'TDM 2on2 Hand to Hand Tunisia: foxhole vs born2kill\',
\'TDM 2on2 Hand to Hand Tunisia: Que paha vs South SIAD\',
\'TDM 2on2 Hand to Hand Tunisia: Withluck vs tryAGAIN\',
\'CoD4 SD 5on5 Ladder: Quick Combat by CBE vs eScuadron Suicida\',
\'Liga BBVA: FC Barcelona - Real Madrid\',
\'UEFA Champions League: FC Barcelona - FC Internazionale Milano\',
\'Final November Cup 5on5: FoxHole vs SIAD Release\',
\'November Cup: limite vs UNDERSCORE\',
\'November Cup 5on5: SIAD Gamers vs FoxHole\',
\'November Cup 5on5: SIAD Release vs born2kill\',
\'November Cup 5on5: SIAD Release vs BuLLetS\',
\'November Cup 5on5: Underscore vs born2kill\',
\'November Cup 5on5: 1Gen vs FoxHole\',
\'November Cup 5on5: SIAD Gamers vs FoxHole\',
\'November Cup: SIAD G vs Night Stalkers\',
\'November Cup: SIAD R vs Fake Death\',
\'November Cup: Banned vs FoxHole\',
\'Barclays Premier League: Chelsea vs Manchester United\',
\'Liga S&D 5on5 ESL II: 4gOds vs SpN\',
\'Liga S&D 5on5 ESL II: CEB vs born2kill\',
\'Final Autumn League: SUBLIMINAL vs.HFRKT\',
\'TDM 2on2 Hand to Hand Tunisia: foxhole vs born2kill\',
\'TDM 2on2 Hand to Hand Tunisia: Macdonald vs Dai-Gurren\',
\'TDM 2on2 Hand to Hand Tunisia: eCore i7 vs noisee\',
\'OpenCup New Vision Fall 2009: maver vs Sexy Generation\',
\'Liga BBVA - Jornada 12º - F.C. Barcelona vs Real Madrid C.F. \',
\'Liga BBVA: FC Barcelona - Real Madrid\',
\'Liga S&D 5on5 ESL II: 1Gen vs SIAD Release\',
\'Final November Cup 5on5: FoxHole vs SIAD Release\',
\'Final i38: dignitas vs fnaticMSi.MW2\'

Bet.find(:all, :conditions => 'title IN (
\'3º y 4º Puesto November Cup 5on5: born2kill vs 1Gen\',
\'Liga S&D 5on5 ESL II: 1Gen vs SIAD Release\',
\'November Cup 5on5: 1Gen vs FoxHole\',
\'October Red Cup II: ambolias vs HFRKT\',
\'3º y 4º Puesto November Cup 5on5: born2kill vs 1Gen\',
\'November Cup 5on5: Underscore vs born2kill\', \'TDM 2on2 Hand to Hand Tunisia: foxhole vs born2kill\', \'CoD4 SD 5on5 Ladder: Quick Combat by CBE vs eScuadron Suicida\', \'Liga BBVA - Jornada 12º - F.C. Barcelona vs Real Madrid C.F.\', \'UEFA Champions League: FC Barcelona - FC Internazionale Milano\', \'Final November Cup 5on5: FoxHole vs SIAD Release\', \'November Cup: Banned vs FoxHole\', \'November Cup: SIAD G vs Night Stalkers\', \'November Cup: SIAD G vs Night Stalkers\', \'November Cup: SIAD R vs Fake Death\', \'November Cup 5on5: 1Gen vs FoxHole\',
\'November Cup 5on5: SIAD Gamers vs FoxHole\',
\'November Cup 5on5: SIAD Release vs born2kill\',
\'November Cup 5on5: SIAD Release vs BuLLetS\',
\'November Cup 5on5: Underscore vs born2kill\',
\'November Cup: limite vs UNDERSCORE\',
\'Final Autumn League: SUBLIMINAL vs.HFRKT\',
\'OpenCup New Vision Fall 2009: maver vs Sexy Generation\',
\'Liga BBVA - Jornada 12º - F.C. Barcelona vs Real Madrid C.F. \',
\'Final November Cup 5on5: FoxHole vs SIAD Release\',
\'Liga S&D 5on5 ESL II: 1Gen vs SIAD Release\',
\'Final Autumn League: SUBLIMINAL vs.HFRKT\',
\'Final i38: dignitas vs fnaticMSi.MW2\',
\'TDM 2on2 Hand to Hand Tunisia: Que paha vs South SIAD\',
\'TDM 2on2 Hand to Hand Tunisia: eCore i7 vs noisee\',
\'TDM 2on2 Hand to Hand Tunisia: foxhole vs born2kill\',
\'TDM 2on2 Hand to Hand Tunisia: Macdonald vs Dai-Gurren\',
\'TDM 2on2 Hand to Hand Tunisia: Withluck vs tryAGAIN\')
').each do |bet|
  next if bet.closed?

  puts "bet: #{bet.id}"
  if bet.forfeit
    result = 'forfeit'
  elsif bet.tie
    result = 'tie'
  elsif bet.cancelled
    result = 'cancelled'
  else
    result = bet.winning_bets_option_id
  end
  
  # bet.reopen

  bet.bets_options.each do |bets_option|
      [23086, 41842, 48767, 39723].each do |uid|
        ticket = bets_option.bets_tickets.find_by_user_id(uid)
        if ticket && ticket.ammount > 0
          puts "updated ticket #{ticket.id} (uid: #{uid}) (ammount: #{ticket.ammount}"
          ticket.update_ammount(0.0)
        end
      end
  end
  
  # puts "bet.complete(#{result})"
  # bet.complete(result)
  # puts "#{bet.id}, #{bet.closed?}"
end

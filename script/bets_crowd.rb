#require File.dirname(__FILE__) + '/../config/boot'

total_bets = 0
crowd_wins = 0
users_totals = {}
users_wins = {}

Bet.published.closed_bets.find(
    :all, :conditions => "cancelled <> 't' and forfeit <> 't'").each do |bet|
  total_bets += 1
  out = bet.determine_crowd_decision
  crowd_decision = out[0]
  winners = out[1]
  user_votes = out[2]
  user_votes.each do |k,v|
    users_totals[k] ||= 0
    users_totals[k] += 1
  end
  winners.each do |user_id|
    users_wins[user_id] ||= 0
    users_wins[user_id] += 1
  end
  puts "crowd_decision: #{crowd_decision} | result: #{bet.winning_bets_option_id} | tie: #{bet.tie?}"
  if bet.tie and crowd_decision == Bet::TIE
    crowd_wins += 1
  elsif bet.winning_bets_option_id == crowd_decision
    crowd_wins += 1
  end
end and nil

puts "Crowd"
puts "#{1.0*crowd_wins/total_bets}(#{crowd_wins}/#{total_bets})"

puts "\n\n"
users_pcent = {}
users_total.each do |u,k|
  users_pcent[u] = k
end

users_wins.each do |u, k|
  users_pcent[u] = k / users_pcent[u]
end

(users_totals.keys - users_wins.keys).each do |loser_user|
  users_pcent[loser_user] = 0.0
end

puts users_pcent

#!/usr/bin/env ruby
if !defined?(App) # necesario para cuando cargamos el script con load desde los tests
  defined? ENV['RAILS_ENV'] ? RAILS_ENV = ENV['RAILS_ENV'] : 'production' # necesario para testing
  require File.dirname(__FILE__) + '/../../config/environment'
end

# karma generated, users_total
# start date
d = Content.find(:first, :conditions => "id = (SELECT id FROM contents WHERE created_on = (SELECT min(created_on) FROM contents))").created_on

twodaysago = 2.days.ago
while d < twodaysago
  sum_for_day = 0
  d_str = d.strftime('%Y-%m-%d 00:00:00')
  #puts d_str
  Content.find(:all, :conditions => "state = 2 AND date_trunc('day', created_on) = '#{d_str}'").each do |c| # contenidos publicados en ese día
    rc = c.real_content
    sum_for_day += Karma::KPS_CREATE[rc.class.name]
    sum_for_day += Karma::KPS_SAVE[rc.class.name] if rc.respond_to? :approved_by_user_id and rc.approved_by_user_id
  end

  sum_for_day += Karma::KPS_CREATE['Comment'] * Comment.count(:conditions => "date_trunc('day', created_on) = '#{d_str}'")

  if User.db_query("SELECT karma_diff FROM stats.global WHERE created_on = '#{d_str}'").size == 0 then
    User.db_query("INSERT INTO stats.global(created_on, karma_diff) VALUES('#{d_str}', #{sum_for_day})")
  else
    User.db_query("UPDATE stats.global SET karma_diff = #{sum_for_day} WHERE created_on = '#{d_str}'")
  end
  d = d.advance :days => 1
end

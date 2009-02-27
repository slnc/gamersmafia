module Reports
  extend ActionViewMixings
  def self.send_mrachmed_dominical
    include ActionView
    # envía una noticia semanal con información varia
    
    # emblemas
    last_ue = UsersEmblem.find(:first, :order => 'id DESC', :limit => 1)
    raise "imposible, no hay emblemas!" unless last_ue
    cur_date = last_ue.created_on
    base = 'Buenas queridos. Los emblemas de esta semana han sido otorgados a los siguientes mafiosos:<br><br><br><table>'
    %w(best_overall karma_fury faith_avalanche most_knowledgeable living_legend funniest profoundest most_informational most_interesting wealthiest okupa bets_master talker best_blogger).each do |emblema|
      ues = UsersEmblem.find(:all, :conditions => ["created_on = ? AND emblem = ?", cur_date, emblema])
      if ues.size > 0
        base << "<tr class=\"#{oddclass}\"><td class=\"w150\"><img class=\"emblema emblema-#{emblema}\" src=\"/images/blank.gif\" /> #{Emblems::EMBLEMS[emblema.to_sym][:title]}</td> <td><strong>"
        base << ues.collect { |ue| "<a href=\"#{ApplicationController.gmurl(ue.user)}\">#{ue.user.login}</a>" }.join(', ')
        base << "</strong></td><td>#{ues[0].details}</td></tr>\n"
      end
    end
    base<< "</table>\n"
    
    virgins = ["Oh, sigo buscando novia. Si alguna mujer joven está interesada por favor que me mande un mensaje privado.", 
               'Soy una persona muy sensible, no me gustaría leer críticas negativas.',
               '¿Está todo bien?',
               'Un tal gr3333n me ha confesado que le gustan los chicos.',
               'Mi psicólogo me ha dicho que hacer esto me ayudará.']
    main = "#{virgins.random}"
    
    dbn = User.db_query("select (select login from users where id = user_id_from) as login from messages where user_id_to = (select id from users where login='nagato') and created_on >= now() - '1 week'::interval group by (select login from users where id = user_id_from) order by count(*) desc limit 1")
    if dbn.size > 0 then      
      main << "<br /><br />Por cierto, <a href=\"/miembros/#{dbn[0]['login']}\">#{dbn[0]['login']}</a>, no le mandes tantos mensajes a <a href=\"/miembros/nagato\">nagato</a> porque forma parte de mi harén y soy celoso."
    end
    
    report_i = User.db_query("SELECT count(distinct(created_on)) FROM users_emblems")[0]['count'].to_i
    n = News.create(:title => "El dominical de MrAchmed ##{(report_i)}", :news_category_id => NewsCategory.find(:first, :conditions => 'code = \'gm\' AND root_id = id').id, :user_id => User.find_by_login('MrAchmed').id, :description => base, :main => main)
    Term.single_toplevel(:slug => 'gm').link(n.unique_content)
    Cms.publish_content(n, User.find_by_login('MrMan'))
  end
end
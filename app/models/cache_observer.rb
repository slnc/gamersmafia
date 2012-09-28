# -*- encoding : utf-8 -*-
# TENER EN CUENTA EL COSTE DE COMPROBAR SI BORRAR UN FRAGMENTO Y DE
# GENERARLO DE NUEVO. SI NO COMPENSA HACER LAS COMPROBACIONES PORQUE SE
# TARDA MÁS EN COMPROBARLO Q EN VOLVER A GENERARLO ENTONCES NO BORRARLO
#
# Esta clase se encarga de gestionar los fragmentos de vista cacheados
# TODO TODO TODO optimizar todo esto para no limpiar con tanta facilidad
class CacheObserver < ActiveRecord::Observer
  observe BazarDistrict,
          Bet,
          Blogentry,
          Clan,
          ClansMovement,
          Column,
          Comment,
          CommentsValoration,
          Competition,
          CompetitionsMatch,
          CompetitionsParticipant,
          Content,
          ContentsRecommendation,
          ContentsTerm,
          Coverage,
          Demo,
          Download,
          Event,
          Faction,
          FactionsLink,
          Friendship,
          Funthing,
          Game,
          GmtvChannel,
          Image,
          Interview,
          News,
          Poll,
          PollsVote,
          Portal,
          Potd,
          ProfileSignature,
          Question,
          RecruitmentAd,
          Review,
          Skin,
          SlogEntry,
          Term,
          Topic,
          Tutorial,
          User,
          UsersEmblem,
          UsersSkill

  def self.bazar_root_tc_id
    @@bazar_root_tc_id ||= Term.single_toplevel(:slug => 'bazar')
  end

  def self.arena_root_tc_id
    @@arena_root_tc_id ||= Term.single_toplevel(:slug => 'arena')
  end

  def after_create(object)
    case object.class.name
      when 'ClansMovement'
      expire_fragment "/home/comunidad/clans_movements"
      when 'RecruitmentAd'
      expire_fragment "/home/comunidad/recruitment_ads_#{object.clan_id ? 'clans' : 'users'}"
      when 'ContentsRecommendation'
      expire_fragment "/_users/#{object.receiver_user_id % 1000}/#{object.receiver_user_id}/layouts/recommendations"
      when 'UsersSkill'
      Cache::Personalization.expire_quicklinks(object.user) if %w(Don ManoDerecha Sicario).include?(object.role)
      if %w(Editor Moderator).include?(object.role)
        faction_id =object.role == 'Moderator' ? object.role_data : object.role_data_yaml[:faction_id]
        expire_fragment("/common/facciones/#{faction_id}/staff")
      end
      when 'SlogEntry'
      expire_fragment "/common/slog/*"

      when 'UsersEmblem'
      expire_fragment "/common/miembros/#{object.user_id % 1000}/#{object.user_id}/emblemas"

      when 'GmtvChannel'
      object.get_related_portals.each { |p| expire_fragment("/#{p.code}/channels") }
      GlobalVars.update_var("gmtv_channels_updated_on", "now()")

      when 'ProfileSignature'
      expire_fragment "/common/miembros/#{object.user_id % 1000}/#{object.user_id}/firmas"
      expire_fragment "#{Cache.user_base(object.user_id)}/profile/last_profile_signatures"

      when 'Content'
      CacheObserver.update_pending_contents
      # TODO esto se cargará la cache de elementos pendientes de moderar al
      # crear/modificar topics.
      expire_fragment('/site/pending_contents') if object.state_changed?

      when 'CompetitionsMatch'
      if object.participant1_id
        expire_fragment("/common/competiciones/participante/#{object.participant1_id % 1000}/#{object.participant1_id}/retos_esperando_respuesta")
        expire_fragment("/common/competiciones/participante/#{object.participant1_id % 1000}/#{object.participant1_id}/retos_pendientes_de_jugar")
        object.participant1.users.each { |u| Cache::Competition.expire_competitions_lists(u) }
      end
      if object.participant2_id
        expire_fragment("/common/competiciones/participante/#{object.participant2_id % 1000}/#{object.participant2_id}/retos_esperando_respuesta")
        expire_fragment("/common/competiciones/participante/#{object.participant2_id % 1000}/#{object.participant2_id}/retos_pendientes_de_jugar")
        object.participant2.users.each { |u| Cache::Competition.expire_competitions_lists(u) }
      end

      when 'CompetitionsParticipant'
      object.users.each { |u| Cache::Competition.expire_competitions_lists(u) }

      if object.competition.kind_of?(Ladder)
        expire_fragment "/arena/home/open_ladders"
        # TODO copypasted
        object.competition.get_related_portals.each do |portal|
          expire_fragment "/#{portal.code}/competiciones/index/competiciones_en_curso"
        end
      end
      expire_fragment("/common/competiciones/#{object.competition_id}/ultimas_inscripciones")
      expire_fragment("/common/competiciones/#{object.competition_id}/participantes")

      when 'Potd' # TODO adapt this
      if object.portal_id && object.portal_id != -1 then
        p = Portal.find(object.portal_id)
        expire_fragment("/imagenes/potds/#{p.code}/page_") # solo tenemos que borrar la última página y nos sirve tb para index
        last_page = Potd.count(:conditions => "portal_id = #{p.id}") / 16 + 1
        expire_fragment("/imagenes/potds/#{p.code}/page_#{last_page}") # solo tenemos que borrar la última página y nos sirve tb para index
        # puts "borrando potds"
        expire_fragment("/#{p.code}/home/index/potd_*") # solo tenemos que borrar la última página y nos sirve tb para index
      else
        last_page = Potd.count(:conditions => "portal_id is null") / 16 + 1
        expire_fragment("/imagenes/potds/page_#{last_page}") # solo tenemos que borrar la última página y nos sirve tb para index
        expire_fragment("/imagenes/potds/page_") # solo tenemos que borrar la última página y nos sirve tb para index
        expire_fragment("/gm/home/index/potd_*") # solo tenemos que borrar la última página y nos sirve tb para index
      end

      when 'Faction'
      Cache::Faction.common(object)

      when 'Blogentry'
      expire_fragment '/common/home/index/blogentries'
      expire_fragment "/common/blogs/#{object.user_id % 1000}/#{object.user_id}"
      object.user.faction.portals.each { |p| expire_fragment("/#{p.code}/home/index/blogentries") }  if object.user.faction_id



      when 'FactionsLink'
      expire_fragment("/common/facciones/#{object.faction_id}/webs_aliadas")
      object.faction.portals.each { |p| expire_fragment("/#{p.code}/webs_aliadas") }

      when 'PollsVote'
      object.polls_option.poll.get_related_portals.each do |portal|
        expire_fragment("/#{portal.code}/encuestas/index/most_votes")
      end


      when 'CommentsValoration'
      expire_fragment("/comments/#{Time.now.to_i/(86400*7)}/#{object.comment.content_id%100}/#{object.comment.content_id}_*") # cacheamos solo una semana para q se actualicen barras

      when 'Comment'
      # NOTA: Tener en cuenta que al modificar comentario se llama a su
      # contenido por lo que la parte de limpieza correspondiente al contenido
      # la ponemos ahí
      # TODO PERF cache borramos de más, todas las páginas anteriores solo cambian por el paginador
      expire_fragment("/comments/#{Time.now.to_i/(86400*7)}/#{object.content_id%100}/#{object.content_id}_*") # cacheamos solo una semana para q se actualicen barras
      Cache::Comments.after_create(object.id)

      when 'Clan'
      expire_fragment('/gm/clanes/index/page*')

      if object.new_record?
        expire_fragment("/gm/clanes/index/newest")
      end

      when 'FactionsPortal'
      do_portal_expire(object)

      when 'Portal'
      do_portal_expire(object)

      when 'Game'
      expire_fragment('/common/miembros/buscar_por_guid')
    end
  end

  def do_competitions(object)
    object.get_related_portals.each do |portal|
      if object.state >= 1
        expire_fragment "/#{portal.code}/competiciones/index/competiciones_en_curso"
        expire_fragment "/#{portal.code}/competiciones/index/inscripciones_abiertas" if object.state <= 2
        expire_fragment "/#{portal.code}/competiciones/index/inscripciones_abiertas2" if object.state <= 2
        expire_fragment "/#{portal.code}/competiciones/index/competiciones_finalizadas" if object.state >= 4
      end
    end
    expire_fragment "/arena/home/open_ladders" if object.kind_of?(Ladder)
    expire_fragment("/common/competiciones/#{object.id}/partidas") # TODO tb podemos ser más exquisitos aquí
  end

  def do_portal_expire(object)
    expire_fragment('/portales')
    expire_fragment('/common/portales2')
    expire_fragment("/#{object.code}/portales")
  end

  def before_create(object)
    case object.class.name
      when 'Clan'
      expire_fragment("/gm/clanes/index/newest")
    end
  end

  def after_destroy(object)
    case object.class.name
      when 'FactionsSkin' then
      Cache::Skins.common(object)
      when 'Skin'
      Cache::Skins.common(object)
      when 'ClansMovement'
      expire_fragment "/home/comunidad/clans_movements"
      expire_fragment "#{Cache.user_base(object.user_id)}/profile/clanes"
      when 'RecruitmentAd'
      expire_fragment "/home/comunidad/recruitment_ads_#{object.clan_id ? 'clans' : 'users'}"
      when 'UsersSkill'
      Cache::Personalization.expire_quicklinks(object.user) if %w(Don ManoDerecha Sicario).include?(object.role)
      if %w(Editor Moderator).include?(object.role)
        faction_id =object.role == 'Moderator' ? object.role_data : object.role_data_yaml[:faction_id]
        expire_fragment("/common/facciones/#{faction_id}/staff")
      end

      when 'ContentsRecommendation'
      expire_fragment "/_users/#{object.receiver_user_id % 1000}/#{object.receiver_user_id}/layouts/recommendations"

      when 'BazarDistrict'
      expire_fragment "/layouts/default/districts"

      when 'Friendship'
      Cache::Friendship.common(object)

      when 'GmtvChannel'
      object.get_related_portals.each { |p| expire_fragment("/#{p.code}/channels") }
      GlobalVars.update_var("gmtv_channels_updated_on", "now()")

      when 'CompetitionsMatch'
      if object.participant1_id
        expire_fragment("/common/competiciones/participante/#{object.participant1_id % 1000}/#{object.participant1_id}/retos_esperando_respuesta")
        object.participant1.users.each { |u| Cache::Competition.expire_competitions_lists(u) }
      end
      if object.participant2_id
        expire_fragment("/common/competiciones/participante/#{object.participant2_id % 1000}/#{object.participant2_id}/retos_esperando_respuesta")
        object.participant2.users.each { |u| Cache::Competition.expire_competitions_lists(u) }
      end

      if object.accepted && object.completed_on.nil? && object.competition.kind_of?(Ladder) then
        expire_fragment("/common/competiciones/_show/#{object.competition_id}/proximas_partidas")
      end

      when 'ProfileSignature'
      expire_fragment "/common/miembros/#{object.user_id % 1000}/#{object.user_id}/firmas"
      expire_fragment "#{Cache.user_base(object.user_id)}/profile/last_profile_signatures"

      when 'Game'
      expire_fragment('/common/miembros/buscar_por_guid')

      when 'FactionsLink'
      expire_fragment("/common/facciones/#{object.faction_id}/webs_aliadas")
      object.faction.portals.each { |p| expire_fragment("/#{p.code}/webs_aliadas") }

      when 'Blogentry'
      expire_fragment('/common/home/index/blogentries')
      expire_fragment "/common/blogs/#{object.user_id % 1000}/#{object.user_id}"
      object.user.faction.portals.each { |p| expire_fragment("/#{p.code}/home/index/blogentries") }  if object.user.faction_id

      when 'Potd'
      # si el potd es de hoy nos cargamos las caches
      if object.date == Date.today
        if object.portal_id && object.portal_id != -1 then
          p = Portal.find(object.portal_id)
          expire_fragment("/#{p.code}/home/index/potd_#{object.date.year}#{object.date.month}#{object.date.day}")
          expire_fragment("/imagenes/potds/#{p.code}/page_") # solo tenemos que borrar la última página y nos sirve tb para index
          last_page = Potd.count(:conditions => "portal_id = #{p.id}") / 16 + 1
          expire_fragment("/imagenes/potds/#{p.code}/page_#{last_page}") # solo tenemos que borrar la última página y nos sirve tb para index
        else
          expire_fragment("/gm/home/index/potd_#{object.date.year}#{object.date.month}#{object.date.day}")
          expire_fragment("/imagenes/potds/page_") # solo tenemos que borrar la última página y nos sirve tb para index
          last_page = Potd.count(:conditions => "portal_id is null") / 16 + 1
          expire_fragment("/imagenes/potds/page_#{last_page}") # solo tenemos que borrar la última página y nos sirve tb para index
        end
      end

      when 'Topic'
      for p in object.get_related_portals;
        expire_fragment("/#{p.code}/home/index/topics")
        expire_fragment("/#{p.code}/home/index/topics2")
        expire_fragment("/site/lasttopics_left#{p.code}")
        if object.state_changed?
          expire_fragment("/#{p.code}/site/last_commented_objects")
          expire_fragment("/#{p.code}/site/last_commented_objects_ids")
        end
      end
      expire_fragment "/common/topics/_latest_by_cat2#{object.main_category.root.code}"

      expire_fragment("/common/foros/by_root/#{object.main_category.root_id}")
      expire_fragment('/home/index/topics')
      expire_fragment("/bazar/home/categories/#{object.main_category.code}") if object.main_category.root_id == CacheObserver.bazar_root_tc_id
      expire_fragment("/arena/home/last_topics") if object.main_category.root_id == CacheObserver.arena_root_tc_id
      expire_fragment('/site/lasttopics_left')
      par = object.main_category
      while par
        expire_fragment("/common/foros/_forums_list/#{par.id}")
        expire_fragment("/common/home/foros/topics_#{par.id}")
        par = par.parent
      end

      # borramos las páginas de listado de noticias posteriores a la actual
      stickies = object.main_category.count(:content_type => 'Topic', :conditions => "sticky is true and state = #{Cms::PUBLISHED}")
      prev_count = object.main_category.count(:content_type => 'Topic', :conditions => ["sticky is false and state = #{Cms::PUBLISHED} and created_on <= ?", object.created_on]) + stickies
      next_count = object.main_category.count(:content_type => 'Topic', :conditions => ["sticky is false and state = #{Cms::PUBLISHED} and created_on >= ?", object.created_on])
      start_page = prev_count / 50 # TODO especificar esto en un único sitio
      end_page = start_page + next_count / 50 + 1

      expire_fragment("/common/foros/_topics_list/#{object.main_category.id}/page_")
      expire_fragment("/common/foros/_topics_list/#{object.main_category.id}/page_*")

      when 'CommentsValoration'
      expire_fragment("/comments/#{Time.now.to_i/(86400*7)}/#{object.comment.content_id%100}/#{object.comment.content_id}_*") # cacheamos solo una semana para q se actualicen barras

      when 'Comment'
      expire_fragment("/comments/#{Time.now.to_i/(86400*7)}/#{object.content_id%100}/#{object.content_id}_*") # cacheamos una semana para q se actualicen barras
      Cache::Comments.delay.after_destroy(object.content_id, object.user_id)

      when 'FactionsPortal'
      do_portal_expire(object)

      when 'Portal'
      do_portal_expire(object)
    end
  end

  def before_destroy(object)
    case object.class.name
      when 'Term'
      Cache::Terms.before_destroy(object) unless object.import_mode
      when 'ContentsTerm'
      Cache::Terms.before_destroy(object.term) unless object.import_mode
      when 'League'
      do_competitions(object)
      when 'Tournament'
      do_competitions(object)
      when 'Ladder'
      do_competitions(object)
      when 'Clan' # lo necesitamos aquí por los foreign keys de games
      expire_fragment('/gm/clanes/index/page*')
      expire_fragment("/common/clanes/#{object.id}/*")

      # TODO copypaste de arriba
      expire_fragment("/gm/clanes/index/newest")
      object.games.each do |g|
        g.faction.portals.each do |p|
          expire_fragment("/#{p.code}/clanes/index/page*")
          expire_fragment("/#{p.code}/clanes/index/newest")
        end
      end
    end
  end

  def after_save(object)
    return unless object.record_timestamps
    # un objeto es guardado justo después de ser publicado y es guardado justo
    # después de ser borrado

    # para evitar repetir hacemos una cosa, si el contenido tiene un atributo
    # user_id borramos las caches de contenidos de dicho usuario
    # TODO(slnc): too aggressive
    if object.respond_to?('user_id') && object.respond_to?(:state)
      expire_fragment("#{Cache.user_base(object.user_id)}/sus_contenidos_son")
      expire_fragment("#{Cache.user_base(object.user_id)}/profile/aportaciones")
      expire_fragment("/common/miembros/#{object.user_id % 1000}/#{object.user_id}/contents_stats")
      expire_fragment("/common/miembros/#{object.user_id % 1000}/#{object.user_id}/contenidos/#{object.class.name.downcase}/*")
      if object.state_changed? && object.state == Cms::DELETED
        expire_fragment('/gm/site/last_commented_objects') # borramos caches de últimos comentarios
        expire_fragment('/gm/site/last_commented_objects_ids')
      end

      return if Cms::CONTENTS_WITH_CATEGORIES.include?(object.class.name) && object.main_category.nil?
    end

    case object.class.name
      when 'BazarDistrict'
      if object.name_changed? || object.code_changed?
        expire_fragment "/layouts/default/districts"
      end

      when 'Bet'
      object.get_related_portals.each do |p|
        expire_fragment("/#{p.code}/home/index/apuestas_#{Time.now.to_i / 3600}")
        expire_fragment("/#{p.code}/home/index/apuestas2_#{Time.now.to_i / 3600}")
        expire_fragment("/common/apuestas/show/latest_by_cat_#{p.id}")
      end

      if (object.winning_bets_option_id_changed? ||
          object.forfeit_changed? ||
          object.cancelled_changed? ||
          object.tie_changed?)
        expire_fragment "/common/admin/contenidos/index/pending_bets"
      end

      when 'Blogentry'
      expire_fragment '/common/home/index/blogentries'
      expire_fragment "/common/blogs/#{object.user_id % 1000}/#{object.user_id}"
      object.user.faction.portals.each { |p| expire_fragment("/#{p.code}/home/index/blogentries") }  if object.user.faction_id

      when 'Clan'
      GlobalVars.update_clans_updated_on
      expire_fragment('/gm/clanes/index/page*')
      expire_fragment("/common/clanes/#{object.id}/*") # TODO excesivo :s

      if object.deleted_changed?
        expire_fragment("/gm/clanes/index/newest")
        object.games.each do |g|
          g.faction.portals.each do |p|
            expire_fragment("/#{p.code}/clanes/index/page*")
            expire_fragment("/#{p.code}/clanes/index/newest")
          end
        end
      end

      if object.game_ids_changed?
        changed_games = []

        if object.game_ids_changed?
          prev = object.game_ids_was
        else
          prev = []
        end
        prev = prev.collect { |d| d.to_i }
        cur = object.games.collect { |g| g.id }

        prev.delete_if { |g_id| cur.include?(g_id) }
        cur.delete_if { |g_id| prev.include?(g_id) }

         (prev + cur).uniq.each do |g_id|
          g = Game.find(g_id)
          g.faction.portals.each do |p|
            expire_fragment("/#{p.code}/clanes/index/page*")
            expire_fragment("/#{p.code}/clanes/index/newest")
          end
        end

      elsif object.members_count_changed?
        object.games.each do |g|
          g.faction.portals.each do |p|
            expire_fragment("/#{p.code}/clanes/index/page*")
          end
        end
      end

      when 'CompetitionsParticipant'
      expire_fragment "/arena/home/open_ladders" if object.competition.kind_of?(Ladder)
      expire_fragment("/common/competiciones/#{object.competition_id}/participantes")
      begin # This is necessary in case we are recreating games and competitions_participants are nil
        object.users.each do |u|
          Cache::Competition.expire_competitions_lists(u)
        end
      rescue
      end

      when 'Column'
      object.get_related_portals.each do |p|
        expire_fragment("/common/home/index/articles2b#{p.code}") if p.class.name == 'BazarDistrictPortal'
        expire_fragment("/#{p.code}/home/index/articles")
        expire_fragment("/#{p.code}/home/index/articles2")
        next unless p.column
        # borramos las páginas de listado de columnas posteriores a la actual
        #prev_count = p.column.count(:published, :conditions => ["created_on <= ?", object.created_on])
        #next_count = p.column.count(:published, :conditions => ["created_on >= ?", object.created_on])
        #start_page = prev_count / ColumnasController::COLUMNS_PER_PAGE
        #end_page = start_page + next_count / ColumnasController::COLUMNS_PER_PAGE + 1

        # (start_page..end_page).each { |i| expire_fragment("/#{p.code}/columnas/index/page_#{i}") }
        expire_fragment("/#{p.code}/columnas/index/page_")
        expire_fragment("/#{p.code}/columnas/index/page_*")
        expire_fragment("/#{p.code}/columnas/show/latest_by_author_#{object.user_id}")
        if object.user_id_changed?
          expire_fragment(
              "/#{p.code}/columnas/index/most_popular_authors_#{Time.now.to_i/(86400)}")
          end
      end

      when 'CompetitionsMatch'
      expire_fragment "/arena/home/matches_results"
      if object.completed_on then
        expire_fragment("/common/competiciones/_show/#{object.competition_id}/partidas_mas_recientes")
        Portal.find_by_competitions_match(object).each { |portal| expire_fragment("/#{portal.code}/competiciones/_ultimos_resultados") }
        expire_fragment("/gm/competiciones/_ultimos_resultados")
      end
      if object.accepted && object.completed_on.nil? && object.competition.kind_of?(Ladder) then
        expire_fragment("/common/competiciones/_show/#{object.competition_id}/proximas_partidas")
      end

      if object.competition.kind_of?(Ladder) then
        expire_fragment("/common/competiciones/#{object.competition.id}/ranking")
      else
        expire_fragment("/common/competiciones/#{object.competition.id}/partidas")
      end
      if object.participant1_id
        expire_fragment("/common/competiciones/participante/#{object.participant1_id % 1000}/#{object.participant1_id}/retos_esperando_respuesta")
        expire_fragment("/common/competiciones/participante/#{object.participant1_id % 1000}/#{object.participant1_id}/retos_pendientes_de_jugar")
        expire_fragment("/common/competiciones/participante/#{object.participant1_id % 1000}/#{object.participant1_id}/ultimas_partidas")
        object.participant1.users.each { |u| Cache::Competition.expire_competitions_lists(u) }
        # TODO expire_fragment("/miembros/#{object.participant1.participant_id % 1000}/#{object.participant1.participant_id}/competition_matches")
      end
      if object.participant2_id
        expire_fragment("/common/competiciones/participante/#{object.participant2_id % 1000}/#{object.participant2_id}/retos_esperando_respuesta")
        expire_fragment("/common/competiciones/participante/#{object.participant2_id % 1000}/#{object.participant2_id}/retos_pendientes_de_jugar")
        expire_fragment("/common/competiciones/participante/#{object.participant2_id % 1000}/#{object.participant2_id}/ultimas_partidas")
        object.participant2.users.each { |u| Cache::Competition.expire_competitions_lists(u) }
      end

      object.competition.get_related_portals.each do |portal|
        expire_fragment "/#{portal.code}/competiciones/index/competiciones_en_curso"
      end

      when 'CommentsValoration'
      expire_fragment("/comments/#{Time.now.to_i/(86400*7)}/#{object.comment.content_id%100}/#{object.comment.content_id}_*") # cacheamos solo una semana para q se actualicen barras

      when 'Comment'
      expire_fragment("/comments/#{Time.now.to_i/(86400*7)}/#{object.content_id%100}/#{object.content_id}_*") # cacheamos una semana para q se actualicen barras
      real = object.content.real_content

      # TODO solo hay que limpiar cache si aparecen en portada y tb
      # TODO ESTO se sigue usando?
      case real.class.name
        when 'Topic'
        expire_fragment("/bazar/home/categories/#{real.main_category.code}")
        expire_fragment("/gm/home/index/topics")# :controller => '/home', :action => 'index', :part => 'topics')
        f = real.main_category
        if f
          f.save
          expire_fragment("/foros/active_items/#{f.root_id}")
        end

        when 'Column'
        expire_fragment(:controller => '/home', :action => 'index', :part => 'articles')
        when 'Interview'
        expire_fragment(:controller => '/home', :action => 'index', :part => 'articles')
        when 'Review'
        expire_fragment(:controller => '/home', :action => 'index', :part => 'articles')
        when 'Tutorial'
        expire_fragment(:controller => '/home', :action => 'index', :part => 'articles')
        when 'News'
        expire_fragment(:controller => '/home', :action => 'index', :part => 'news')
        expire_fragment(:controller => '/home', :action => 'index', :part => 'news_developed')
        when 'Download'
        expire_fragment(:controller => '/home', :action => 'index', :part => 'downloads')
        when 'Poll'
        expire_fragment(:controller => '/home', :action => 'index', :part => 'polls')
        if object.content.real_content.my_faction
          expire_fragment(:controller => '/home', :action => 'index', :part => "polls_#{object.content.real_content.my_faction.id}")
        end
        when 'Image'
        expire_fragment(:controller => '/home', :action => 'index', :part => "daily_image#{Time.now.to_i/86400}")
        when 'Funthing'
        expire_fragment(:controller => '/home', :action => 'index', :part => 'curiosidades')

      end

      when 'Content'
      CacheObserver.update_pending_contents if object.state_changed?
      if ((object.state_changed? && object.state == Cms::DELETED) ||
          object.comments_count_changed?)
        object.terms.each do |t|
          t.recalculate_counters
        end
      end

      when 'ContentsRecommendation'
      expire_fragment "/_users/#{object.receiver_user_id % 1000}/#{object.receiver_user_id}/layouts/recommendations"

      when 'ContentsTerm' then
      Cache::Terms.after_save(object.term) unless object.import_mode
      #
      # TODO ser más exquisito cuando reordenemos la sección
      when 'Coverage'
      for p in object.get_related_portals
        expire_fragment("/#{p.code}/home/index/coverages")
        expire_fragment("/#{p.code}/home/index/coverages2")
        expire_fragment("/#{p.code}/home/index/coverages_developed")
      end

      when 'Demo'
      for p in object.get_related_portals
        expire_fragment("/#{p.code}/home/index/demos")
        expire_fragment("/#{p.code}/home/index/demos2")
      end

      expire_fragment "/common/demos/show/_latest_cat#{object.main_category.id}"

      when 'Download'
      expire_fragment('/home/index/downloads')
      for p in object.get_related_portals
        expire_fragment("/#{p.code}/home/index/downloads")
        expire_fragment("/#{p.code}/home/index/downloads2")

      end
      expire_fragment "/common/home/index/downloads3#{object.main_category.root.code}"

      # borramos las páginas de listados por si es un nuevo comment
      expire_fragment("/common/descargas/index/downloads_#{object.main_category.id}/page_*")

      # TODO optimizar, no?
      p = object.main_category
      expire_fragment("/common/descargas/index/most_downloaded_#{p.root_id}")
      expire_fragment("/common/descargas/index/essential_#{p.root_id}")
      expire_fragment("/common/descargas/index/essential2_#{p.root_id}")
      expire_fragment("/common/descargas/index/essential3_#{p.root_id}")
      object.get_related_portals.each do |pp|
        expire_fragment("/#{pp.code}/descargas/index/folders")
      end

      while p do
        expire_fragment("/common/descargas/index/most_productive_author_by_cat_#{p.id}")
        expire_fragment("/common/descargas/index/folders_#{p.id}")
        expire_fragment("/common/descargas/index/downloads_#{p.id}/page_*")
        p = p.parent # necesario por la clase proxy de noticias de GmPortal
      end

      when 'Event'
      # TODO borrar de forma más selectiva
      object.get_related_portals.each do |p|
        expire_fragment("/#{p.code}/home/index/eventos/#{Time.now.strftime('%Y%m%d')}")
        expire_fragment("/#{p.code}/home/index/eventos2/#{Time.now.strftime('%Y%m%d')}")
        #next if p.event.nil?
        # borramos las páginas de listado de noticias posteriores a la actual
        # TODO PERF
        #prev_count = p.event.count(:published, :conditions => ["created_on <= ?", object.created_on])
        #next_count = p.event.count(:published, :conditions => ["created_on >= ?", object.created_on])
        #start_page = prev_count / EventosController::PER_PAGE
        #end_page = start_page + next_count / EventosController::PER_PAGE + 1

        # (start_page..end_page).each { |i| expire_fragment("/#{p.code}/eventos/index/page_#{i}") }

        expire_fragment("/#{p.code}/eventos/index/page_")
        expire_fragment("/#{p.code}/eventos/index/page_*")
      end

      when 'Faction'
      Cache::Faction.common(object)

      when 'FactionsLink'
      expire_fragment("/common/facciones/#{object.faction_id}/webs_aliadas")
      object.faction.portals.each { |p| expire_fragment("/#{p.code}/webs_aliadas") }

      when 'FactionsPortal'
      do_portal_expire(object)

      when 'FactionsSkin' then
      Cache::Skins.common(object)

      when 'Friendship'
      Cache::Friendship.common(object)

      when 'Funthing'
      expire_fragment('/common/home/index/curiosidades')
      expire_fragment('/common/home/index/curiosidades2')
      expire_fragment('/common/curiosidades/show/_latest')
      # TODO(juanalonso): hack, the page counting code isn't working.
      expire_fragment('/common/curiosidades/index/page_*')
      # TODO es un copypaste de news

      # borramos las páginas de listado de noticias posteriores a la actual
      prev_count = Funthing.published.count(:conditions => ["created_on <= ?", object.created_on])
      next_count = Funthing.published.count(:conditions => ["created_on >= ?", object.created_on])
      start_page = prev_count / 20 # TODO especificar esto en un único sitio
      end_page = start_page + next_count / 20 + 1
      [start_page..end_page].each do |i|
        expire_fragment("/common/curiosidades/index/page_#{i}")
      end

      expire_fragment("/common/curiosidades/index/page_")

      when 'Game'
      expire_fragment('/common/miembros/buscar_por_guid')

      when 'GmtvChannel'
      object.get_related_portals.each { |p| expire_fragment("/#{p.code}/channels") }
      GlobalVars.update_var("gmtv_channels_updated_on", "now()")

      when 'Image'
      d = Date.today
      # TODO un poco de porfavor
      expire_fragment("/gm/home/index/potd_#{d.strftime('%Y%m%d')}")
      expire_fragment "/common/home/index/imagenes_#{object.main_category.root.code}"
      object.get_related_portals.each do |p|
        expire_fragment("/#{p.code}/home/index/daily_image#{d.strftime('%Y%m%d')}")
        expire_fragment("/#{p.code}/imagenes/index/galleries")
        expire_fragment("/#{p.code}/imagenes/show/_other_images_by_user/#{object.user_id % 1000}/#{object.user_id}")
      end
      expire_fragment("/common/imagenes/toplevel/#{object.main_category.root_id}/page_*}")
      expire_fragment("/common/imagenes/gallery/#{object.main_category.id}/page_*")
      expire_fragment("/common/imagenes/gallery/#{object.main_category.id}/profile/aportaciones")
      expire_fragment("/common/imagenes/show/g#{object.main_category.id}/*") # muy heavy

      when 'Interview'
      object.get_related_portals.each do |p|
        expire_fragment("/common/home/index/articles2b#{p.code}") if p.class.name == 'BazarDistrictPortal'
        expire_fragment("/#{p.code}/home/index/articles")
        expire_fragment("/#{p.code}/home/index/articles2")
        next unless p.interview
        # borramos las páginas de listado de entrevistas posteriores a la actual
        # TODO PERF
        #prev_count = p.interview.count(:published, :conditions => ["created_on <= ?", object.created_on])
        #next_count = p.interview.count(:published, :conditions => ["created_on >= ?", object.created_on])
        #start_page = prev_count / EntrevistasController::INTERVIEWS_PER_PAGE
        #end_page = start_page + next_count / EntrevistasController::INTERVIEWS_PER_PAGE + 1

        # (start_page..end_page).each { |i| expire_fragment("/#{p.code}/entrevistas/index/page_#{i}") }

        expire_fragment("/#{p.code}/entrevistas/index/page_")
        expire_fragment("/#{p.code}/entrevistas/index/page_*")
        expire_fragment("/#{p.code}/entrevistas/show/latest_by_author_#{object.user_id}")
      end

      when 'Ladder'
      do_competitions(object)

      when 'League'
      do_competitions(object)

      when 'News'
      # TODO borrar de forma más selectiva
      object.terms.find(:all).each do |t|
        expire_fragment("/bazar/home/categories/#{t.slug}")
        expire_fragment("/common/noticias/_latest_by_cat2_#{t.root.code}")
        # borramos el listado de últimas noticias de categoría X
        # TODO solo deberíamos borrar si es la última
        expire_fragment("/common/noticias/show/_latest_by_cat_#{t.id}")

        if t.slug == 'gm'
          expire_fragment("/common/novedades/page_*")
          expire_fragment("/common/novedades/page_")
        end
      end
      expire_fragment("/common/home/index/news_inet")
      expire_fragment("/common/gmversion") if object.title.index('Gamersmafia actualizada a la')

      object.get_related_portals.each do |p|
        expire_fragment("/#{p.code}/home/index/news")
        expire_fragment("/#{p.code}/home/index/news2")
        expire_fragment("/#{p.code}/home/index/news30")

        expire_fragment("/#{p.code}/home/index/news_developed")
        # borramos las páginas de listado de noticias posteriores a la actual
        #prev_count = p.news.count(:published, :content_type => 'News', :conditions => "contents.created_on <= '#{object.created_on.strftime('%Y-%m-%d %H:%M:%s')}'")
        #next_count = p.news.count(:published, :content_type => 'News', :conditions => "contents.created_on >= '#{object.created_on.strftime('%Y-%m-%d %H:%M:%s')}'")
        #start_page = prev_count / NoticiasController::NEWS_PER_PAGE
        #end_page = start_page + next_count / NoticiasController::NEWS_PER_PAGE + 1
        # TODO PERF
        # (start_page..end_page).each { |i| expire_fragment("/#{p.code}/noticias/index/page_#{i}") }

        expire_fragment("/#{p.code}/noticias/index/page_*")
        expire_fragment("/#{p.code}/noticias/index/page_")
      end

      expire_fragment('/rss/noticias/all')

      when 'Poll'
      object.get_related_portals.each do |p|
        if object.respond_to?(:my_faction)
          f = object.my_faction
          expire_fragment("/#{p.code}/home/index/polls_#{f.id}") if f # note: no funciona en webs de clanes
        end

        expire_fragment("/#{p.code}/encuestas/index/page_*")
      end

      when 'Portal'
      do_portal_expire(object)

      when 'Question'
      Cache::Contents.common_question(object)

      when 'ProfileSignature'
      expire_fragment "/common/miembros/#{object.user_id % 1000}/#{object.user_id}/firmas"
      expire_fragment "#{Cache.user_base(object.user_id)}/profile/last_profile_signatures"

      when 'RecruitmentAd'
      expire_fragment "/home/comunidad/recruitment_ads_#{object.clan_id ? 'clans' : 'users'}"

      when 'Review'
      expire_fragment('/home/index/articles')
      for p in object.get_related_portals
        expire_fragment("/common/home/index/articles2b#{p.code}") if p.class.name == 'BazarDistrictPortal'
        expire_fragment("/#{p.code}/home/index/articles")
        expire_fragment("/#{p.code}/home/index/articles2")
        if object.user_id_changed?
          expire_fragment(
              "/#{p.code}/reviews/index/most_popular_authors_#{Time.now.to_i/(86400)}")
        end
      end

      # borramos las páginas de listados por si es un nuevo comment
      expire_fragment("/reviews/page_*") # TODO un poco basto, no?
      p = object.main_category

      while p do
        expire_fragment("/reviews/latest_by_cat_#{p.id}")
        expire_fragment("/reviews/latest_by_cat_5_#{p.id}")
        expire_fragment("/reviews/most_productive_author_by_cat_#{p.id}")
        expire_fragment("/reviews/list/subcategories_#{p.id}")
        expire_fragment("/reviews/cat_#{p.id}/page_*")
        p = p.parent
      end

      expire_fragment("/reviews/latest_by_cat_")
      expire_fragment("/reviews/most_productive_author_by_cat")

      expire_fragment("/reviews/list/subcategories_")

      when 'Skin' then
      Cache::Skins.common(object)

      when 'Term' then
      Cache::Terms.after_save(object) unless object.import_mode

      # TODO duplicado
      when 'Topic'
      return if object.main_category.nil?
      expire_fragment("/bazar/home/categories/#{object.main_category.code}") if object.main_category.root_id == CacheObserver.bazar_root_tc_id
      expire_fragment("/arena/home/last_topics") if object.main_category.root_id == CacheObserver.arena_root_tc_id
      expire_fragment("/common/foros/by_root/#{object.main_category.root_id}")
      expire_fragment('/site/lasttopics_left')
      expire_fragment("/common/foros/_topics_list/#{object.main_category}/page_")
      expire_fragment('/gm/home/index/topics')
      expire_fragment('/gm/home/index/topics2')
      expire_fragment('/home/index/topics')
      for p in object.get_related_portals
        expire_fragment("/#{p.code}/home/index/topics")
        expire_fragment("/#{p.code}/home/index/topics2")
        expire_fragment("/site/lasttopics_left#{p.code}")
        expire_fragment("/#{p.code}/foros/index/index")
        if object.state_changed?
          expire_fragment("/#{p.code}/site/last_commented_objects")
          expire_fragment("/#{p.code}/site/last_commented_objects_ids")
        end
      end
      expire_fragment("/common/foros/by_root/#{object.main_category.root_id}")
      expire_fragment("/bazar/home/categories/#{object.main_category.code}") if object.main_category.root_id == CacheObserver.bazar_root_tc_id
      expire_fragment("/arena/home/last_topics") if object.main_category.root_id == CacheObserver.arena_root_tc_id
      expire_fragment "/common/topics/_latest_by_cat2#{object.main_category.root.code}"
      expire_fragment('/site/lasttopics_left')
      p = object.main_category
      expire_fragment("/foros/active_items/#{p.root_id}")
      expire_fragment "/common/topics/_latest_by_cat2#{p.root.code}"
      while p
        expire_fragment("/common/foros/_forums_list/#{p.id}")
        expire_fragment("/common/home/foros/topics_#{p.id}")
        p = p.parent
      end

      # borramos las páginas de listado de noticias posteriores a la actual
      stickies = object.main_category.count(:content_type => 'Topic', :conditions => "sticky is true and contents.state = #{Cms::PUBLISHED}")
      prev_count = object.main_category.count(:content_type => 'Topic', :conditions => ["sticky is false and contents.state = #{Cms::PUBLISHED} and contents.updated_on <= ?", object.created_on]) + stickies
      next_count = object.main_category.count(:content_type => 'Topic', :conditions => ["sticky is false and contents.state = #{Cms::PUBLISHED} and contents.updated_on >= ?", object.created_on])
      start_page = (prev_count / 50).to_i # TODO especificar esto en un único sitio
      end_page = start_page + next_count / 50 + 1

      for i in (start_page..end_page)
        expire_fragment("/common/foros/_topics_list/#{object.main_category.id}/page_#{i}")
      end

      expire_fragment("/common/foros/_topics_list/#{object.main_category.id}/page_")

      when 'Tournament'
      do_competitions(object)

      when 'Tutorial'
      expire_fragment('/home/index/articles')
      for p in object.get_related_portals;
        expire_fragment("/common/home/index/articles2b#{p.code}") if p.class.name == 'BazarDistrictPortal'
        expire_fragment("/#{p.code}/home/index/articles")
        expire_fragment("/#{p.code}/home/index/articles2")
      end

      # borramos las páginas de listados por si es un nuevo comment
      expire_fragment("/common/tutoriales/index/tutorials_#{object.main_category.id}/page_*")

      p = object.main_category
      while p do
        expire_fragment("/common/tutoriales/_latest_by_cat/#{p.id}")
        expire_fragment("/common/tutoriales/_most_productive_author_by_cat/#{p.id}")
        expire_fragment("/common/tutoriales/index/folders_#{p.id}")
        expire_fragment("/common/tutoriales/index/tutorials_#{p.id}/page_*")
        p = p.parent
      end

      object.get_related_portals.each do |p|
        expire_fragment("/#{p.code}/tutoriales/index/folders")
      end

      when 'User'
      if object.login_changed?
        expire_fragment(
            "/common/globalnavbar/#{object.id % 1000}/#{object.id}_avatar.cache")
      end
      if object.state_changed?
        expire_fragment("/common/carcel")
        expire_fragment("/common/carcel_full")
      end
      if object.faction_id_changed?
        Cache::Personalization.expire_quicklinks(object)
      end
      if object.state_changed?
        expire_fragment("/common/miembros/_rightside/ultimos_registros")
      end
      if object.avatar_id_changed?
        expire_fragment("/common/globalnavbar/#{object.id % 1000}/#{object.id}_avatar")
      end
    end
  end

  def self.expire_fragment(file)
    # como no podemos traernos un controller aquí nos hacemos una minifunción superhacked
    # TODO cambiar esto eeek usar url_for
    file = file.gsub('../', '') if file.class.name == 'String'

    fpath = "#{FRAGMENT_CACHE_PATH}/#{file}.cache"
    fmask = "#{FRAGMENT_CACHE_PATH}/#{file}"

    if File.file?(fpath) then
      begin; File.delete(fpath); rescue; end
    elsif File.directory?(File.dirname(fpath)) then
      for i in Dir.glob(fmask)
        if File.file?(i) then
          begin; File.delete(i); rescue; end
        end
      end
    else
      # raise "#{fpath} #{File.dirname(fpath)}"
    end
  end

  def expire_fragment(file)
    self.class.expire_fragment(file)
  end

  def self.user_may_have_joined_clan(user)
    expire_fragment("/common/globalnavbar/#{user.id % 1000}/#{user.id}_clans")
    expire_fragment("/common/globalnavbar/#{user.id % 1000}/#{user.id}_clans_box_en_member")
    expire_fragment("/_users/#{user.id % 1000}/#{user.id}/layouts/clans")
  end

  def self.update_pending_contents
    GlobalVars.update_var(
        "pending_contents",
        Content.count(:conditions => ["state = ?", Cms::PENDING]))
  end
end

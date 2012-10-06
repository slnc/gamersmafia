# -*- encoding : utf-8 -*-
module Comments

  SIMPLE_URL_REGEXP = /[a-zA-Z0-9_.:?#&%-\/]+/

  def self.require_user_can_comment_on_content(user, object)
    time1 = Time.now
    time_3_months_ago = time1 - 86400 * 90
    time_15_mins_ago = 60 * 15
    raise 'El contenido no está publicado. No se permiten nuevos comentarios.' if object.state == Cms::DELETED
    if object.closed
      if object.reason_to_close
        msg = "El contenido ha sido cerrado por <a href=\"#{Routing.gmurl(object.closed_by_user)}\">#{object.closed_by_user.login}</a> (Razón: #{object.reason_to_close}).<br />No se permiten nuevos comentarios."
      else
        msg = 'El contenido ha sido cerrado. No se permiten nuevos comentarios.'
      end
      raise msg
    end

    raise 'El topic tiene más de 3 meses de antigüedad y ha sido archivado. No se permiten nuevos comentarios.' if object.class == Topic and object.created_on < time_3_months_ago and not object.sticky

    if user.antiflood_level > -1 then
      max = (5 - user.antiflood_level) * 5
      cur = Comment.count(:conditions => "user_id = #{user.id} and created_on::date = now()::date")
      raise 'No puedes publicar más comentarios por hoy.' if cur >= max

      # esto debería estar fuera pero como el usuario está baneado de la facción
      # que se joda, no hacemos 2 queries por culpa de un 1% de los usuarios

    end
    game_id = object.unique_content.game_id
    if game_id
      contents_faction = Faction.find_by_game_id(game_id)
      raise 'Estás baneado de esta facción.' if contents_faction && contents_faction.user_is_banned?(user)
    end
  end

  # Cambia de tags html a bbcode
  def self.unformatize(str)
    str ||= ''
    newstr = str.clone
    # parsea comentarios de usuarios, líneas de chat, etc
    newstr.gsub!('<br />', "\n")
    newstr.gsub!(/(<(\/*)(blockquote)>)/i, '<\\2quote>')
    newstr.gsub!(/<pre class="brush: ([^"]+)">/i, '[code=\\1]')
    newstr.gsub!(/(<(\/*)(pre)>)/i, '[\\2code]') # TODO we don't preseve the class!
    newstr.gsub!(/(<(\/*)(b|i|code|quote)>)/i, '[\\2\\3]')
    newstr.gsub!(/<img class="icon" src="\/images\/flags\/([a-z]+).gif" \/>/i, '[flag=\\1]')
    newstr.gsub!(/<img src="([^"]+)" \/>/i, '[img]\\1[/img]')
    newstr.gsub!(/<a href="\/miembros\/([^"]+)">([^<]+)<\/a>/i, '[~\\1]')
    newstr.gsub!('url=www', 'url=http://www')
    newstr.gsub!(/<a href="([^"]+)">([^<]+)<\/a>/i, '[url=\\1]\\2[/url]')
    newstr.gsub!('&lt;', '<')
    newstr.gsub!('&gt;', '>')

    newstr
  end

  def self.fix_incorrect_bbcode_nesting(input)
    q = []
    #regexp = /(\[\/*(b|i|span|code|quote|img|url=[^\]]*|url)\])/i
    regexp = /(\[\/*(b|i|span|code=[^\]]*|code|quote|img|url=[^\]]*|url)\])/i
    next_idx = input.index(regexp)

    while next_idx
      m = regexp.match(input[next_idx..-1])
      bbcode = m[2][0..(m[2].index(/=|$/)-1)]      # get 'b' or 'quote'
      insertion = ''

      if m[0][1..1] != '/'
        q << bbcode
      else
        if bbcode.gsub('/', '') == q.last
          q.pop
        else
          insertion = "[#{bbcode}]"
          input = "#{input[0..next_idx-1]}#{insertion}#{input[next_idx..-1]}"
        end
      end

      next_idx += m[0].size + insertion.size
      next_idx = input.index(regexp, next_idx)
    end

    q.each do |bbcode|
      input = "#{input}[/#{bbcode}]"
    end
    input = input.gsub(/(\[(b|i|code|quote)\]\[\/(b|i|code|quote)\])/i, '')
    input
  end

  def self.formatize(str)
    # parsea comentarios de usuarios, líneas de chat, etc
    str ||= ''
    str = Comments.fix_incorrect_bbcode_nesting(str.clone)
    interword_regexp = /[^><]+/
    interword_regexp_strict = /[^\[]+/
    str.strip!
    str.gsub!(/</, '&lt;')
    str.gsub!(/>/, '&gt;')
    str.gsub!(/\r\n/, "<br />")
    str.gsub!(/\r/, "<br />\\n")
    str.gsub!(/\n/, "<br />\\n")
    str.gsub!(/(\[(\/*)(b|i|quote)\])/i, '<\\2\\3>')
    str.gsub!(/(<(\/*)(quote)>)/i, '<\\2blockquote>')
    str.gsub!(/(\[~(#{User::LOGIN_REGEXP_NOT_FULL})\])/, '<a href="/miembros/\\2">\\2</a>') # ~dharana >> <a href="/miembros/dharana">dharana</a>
    str.gsub!(/\[flag=([a-z]+)\]/i, '<img class="icon" src="/images/flags/\\1.gif" />')

    str.gsub!(/\[img\](#{SIMPLE_URL_REGEXP})\[\/img\]/i, '<img src="\\1" />')
    str.gsub!(/\[url=(#{SIMPLE_URL_REGEXP})\](#{interword_regexp_strict})\[\/url\]/i, '<a href="\\1">\\2</a>')

    str.gsub!(/\[color=([a-zA-Z]+)\](#{interword_regexp})\[\/color\]/i, '<span class="c_\\1">\\2</span>')

    str.gsub!(/\[code=([a-zA-Z0-9]+)\](.+?)\[\/code\]/i, '<pre class="brush: \\1">\\2</pre>')
    str.gsub!(/\[code\](.+?)\[\/code\]/i, '<pre class="brush: js">\\1</pre>')
    # remove any html tag inside a <code></code>

    str.gsub!(/<pre class="brush: [a-z]+">.*<\/pre>/) { |blck|
      code_part = blck.scan(/<pre class="brush: [a-z]+">(.*)<\/pre>/)[0][0].to_s.gsub("<", "&lt;").gsub(">", "&gt;").gsub("&lt;br /&gt;", "\n")
      brush_part = blck.scan(/<pre class="brush: ([a-z]+)">.*<\/pre>/)[0][0]
      "<pre class=\"brush: #{brush_part}\">#{code_part}<\/pre>"
    }

    str.gsub!("\\n", "\n")
    str.gsub!("\n\n", "\n")
    str
  end

  def self.user_can_moderate_comments_of_content(user, content)
    return true if user.has_skill?("Capo")

    f = Organizations.find_by_content(content)
    return true if f && f.user_is_moderator(user)

    real = content
    if (real.class.name == 'Event' &&
        (cm = CompetitionsMatch.find_by_event_id(real.id)) &&
        cm.competition.user_is_admin(user.id))
      true
    elsif (real.class.name == 'Coverage' &&
           (c = Competition.find_by_event_id(real.event_id)) &&
           c.user_is_admin(user.id))
      true
    else
      false
    end
  end

  def self.get_user_type_based_on_comments(user)
    ids_together = "SELECT a.id
                      FROM comments a
                     WHERE a.has_comments_valorations = 't'
                       AND a.deleted = 'f'
                       AND a.user_id = #{user.id} UNION SELECT 0"

    winner_direction_weight = User.db_query("select direction, sum(weight)
                                             from comments_valorations a join comments_valorations_types b on a.comments_valorations_type_id = b.id
                                            where comment_id IN (#{ids_together})
                                         group by direction order by sum desc limit 1")

    all_options_weight = User.db_query("SELECT sum(weight)
                                          FROM comments_valorations a
                                         WHERE comment_id IN (#{ids_together})")

    if winner_direction_weight.size == 0 || winner_direction_weight[0]['sum'].to_f < 0.10
      defval
    else
      winner_options_weight = User.db_query("select direction, comments_valorations_type_id, sum(weight)
                                             from comments_valorations a join comments_valorations_types b on a.comments_valorations_type_id = b.id
                                            where comment_id IN (#{ids_together}) and direction = #{winner_direction_weight[0]['direction']}
                                         group by direction, comments_valorations_type_id order by sum desc limit 1")

      [CommentsValorationsType.find(winner_options_weight[0]['comments_valorations_type_id'].to_i), winner_options_weight[0]['sum'].to_f / all_options_weight[0]['sum'].to_f]
    end
  end

  def self.get_user_comments_type(user, refobj)
    if refobj.class.name == 'Comment'
      content = refobj.content
      if content.clan_id
        refobj = content.clan
      elsif content.game_id
        refobj = content.my_faction
      else
        refobj = content.real_content
      end
    end

    # TODO SOY GILIPOLLAS
    # TODO esto es O(n) !!!!!
    case refobj.class.name
      when 'Blogentry'
      comments_ids = User.db_query("SELECT a.id
                                      FROM comments a join contents b on a.content_id = b.id
                                     WHERE a.has_comments_valorations = 't'
                                       AND a.user_id = #{user.id}
                                       AND b.content_type_id = (SELECT id FROM content_types WHERE name = 'Blogentry')")
      when 'Clan'
      comments_ids = User.db_query("SELECT a.id
                                      FROM comments a join contents b on a.content_id = b.id
                                     WHERE a.has_comments_valorations = 't'
                                       AND a.user_id = #{user.id}
                                       AND b.clan_id IS NOT NULL")

      when 'Faction'
      # TODO si refobj es Faction hay que cambiar la consulta
      comments_ids = User.db_query("SELECT a.id
                                      FROM comments a join contents b on a.content_id = b.id
                                     WHERE a.has_comments_valorations = 't'
                                       AND a.user_id = #{user.id}
                                       AND b.game_id = #{content.game_id}")

    else # General, la valoración media de este usuario
      # TODO: Debería ser la valoración de los contenidos de temática general
      # TODO: Diferenciar plataformas y competiciones de general
      comments_ids = User.db_query("SELECT a.id
                                      FROM comments a
                                     WHERE a.has_comments_valorations = 't'
                                       AND a.user_id = #{user.id}")
    end

    # TODO índices
    # TODO TEMP
    comments_ids.collect!{ |c| c['id'] }
    get_ratings_for_comments(comments_ids+[0])
  end

  def self.top_commenter_of_type_in_time_period(cvt, date_start, date_end, limit=10)
    date_start, date_end = date_end, date_start if date_start > date_end

    User.db_query("SELECT count(*) * count(distinct(a.user_id)) as m1,
                          b.user_id
                     FROM comments_valorations a
                     JOIN comments b ON a.comment_id = b.id
                    WHERE a.created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
                      AND a.comments_valorations_type_id = #{cvt.id}
                 GROUP BY b.user_id
                 ORDER BY m1 DESC LIMIT #{limit}").collect do |dbr|
      [dbr['m1'].to_i, User.find(dbr['user_id'].to_i)]
    end
  end

  def self.get_comments_ratings_for_content(content)
    comments_ids = content.comments_ids
    return defval if comments_ids.size == 0
    udata = get_ratings_for_comments(comments_ids)
    comments_total = content.cache_comments_count
    comments_rated = Comment.count(:conditions => "deleted = 'f' AND id IN (#{content.comments_ids.join(',')}) AND has_comments_valorations = 't'")

    return defval if comments_rated == 0 || comments_total == 0

    # Usamos log10 porque si no al multiplicar pesos 0<x<1 por factor 0<x<1 los pesos resultantes quedan ridículos.
    if comments_rated == comments_total
      normalized_weight = udata[1]
    else
      normalized_weight = udata[1]*Math.log10(comments_rated).to_f/Math.log10(comments_total)
    end

    if udata[0].name == 'Normal'
      # Si el peso ganador es Normal tenemos que hacer las cuentas de otra manera o los comentarios sin valorar (que consideramos normales) reducirán la normalidad ganadora.
      normalized_weight = (normalized_weight*comments_rated  + 1.0*(comments_total-comments_rated))/comments_total
    end

    if normalized_weight < 0.05
      defval
    else
      [udata[0], normalized_weight]
    end
  end

  def self.defval
    @@defval ||= [CommentsValorationsType.find_by_name('Normal'), 1.0]
    @@defval
  end

  def self.comments_ratings_for_user_in_object_in_page(user, object, page)
    res = {}
    User.db_query("select a.comment_id,
                          b.name
                     from comments_valorations a
                     join comments_valorations_types b on a.comments_valorations_type_id = b.id
                    where a.comment_id in (select id
                                             from comments
                                            where content_id = #{object.unique_content.id}
                                         order by created_on limit 30 offset #{(page-1)*30}) and a.user_id = #{user.id}").each do |dbr|
      res[dbr['comment_id'].to_i] = dbr['name']
    end
    res
  end

  def self.get_ratings_for_comments(comments_ids_array)
    ids_together = (comments_ids_array+[0]).join(',')

    winner_direction_weight = User.db_query("select direction, sum(weight)
                                             from comments_valorations a join comments_valorations_types b on a.comments_valorations_type_id = b.id
                                            where comment_id IN (#{ids_together})
                                         group by direction order by sum desc limit 1")

    all_options_weight = User.db_query("select sum(weight)
                                             from comments_valorations a
                                            where comment_id IN (#{ids_together})")

    if winner_direction_weight.size == 0 || winner_direction_weight[0]['sum'].to_f < 0.10
      defval
    else
      winner_options_weight = User.db_query("select direction, comments_valorations_type_id, sum(weight)
                                             from comments_valorations a join comments_valorations_types b on a.comments_valorations_type_id = b.id
                                            where comment_id IN (#{ids_together}) and direction = #{winner_direction_weight[0]['direction']}
                                         group by direction, comments_valorations_type_id order by sum desc limit 1")

      [CommentsValorationsType.find(winner_options_weight[0]['comments_valorations_type_id'].to_i), winner_options_weight[0]['sum'].to_f / all_options_weight[0]['sum'].to_f]
    end
  end

  @_cache_get_ratings_for_user = {}
  def self.get_ratings_for_user(user_id)
    @_cache_get_ratings_for_user[user_id] ||= begin
    winner_direction_weight = User.db_query("select direction, sum(weight)
                                               from comments_valorations a
                                               join comments_valorations_types b on a.comments_valorations_type_id = b.id
                                               join comments c on a.comment_id = c.id
                                              where c.user_id = #{user_id}
                                           group by direction order by sum desc limit 1")

    all_options_weight = User.db_query("select sum(weight)
                                               from comments_valorations a
                                               join comments_valorations_types b on a.comments_valorations_type_id = b.id
                                               join comments c on a.comment_id = c.id
                                              where c.user_id = #{user_id}")

    if winner_direction_weight.size == 0 || winner_direction_weight[0]['sum'].to_f < 0.01
      defval
    else
      winner_options_weight = User.db_query("select direction, comments_valorations_type_id, sum(weight)
                                             from comments_valorations a
                                               join comments_valorations_types b on a.comments_valorations_type_id = b.id
                                               join comments c on a.comment_id = c.id
                                            where c.user_id = #{user_id} AND direction = #{winner_direction_weight[0]['direction']}
                                         group by direction, comments_valorations_type_id order by sum desc limit 1")

      [CommentsValorationsType.find(winner_options_weight[0]['comments_valorations_type_id'].to_i), winner_options_weight[0]['sum'].to_f / all_options_weight[0]['sum'].to_f]
    end
    end
  end

  # TODO NO FUNCIONA
  def self.fix_malformed_comment(comment_text)
    new = comment_text.clone

    stack = []
    new.gsub!(/(\[.*?\])/m) do |element|
      clean_el = element.gsub(/([\[\]\/]+)/, '')
      if element.index('[/') == nil # abriendo
        stack.push(clean_el) # TODO meter solo b, i, url, etc
        element
      else # cerrando
        out = ''
        while stack.size > 0 && stack.last != clean_el
          out << "[/#{stack.pop}]"
        end
        if stack.size  == 0 # el elemento que se esta cerrando no existia, lo descartamos
          out
        else
          if out == ''
            stack.pop
            element
          else
            "#{out}[/#{clean_el}]"
          end
        end
      end
    end
    new
  end
end

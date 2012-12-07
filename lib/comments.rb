# -*- encoding : utf-8 -*-
module Comments

  def self.require_user_can_comment_on_content(user, object)
    time1 = Time.now
    time_3_months_ago = time1 - 86400 * 90
    time_15_mins_ago = 60 * 15
    if object.state == Cms::DELETED
      raise 'El contenido no está publicado. No se permiten nuevos comentarios.'
    end
    if object.closed
      if object.reason_to_close
        msg = (
            "El contenido ha sido cerrado por
            <a href=\"#{Routing.gmurl(object.closed_by_user)}\"
            >#{object.closed_by_user.login}</a> (Razón:
            #{object.reason_to_close}).
            <br />
            No se permiten nuevos comentarios.")
      else
        msg = 'El contenido ha sido cerrado. No se permiten nuevos comentarios.'
      end
      raise msg
    end

    if (object.class.name == "Topic" &&
        object.created_on < time_3_months_ago &&
        !object.sticky)
      raise ('El topic tiene más de 3 meses de antigüedad y ha sido archivado' +
             '. No se permiten nuevos comentarios.')
    end

    if user.antiflood_level > -1 then
      max = (5 - user.antiflood_level) * 5
      cur = user.comments.count(:conditions => "created_on::date = now()::date")
      raise 'No puedes publicar más comentarios por hoy.' if cur >= max

      # Esto debería estar fuera pero como el usuario está baneado de la facción
      # que se fastidie, no hacemos 2 queries por culpa de un 1% de los
      # usuarios.
    end

    game_id = object.game_id
    if game_id
      contents_faction = Faction.find_by_game_id(game_id)
      if contents_faction && contents_faction.user_is_banned?(user)
        raise 'Estás baneado de esta facción.'
      end
    end
  end

  def self.get_user_type_based_on_comments(user)
    ids_together = "
        SELECT a.id
        FROM comments a
        WHERE a.has_comments_valorations = 't'
        AND a.deleted = 'f'
        AND a.user_id = #{user.id}
        UNION
        SELECT 0"

    winner_direction_weight = User.db_query(
        "SELECT direction, SUM(weight) as sum
         FROM comments_valorations a
         JOIN comments_valorations_types b
         ON a.comments_valorations_type_id = b.id
         WHERE comment_id IN (#{ids_together})
         GROUP BY direction
         ORDER BY sum DESC
         LIMIT 1")

    all_options_weight = User.db_query(
        "SELECT sum(weight)
         FROM comments_valorations a
         WHERE comment_id IN (#{ids_together})")

    if (winner_direction_weight.size == 0 ||
        winner_direction_weight[0]['sum'].to_f < 0.10)
      defval
    else
      winner_options_weight = User.db_query(
          "SELECT direction,
             comments_valorations_type_id,
             SUM(weight)
           FROM comments_valorations a
           JOIN comments_valorations_types b
           ON a.comments_valorations_type_id = b.id
           WHERE comment_id IN (#{ids_together})
           AND direction = #{winner_direction_weight[0]['direction']}
           GROUP BY direction,
             comments_valorations_type_id
           ORDER BY sum DESC
           LIMIT 1")

      cvt_id = winner_options_weight[0]['comments_valorations_type_id'].to_i
      [CommentsValorationsType.find(cvt_id),
       winner_options_weight[0]['sum'].to_f / all_options_weight[0]['sum'].to_f]
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
        refobj = content
      end
    end

    # TODO SOY GILIPOLLAS
    # TODO esto es O(n) !!!!!
    case refobj.class.name
      when 'Blogentry'
      comments_ids = User.db_query(
          "SELECT a.id
           FROM comments a join contents b ON a.content_id = b.id
           WHERE a.has_comments_valorations = 't'
           AND a.user_id = #{user.id}
           AND b.content_type_id = (
              SELECT id FROM content_types WHERE name = 'Blogentry')")

      when 'Clan'
      comments_ids = User.db_query(
          "SELECT a.id
           FROM comments a join contents b on a.content_id = b.id
           WHERE a.has_comments_valorations = 't'
           AND a.user_id = #{user.id}
           AND b.clan_id IS NOT NULL")

      when 'Faction'
      # TODO si refobj es Faction hay que cambiar la consulta
      comments_ids = User.db_query(
          "SELECT a.id
           FROM comments a join contents b on a.content_id = b.id
           WHERE a.has_comments_valorations = 't'
           AND a.user_id = #{user.id}
           AND b.game_id = #{content.game_id}")

    else # General, la valoración media de este usuario
      # TODO: Debería ser la valoración de los contenidos de temática general
      # TODO: Diferenciar plataformas y competiciones de general
      comments_ids = User.db_query(
          "SELECT a.id
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

    User.db_query(
        "SELECT count(*) * count(distinct(a.user_id)) as m1,
           b.user_id
         FROM comments_valorations a
         JOIN comments b ON a.comment_id = b.id
         WHERE a.created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'
           AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
         AND a.comments_valorations_type_id = #{cvt.id}
         GROUP BY b.user_id
         ORDER BY m1 DESC
         LIMIT #{limit}").collect do |dbr|
      [dbr['m1'].to_i, User.find(dbr['user_id'].to_i)]
    end
  end

  def self.get_comments_ratings_for_content(content)
    comments_ids = content.comments_ids
    return defval if comments_ids.size == 0
    udata = get_ratings_for_comments(comments_ids)
    comments_total = content.cache_comments_count
    comments_rated = Comment.count(
        :conditions => "deleted = 'f'
                        AND id IN (#{content.comments_ids.join(',')})
                        AND has_comments_valorations = 't'")

    return defval if comments_rated == 0 || comments_total == 0

    # Usamos log10 porque si no al multiplicar pesos 0<x<1 por factor 0<x<1 los
    # pesos resultantes quedan ridículos.
    if comments_rated == comments_total
      normalized_weight = udata[1]
    else
      ratio_rated = Math.log10(comments_rated).to_f / Math.log10(comments_total)
      normalized_weight = udata[1] * ratio_rated
    end

    if udata[0].name == 'Normal'
      # Si el peso ganador es Normal tenemos que hacer las cuentas de otra
      # manera o los comentarios sin valorar (que consideramos normales)
      # reducirán la normalidad ganadora.
      numerator = (normalized_weight * comments_rated +
                   (comments_total - comments_rated))
      normalized_weight = numerator.to_f / comments_total
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
    User.db_query(
        "SELECT a.comment_id,
           b.name
         FROM comments_valorations a
         JOIN comments_valorations_types b
         ON a.comments_valorations_type_id = b.id
         WHERE a.comment_id in (
           SELECT id
           FROM comments
           WHERE content_id = #{object.id}
           ORDER BY created_on
           LIMIT 30 OFFSET #{(page-1)*30})
         AND a.user_id = #{user.id}").each do |dbr|
      res[dbr['comment_id'].to_i] = dbr['name']
    end
    res
  end

  def self.get_ratings_for_comments(comments_ids_array)
    ids_together = (comments_ids_array+[0]).join(',')

    winner_direction_weight = User.db_query(
        "SELECT direction, sum(weight)
         FROM comments_valorations a
         JOIN comments_valorations_types b
           ON a.comments_valorations_type_id = b.id
         WHERE comment_id IN (#{ids_together})
         GROUP BY direction
         ORDER BY sum DESC
         LIMIT 1")

    all_options_weight = User.db_query(
        "SELECT sum(weight)
         FROM comments_valorations a
         WHERE comment_id IN (#{ids_together})")

    if (winner_direction_weight.size == 0 ||
        winner_direction_weight[0]['sum'].to_f < 0.10)
      defval
    else
      winner_options_weight = User.db_query(
          "SELECT direction, comments_valorations_type_id, sum(weight)
           FROM comments_valorations a
           JOIN comments_valorations_types b
           ON a.comments_valorations_type_id = b.id
           WHERE comment_id IN (#{ids_together})
           AND direction = #{winner_direction_weight[0]['direction']}
           GROUP BY direction,
             comments_valorations_type_id
           ORDER BY sum DESC
           LIMIT 1")

      cvt_id = winner_options_weight[0]['comments_valorations_type_id'].to_i
      [CommentsValorationsType.find(cvt_id),
       winner_options_weight[0]['sum'].to_f / all_options_weight[0]['sum'].to_f]
    end
  end

  @_cache_get_ratings_for_user = {}
  def self.get_ratings_for_user(user_id)
    @_cache_get_ratings_for_user[user_id] ||= begin
    winner_direction_weight = User.db_query(
        "SELECT direction, sum(weight)
         FROM comments_valorations a
         JOIN comments_valorations_types b
         ON a.comments_valorations_type_id = b.id
         JOIN comments c on a.comment_id = c.id
         WHERE c.user_id = #{user_id}
         GROUP BY direction
         ORDER BY sum DESC
         LIMIT 1")

    all_options_weight = User.db_query(
        "SELECT SUM(weight)
         FROM comments_valorations a
         JOIN comments_valorations_types b
         ON a.comments_valorations_type_id = b.id
         JOIN comments c on a.comment_id = c.id
         WHERE c.user_id = #{user_id}")

    if (winner_direction_weight.size == 0 ||
        winner_direction_weight[0]['sum'].to_f < 0.01)
      defval
    else
      winner_options_weight = User.db_query(
          "SELECT direction, comments_valorations_type_id, SUM(weight)
           FROM comments_valorations a
           JOIN comments_valorations_types b
           ON a.comments_valorations_type_id = b.id
           JOIN comments c on a.comment_id = c.id
           WHERE c.user_id = #{user_id}
           AND direction = #{winner_direction_weight[0]['direction']}
           GROUP BY direction,
             comments_valorations_type_id
           ORDER BY sum DESC
           LIMIT 1")

      cvt_id = winner_options_weight[0]['comments_valorations_type_id'].to_i
      [CommentsValorationsType.find(cvt_id),
       winner_options_weight[0]['sum'].to_f / all_options_weight[0]['sum'].to_f]
    end
    end
  end
end

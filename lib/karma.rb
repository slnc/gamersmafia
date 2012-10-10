# -*- encoding : utf-8 -*-
module Karma
  POINTS_FIRST_LEVEL = 500
  INCREMENT_PER_LEVEL = 0.05
  KPS_CREATE = {
      'Bet'=> 40,
      'Blogentry'=> 20,
      'Column'=> 300,
      'Comment'=> 5,
      'Copypaste'=> 20,
      'Coverage'=> 30,
      'Demo'=> 40,
      'Download'=> 30,
      'Event'=> 30,
      'Funthing'=> 20,
      'Image'=> 5,
      'Interview'=> 500,
      'News'=> 60,
      'Poll'=> 40,
      'Question'=> 20,
      'RecruitmentAd'=> 20,
      'Review'=> 200,
      'Topic'=> 20,
      'Tutorial'=> 400,
  }

  KPS_SAVE = {
      'Bet'=> 10,
      'Column'=> 70,
      'Coverage'=> 10,
      'Demo'=> 10,
      'Download'=> 10,
      'Event'=> 10,
      'Funthing'=> 10,
      'Image'=> 10,
      'Interview'=> 70,
      'News'=> 10,
      'Poll'=> 10,
      'Question'=> 5,
      'Review'=> 40,
      'Tutorial'=> 70,
  }

  UGC_OLD_ENOUGH_FOR_KARMA_DAYS = 14

  def self.recalculate_karma
    # User.db_query("UPDATE users SET cache_karma_points = NULL")
    self.award_karma_points_new_ugc(false)
    # TODO(slnc): we need to recalculate factions and daily stats
  end

  def self.award_karma_points_new_ugc(give_gmfs=true)
    Content.published.find_each(
        :conditions => (
          "created_on <= NOW() - '#{UGC_OLD_ENOUGH_FOR_KARMA_DAYS}" +
          " days'::interval AND karma_points IS NULL")
    ) do |content|
      self.add_karma_after_content_is_published(content, give_gmfs)
    end

    Comment.karma_eligible.find_each(
        :conditions => (
          "created_on <= NOW() - '#{UGC_OLD_ENOUGH_FOR_KARMA_DAYS}" +
          " days'::interval AND karma_points IS NULL")
    ) do |content|
      self.add_karma_after_comment_is_created(content, give_gmfs)
    end
  end

  def self.kp_for_level(level)
   (POINTS_FIRST_LEVEL * level) + (
     (POINTS_FIRST_LEVEL * (level - 1)) * (INCREMENT_PER_LEVEL * level))
  end

  def self.pc_done_for_next_level(kp)
    cur_level = Karma.level(kp)
    kp_cur_lvl  = Karma.kp_for_level cur_level
    kp_next_lvl = Karma.kp_for_level(cur_level + 1)

    diff_100 = kp_next_lvl - kp_cur_lvl
    diff_done = kp - kp_cur_lvl

    return (100 * diff_done / diff_100).to_i
  end

  def self.level(kp)
    kp = kp.karma_points unless kp.is_a?(Fixnum)
    lvl = 0
    kp_for_lvl = 0

    if kp >= POINTS_FIRST_LEVEL
      while (kp > kp_for_lvl)
        lvl += 1
        kp_for_lvl = Karma.kp_for_level(lvl + 1)
      end
    end

    return lvl
  end

  def self.max_user_points
    User.db_query("SELECT max(cache_karma_points) FROM users")[0]['max'].to_i
  end

  def self.user_daily_karma(u, date_start, date_end)
    res = {}
    User.db_query("
        SELECT karma,
          created_on
        FROM stats.users_daily_stats
        WHERE user_id = #{u.id}
        AND created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'
          AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
        ORDER BY created_on").each do |dbr|
      res[dbr['created_on'][0..10]] = dbr['karma'].to_i
    end
    curdate = date_start
    curstr = curdate.strftime('%Y-%m-%d')
    endd = date_end.strftime('%Y-%m-%d')

    while curstr <= endd
      res[curstr] ||= 0
      curdate = curdate.advance(:days => 1)
      curstr = curdate.strftime('%Y-%m-%d')
    end
    res
  end

  def self.karma_points_of_users_at_date_range(date_start, date_end)
    date_start, date_end = date_end, date_start if date_start > date_end
    points = {}
    User.db_query("
        SELECT SUM(karma_points) AS karma_points,
          user_id
        FROM comments
        WHERE user_id NOT IN (
            SELECT user_id
            FROM users_skills
            WHERE role = 'Bot')
        AND created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'
          AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
        GROUP BY user_id").each do |dbc|
      points[dbc['user_id']] = dbc['karma_points'].to_i
    end

    # ahora contenidos
    User.db_query("
        SELECT SUM(karma_points) AS karma_points,
          user_id,
          content_type_id
        FROM contents
        WHERE user_id NOT IN (
            SELECT user_id
            FROM users_skills
            WHERE role = 'Bot')
        AND created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'
          AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
        GROUP BY user_id, content_type_id").each do |dbc|
      points[dbc['user_id']] ||= 0
      points[dbc['user_id']] += dbc['karma_points'].to_i
    end

    points
  end

  def self.karma_points_of_user_at_date(user, date)
    # devuelve un array
    # [-1][50] 50 puntos en el portal con id -1
    points = {}
    User.db_query("
        SELECT SUM(karma_points) AS karma_points,
          portal_id
        FROM comments
        WHERE user_id = #{user.id}
        AND DATE_TRUNC('day', created_on) = '#{date.strftime('%Y-%m-%d')} 00:00:00'
        GROUP BY portal_id").each do |dbc|
      points[dbc['portal_id']] = dbc['karma_points'].to_i
    end

    # ahora contenidos
    User.db_query("
        SELECT SUM(karma_points) AS karma_points,
          portal_id,
          content_type_id
        FROM contents
        WHERE user_id = #{user.id}
        AND DATE_TRUNC('day', created_on) = '#{date.strftime('%Y-%m-%d')} 00:00:00'
        GROUP BY portal_id, content_type_id").each do |dbc|
      points[dbc['portal_id']] ||= 0
      points[dbc['portal_id']] += dbc['karma_points'].to_i
    end

    points
  end

  def self.regenerate_users_karma_points
    i = 0
    User.find_each do |u|
      u.update_column(:cache_karma_points, self.calculate_karma_points(u))
      i += 1
      puts i if i % 1000 == 0
    end
  end

  def self.calculate_karma_points(thing, other_conditions=nil)
    opts = other_conditions ? {:conditions => other_conditions} : {}
    if thing.kind_of?(User)
      (thing.contents.sum('karma_points', opts) +
       thing.comments.sum('karma_points', opts))
    elsif thing.kind_of?(Faction)
      # Para cada contenido calculamos el total de elementos que salgan de
      # nuestra categoría base y a la vez calculamos los puntos por comentarios
      # (requiere que cache_karma_points != NULL)
      rthing = thing.referenced_thing
      sql_other_conditions = other_conditions ? " AND #{other_conditions}" : ""
      comments_karma = Comment.sum(
          :karma_points,
          :conditions => "
              content_id IN (
                SELECT id
                FROM contents
                WHERE #{thing.referenced_thing_field} = #{rthing.id})
              #{sql_other_conditions}")
      root_term = Term.single_toplevel(
          thing.referenced_thing_field => rthing.id)
      total = (
          Content.in_term_tree(root_term).sum(:karma_points, opts) +
          comments_karma)
    elsif thing.class.kind_of?(ActsAsContent::AddActsAsContent)
      if other_conditions
        raise "Unable to pass other_conditions for acts_as_content"
      end
      (karma_points, trace) = Karma.contents_karma(thing.unique_content)
      karma_points
    else
      raise "calculate_karma_points of unsupported class #{thing.class.name}."
    end
  end

  def self.give(user, points)
    self.modify_user_karma(user, points, "+")
  end

  def self.take(user, points)
    self.modify_user_karma(user, points, "-")
  end

  def self.modify_user_karma(user, points, operation)
    raise TypeError unless (user.kind_of?(User) and points.kind_of?(Fixnum))
      raise ArgumentError("#{points} <= 0") unless points > 0

    # forzamos el cálculo desde 0, esto sí que puede incurrir en race condition
    user.karma_points
    user.cache_karma_points = User.db_query("
        UPDATE users
        SET cache_karma_points = cache_karma_points #{operation} #{points}
        WHERE id = #{user.id};

        SELECT cache_karma_points
        FROM users
        WHERE id = #{user.id}")[0]['cache_karma_points'].to_i
  end

  def self.ranking_user(u)
    total = User.can_login.count
    pos = u.ranking_karma_pos || total
    {:pos => pos, :total => total}
  end

  def self.update_ranking
    users_by_karma = {}
    old_ranks = {}
    User.can_login.each do |user|
      users_by_karma[user.karma_points] ||= []
      users_by_karma[user.karma_points] << user.id
      old_ranks[user.id] = user.ranking_karma_pos
    end

    pos = 1
    users_by_karma.keys.sort.reverse.each do |k|
      # In case of tie older users come first.
      users_by_karma[k].sort.each do |uid|
        if old_ranks[uid] != pos
          User.db_query(
            "UPDATE users SET ranking_karma_pos = #{pos} WHERE id = #{uid}")
        end
        pos += 1
      end
    end
  end

  # Karma points are a weighted sum of unique users commenting on the content
  # and the rating of that content. Contents belonging to portals with more
  # active users have a higher starting karma points.
  # content: a Content object.
  def self.contents_karma(content)
    content_commentators = User.db_query(
        "SELECT COUNT(DISTINCT(user_id)) as count
         FROM comments
         WHERE content_id = #{content.id}
         AND created_on <= (
              SELECT created_on
              FROM contents
              WHERE id = #{content.id}) + '2 weeks'::interval")[0]['count'].to_f

    recent_portal_commentators = User.db_query(
        "SELECT COUNT(DISTINCT(user_id)) as count
         FROM comments
         WHERE portal_id = #{content.portal_id}
         AND created_on BETWEEN (
           SELECT created_on
           FROM contents
           WHERE id = #{content.id}) AND (
           SELECT created_on
           FROM contents
           WHERE id = #{content.id}) + '2 weeks'::interval")[0]['count'].to_f

    ratings = content.content_ratings.count
    if ratings >= 3
      rating =  content.content_ratings.average(
          :rating,
          :conditions => "created_on <= (
              SELECT created_on
              FROM contents
              WHERE id = #{content.id}) + '2 weeks'::interval")
      rating = 0 if rating.nil?
      w_ratings = 0.5
      w_comments = 0.5
    else
      ratings = 0  # that way they don't affect w_comments
      rating = 0
      w_ratings = 0
      w_comments = 0.7
    end

    recent_portal_commentators = 1 if recent_portal_commentators == 0
    users_ratio = Math.log10(
        10.0 * content_commentators / recent_portal_commentators)
    users_ratio = content_commentators/recent_portal_commentators
    if users_ratio < 0 && content_commentators > 0
      users_ratio = 0.1
    end
    users_ratio = 0 if users_ratio < 0

    if (content.source)
      kpc = Karma::KPS_CREATE['Copypaste']
    else
      kpc = Karma::KPS_CREATE[content.content_type.name]
    end

    portal_factor = Math.log10(recent_portal_commentators)
    comments_factor = w_comments * users_ratio
    ratings_factor = w_ratings * (rating / 10.0)
    karma = (kpc * portal_factor * (comments_factor + ratings_factor)).ceil

    # We compute debugging line
    portal_factor_explained = "%.2f" % portal_factor
    users_ratio_explained = "%.2f" % users_ratio
    comments_factor_explained = "#{w_comments} * #{users_ratio_explained}"
    ratings_factor_explained = "#{w_ratings} * (#{rating/10.0})"
    karma_explained = (
        "#{kpc} * #{portal_factor_explained} * (#{comments_factor_explained}" +
        " + #{ratings_factor_explained}):  # usuarios:" +
        " #{content_commentators} de #{recent_portal_commentators}," +
        " valoración: #{rating}")

    [karma, karma_explained]
  end

  def self.add_karma_after_content_is_published(content, give_gmfs=true)
    if !content.karma_points.nil?
      raise "content #{content.id} already has karma points."
    end

    if (content.karma_points ||
        content.created_on > UGC_OLD_ENOUGH_FOR_KARMA_DAYS.days.ago)
      return
    end

    (karma_points, trace_log) = self.contents_karma(content)
    if !content.update_column(:karma_points, karma_points)
      raise ("Error adding karma_points to content:" +
             " #{content.errors.full_messages_html}")
    end
    return if karma_points == 0

    user = content.user
    Karma.give(user, karma_points.to_i)
    return if !give_gmfs
    Bank.transfer(
        :bank,
        user,
        Bank::convert(karma_points, 'karma_points'),
        "Karma por resultar aceptado \"#{content.name}\"" +
        " (#{Cms::CLASS_NAMES[content.real_content.class.name]})")
  end

  def self.del_karma_after_content_is_unpublished(content)
    return if content.karma_points.nil?

    old_karma_points = content.karma_points
    if !content.frozen?
      content.update_column(:karma_points, nil)
    end
    return if old_karma_points == 0

    user = content.user
    Karma.take(user, old_karma_points.to_i)
    Bank.transfer(
        user,
        :bank,
        Bank::convert(old_karma_points, 'karma_points'),
        "Devolución de karma por contenido despublicado:" +
        " #{content.name}" +
        " (#{Cms::CLASS_NAMES[content.real_content.class.name]})")
  end

  def self.comment_karma(comment)
    return nil if !comment.karma_eligible?

    positive_ratings = comment.comments_valorations.positive.count(
        :conditions => "
            created_on <= (
              SELECT created_on
              FROM comments
              WHERE id = #{comment.id}) +
                         '#{UGC_OLD_ENOUGH_FOR_KARMA_DAYS} days'::interval")

    if positive_ratings == 0
      0
    else
      (positive_ratings ** Math.log10(positive_ratings)).ceil
    end
  end

  def self.add_karma_after_comment_is_created(comment, give_gmfs=true)
    if !comment.karma_points.nil?
      raise "Comment #{comment.id} already has karma points."
    end

    if (comment.karma_points ||
        comment.created_on > UGC_OLD_ENOUGH_FOR_KARMA_DAYS.days.ago)
      return
    end

    karma_points = self.comment_karma(comment)
    if !comment.update_column(:karma_points, karma_points)
      raise ("Error adding karma_points to comment:" +
             " #{comment.errors.full_messages_html}")
    end
    return if karma_points == 0

    u = comment.user
    Karma.give(u, karma_points.to_i)
    return if !give_gmfs
    Bank.transfer(
        :bank,
        u,
        Bank::convert(karma_points, 'karma_points'),
        "Karma por comentario a #{comment.content.real_content.resolve_hid}" +
        " (#{Cms::CLASS_NAMES[comment.content.real_content.class.name]})")
  end

  def self.del_karma_after_comment_is_deleted(comment)
    old_points = comment.karma_points
    return if old_points == 0

    u = comment.user
    Karma.take(u, old_points.to_i)

    new_cash = Bank::convert(old_points, 'karma_points')
    return if new_cash == 0

    Bank.transfer(
        u,
        :bank,
        new_cash,
        "Devolución de Karma por comentario borrado a" +
        " #{comment.content.real_content.resolve_hid}" +
        " (#{Cms::CLASS_NAMES[comment.content.real_content.class.name]})")
  end

  def self.karma_in_time_period(t1, t2, other_conditions=nil)
    points = 0
    cond = {
        :conditions => "karma_points > 0 AND
                        created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}'
                          AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'",
    }
    cond[:conditions] += " AND #{other_conditions}" if other_conditions
    Content.sum(:karma_points, cond) + Comment.sum(:karma_points, cond)
  end

  def self.faction_karma_in_time_period(faction, t1, t2)
    time_condition = "created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}'
                        AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'"
    self.calculate_karma_points(faction, time_condition)
  end
end

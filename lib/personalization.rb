# -*- encoding : utf-8 -*-
# This library is in charge of handling quicklinks (shortcuts to portals) and
# user forums (forums shown on the forums homepage).
module Personalization
  MAX_QUICKLINKS = 10

  def self.get_default_quicklinks
    # TODO(slnc): PERF compute this in the background
    @_cached_quicklinks_anon ||= begin
    qlinks = []
    User.db_query(
      "SELECT count(*) as cnt,
         portal_id
       FROM stats.pageviews
      WHERE created_on >= now() - '3 days'::interval
      GROUP BY portal_id
      ORDER BY cnt desc
      LIMIT 20;").collect {|dbr|
      next if dbr["portal_id"].to_i < 1
      break if qlinks.size > 15
      portal = Portal.find(dbr["portal_id"].to_i)
      qlinks.append({
        :code => portal.code,
        :url => "http://#{portal.code}.#{App.domain}",
      })
    }
    qlinks.sort_by {|qlink| qlink[:code].downcase}
    end
    @_cached_quicklinks_anon
  end

  def self.default_user_forums
    # TODO aqui se podria aplicar inteligencia en base al historial de
    # navegación del usuario.
    # TODO no tenemos updated_on en terms asi que usamos el id del ultimo el
    # actualizado para elegir los foros por defecto.
    Term.find(
        :all,
        :conditions => 'id = root_id',
        :order => 'last_updated_item_id DESC',
        :limit => 12).collect {|tc| tc.id }.chunk(3)
  end

  def self.get_user_forums(user)
    forums = user.pref_user_forums
    forums.size > 0 ? forums : [[], [], []]
  end

  def self.update_user_forums_order(u, bucket1, bucket2, bucket3)
    u.pref_user_forums = [
        bucket1.collect {|i| i.to_i},
        bucket2.collect {|i| i.to_i},
        bucket3.collect {|i| i.to_i}
    ]
  end

  def self.add_user_forum(user, forum_id, link)
    forum_id = forum_id.to_i unless forum_id.kind_of?(Fixnum)
    user_forums = self.get_user_forums(user)
    user_forums[0] = user_forums[0].each {|ql| return if ql == forum_id}
    user_forums[1] = user_forums[1].each {|ql| return if ql == forum_id}
    user_forums[2] = user_forums[2].each {|ql| return if ql == forum_id}
    if user_forums[1].size < user_forums[0].size
      dst = 1
    elsif (user_forums[2].size < user_forums[1].size)
      dst = 2
    else
      dst = 0
    end

    user_forums[dst] << forum_id.to_i
    user.pref_user_forums = user_forums
  end

  def self.del_user_forum(user, forum_id)
    forum_id = forum_id.to_i unless forum_id.kind_of?(Fixnum)
    user_forums = self.get_user_forums(user)
    user_forums[0] = user_forums[0].delete_if {|a| a == forum_id}
    user_forums[1] = user_forums[1].delete_if {|a| a == forum_id}
    user_forums[2] = user_forums[1].delete_if {|a| a == forum_id}
    user.pref_user_forums = user_forums
  end
end

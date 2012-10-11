# -*- encoding : utf-8 -*-
class UserEmblemObserver < ActiveRecord::Observer
  observe Comment,
          CommentsValoration,
          User

  def after_create(o)
    case o.class.name
    when 'Comment'
      UserEmblemObserver::Emblems.comments_count(o.user)

    when 'CommentsValoration'
      UserEmblemObserver::Emblems.comments_valorations(o.user)
    end
  end

  def after_save(o)
    case o.class.name
    when 'User'
      UserEmblemObserver::Emblems.the_beast(o)
    end
  end

  module Emblems
    def self.give_emblem_if_not_present(user, emblem)
      if !user.has_emblem?(emblem)
        user.users_emblems.create(:emblem => emblem)
      end
    end

    SQL_COMMENTS_VALORATIONS = "
    SELECT count(*) as cnt
    FROM (
      SELECT comment_id, (
        SELECT COUNT(distinct(user_id))
        FROM comments_valorations as b
        WHERE comment_id = a.comment_id) - 1 AS uniq_users
      FROM comments_valorations AS a
      WHERE user_id = ##USER_ID
      AND (
        SELECT COUNT(DISTINCT(user_id))
        FROM comments_valorations AS b
        WHERE comment_id = a.comment_id) - 1 >= ##MIN_USERS) as foo;
    "
    def self.comments_valorations(user)
      return if user.has_emblem?("comments_valorations_3")

      self.give_emblem_if_not_present(user, "comments_valorations_1")

      if !user.has_emblem?("comments_valorations_2")
        sql_tpl = SQL_COMMENTS_VALORATIONS.
          gsub("##USER_ID", user.id.to_s).
          gsub("##MIN_USERS", UsersEmblem::T_COMMENT_VALORATIONS_2_MATCHING_USERS.to_s)
        valorations = User.db_query(sql_tpl)[0]['cnt'].to_i
        if valorations >= UsersEmblem::T_COMMENT_VALORATIONS_2
          self.give_emblem_if_not_present(user, "comments_valorations_2")
        end
      end

      sql_tpl = SQL_COMMENTS_VALORATIONS.
        gsub("##USER_ID", user.id.to_s).
        gsub("##MIN_USERS", UsersEmblem::T_COMMENT_VALORATIONS_3_MATCHING_USERS.to_s)
      valorations = User.db_query(sql_tpl)[0]['cnt'].to_i
      if valorations >= UsersEmblem::T_COMMENT_VALORATIONS_3
        self.give_emblem_if_not_present(user, "comments_valorations_3")
      end
    end

    def self.comments_count(user)
      return if user.has_emblem?("comments_count_3")

      comments_count = user.comments.visible.count
      if comments_count >= UsersEmblem::T_COMMENTS_COUNT_1
        self.give_emblem_if_not_present(user, "comments_count_1")
      end
      if comments_count >= UsersEmblem::T_COMMENTS_COUNT_2
        self.give_emblem_if_not_present(user, "comments_count_2")
      end
      if comments_count >= UsersEmblem::T_COMMENTS_COUNT_3
        self.give_emblem_if_not_present(user, "comments_count_3")
      end
    end

    def self.the_beast(user)
      # TODO(slnc): esto no funciona ahora porque no actualizamos
      # cache_karma_points por update_attribute.
      if (user.cache_karma_points_changed? &&
          user.cache_karma_points.to_i >= UsersEmblem::T_THE_BEAST_KARMA_POINTS)
        self.give_emblem_if_not_present(user, "the_beast")
      end
    end

    # This function is called from daily rakes as we have to do this
    # asynchronously.
    def self.check_user_referers_candidates
      User.db_query(
          "SELECT id, (
             SELECT count(*)
             FROM users
             WHERE referer_user_id = a.id
             AND lastseen_on >= created_on + '30 days'::interval
             AND comments_count > 0) as refered_users
          FROM users a
          WHERE (
             SELECT count(*)
             FROM users
             WHERE referer_user_id = a.id
             AND lastseen_on >= created_on + '30 days'::interval
             AND comments_count > 0) > 0").each do |dbrow|
        user = User.find(dbrow['id'].to_i)
        refered_30d_active = dbrow['refered_users'].to_i

        if refered_30d_active >= UsersEmblem::T_REFERER_1
          self.give_emblem_if_not_present(user, "user_referer_1")
        end
        if refered_30d_active >= UsersEmblem::T_REFERER_2
          self.give_emblem_if_not_present(user, "user_referer_2")
        end
        if refered_30d_active >= UsersEmblem::T_REFERER_3
          self.give_emblem_if_not_present(user, "user_referer_3")
        end
      end
    end
  end
end

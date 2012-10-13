# -*- encoding : utf-8 -*-
class UserEmblemObserver < ActiveRecord::Observer
  observe Comment,
          CommentsValoration,
          Content,
          User

  def after_create(o)
    case o.class.name
    when 'Comment'
      UserEmblemObserver::Emblems.delay.comments_count(o.user)

    when 'CommentsValoration'
      UserEmblemObserver::Emblems.delay.comments_valorations_creator(o.user)
      if o.comments_valorations_type.direction == 1
        UserEmblemObserver::Emblems.delay.comments_valorations_receiver(
            o.comments_valorations_type, o.comment.user)
      end
    end
  end

  def after_save(o)
    case o.class.name
    when 'Content'
      if o.state_changed? && o.state == Cms::PUBLISHED
        Emblems.give_emblem_if_not_present(o.user, "first_content")
      end
      if o.karma_points_changed? && o.karma_points > 0
        Emblems.check_suv(o.user)
      end
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
    def self.comments_valorations_creator(user)
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

    def self.check_suv(user)
      rows = User.db_query(
          "SELECT count(*), content_type_id
          FROM contents
          WHERE state = #{Cms::PUBLISHED}
          AND user_id = #{user.id}
          AND karma_points >= #{UsersEmblem::T_SUV_MIN_KARMA_POINTS}
          GROUP BY content_type_id")

      if rows.size == ContentType.count
        self.give_emblem_if_not_present(user, "suv")
      end
    end

    def self.comments_valorations_receiver(cvt, user)
      downcased_named = cvt.name.downcase
      if user.has_emblem?("comments_valorations_received_#{downcased_named}_3")
        return
      end
      sql_query = "
        SELECT count(*) as valorations,
          COUNT(distinct(comment_id)) as unique_comments,
          COUNT(distinct(user_id)) as unique_users
        FROM comments_valorations
        WHERE comment_id in (
          SELECT id
          FROM comments
          WHERE user_id = #{user.id})
        AND comments_valorations_type_id = #{cvt.id};
      "
      dbr = User.db_query(sql_query)[0]
      valorations = dbr["valorations"].to_i
      unique_comments = dbr["unique_comments"].to_i
      unique_users = dbr["unique_users"].to_i
      if valorations >= UsersEmblem::T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_1 &&
        unique_comments >= UsersEmblem::T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1 &&
        unique_users >= UsersEmblem::T_COMMENT_VALORATIONS_RECEIVED_USERS_1
        self.give_emblem_if_not_present(
            user, "comments_valorations_received_#{downcased_named}_1")
      end
      if valorations >= UsersEmblem::T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_2 &&
        unique_comments >= UsersEmblem::T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2 &&
        unique_users >= UsersEmblem::T_COMMENT_VALORATIONS_RECEIVED_USERS_2
        self.give_emblem_if_not_present(
            user, "comments_valorations_received_#{downcased_named}_2")
      end
      if valorations >= UsersEmblem::T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_3 &&
        unique_comments >= UsersEmblem::T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3 &&
        unique_users >= UsersEmblem::T_COMMENT_VALORATIONS_RECEIVED_USERS_3
        self.give_emblem_if_not_present(
            user, "comments_valorations_received_#{downcased_named}_3")
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

    def self.rockefeller(user)
      if user.cash >= UsersEmblem::T_ROCKEFELLER
        # Discount transfers from users from the last 3 months
        amount_from_users = CashMovement.sum(
            :ammount,
            :conditions => ["object_id_from is not null AND
                             object_id_to_class = 'User' AND
                             object_id_to = ? AND
                             created_on >= now() - '3 months'::interval",
                            user.id])
        if user.cash - amount_from_users >= UsersEmblem::T_ROCKEFELLER
          self.give_emblem_if_not_present(user, "rockefeller")
        end
      end
    end

    def self.the_beast(user)
      if user.cache_karma_points.to_i >= UsersEmblem::T_THE_BEAST_KARMA_POINTS
        self.give_emblem_if_not_present(user, "the_beast")
      end
    end

    def self.daily_checks
      # Rockefeller
      User.find_each(
          :conditions => ["cash >= ?", UsersEmblem::T_ROCKEFELLER]) do |user|
            self.rockefeller(user)
      end

      # The Beast
      User.find_each(
          :conditions => ["cache_karma_points >= ?",
                          UsersEmblem::T_THE_BEAST_KARMA_POINTS]) do |user|
            self.the_beast(user)
      end

      self.check_user_referers_candidates
      self.check_karma_rage
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

    def self.check_karma_rage(last_day=nil)
      days_back = (
          UsersEmblem::T_KARMA_RAGE_3 +
          Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS)
      first_day = days_back.days.ago.beginning_of_day
      if last_day.nil?
        last_day = Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS.days.ago.end_of_day
      end
      Karma.users_who_generated_karma_on(last_day).each do |user|
        grouped_by_day = Karma.daily_karma_in_period(user, first_day, last_day)

        # Now we look for the longest sequence
        longest = 0
        current = 0
        grouped_by_day.keys.sort.each do |key|
          if grouped_by_day[key] == 0
            longest = current
            current = 0
          else
            longest += 1
          end
        end

        if longest >= UsersEmblem::T_KARMA_RAGE_1
          self.give_emblem_if_not_present(user, "karma_rage_1")
        end
        if longest >= UsersEmblem::T_KARMA_RAGE_2
          self.give_emblem_if_not_present(user, "karma_rage_2")
        end
        if longest >= UsersEmblem::T_KARMA_RAGE_3
          self.give_emblem_if_not_present(user, "karma_rage_3")
        end

      end
    end

  end
end

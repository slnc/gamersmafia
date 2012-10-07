# -*- encoding : utf-8 -*-
class UserEmblemObserver < ActiveRecord::Observer
  observe Comment

  def after_create(o)
    case o.class.name
    when 'Comment'
      UserEmblemObserver::Emblems.comments_count(o.user)
    end
  end

  module Emblems
    def self.give_emblem_if_not_present(user, emblem)
      if !user.has_emblem?(emblem)
        user.users_emblems.create(:emblem => emblem)
      end
    end

    def self.comments_count(user)
      return if user.has_emblem?("comments_count_3")

      comments_count = user.comments.karma_eligible.count
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
  end

end

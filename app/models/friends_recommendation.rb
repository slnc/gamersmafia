# -*- encoding : utf-8 -*-
class FriendsRecommendation < ActiveRecord::Base
  belongs_to :user
  belongs_to :recommended_user, :class_name => 'User', :foreign_key => 'recommended_user_id'

  validates_presence_of :user_id, :recommended_user_id
  validates_uniqueness_of :user_id, :scope => :recommended_user_id

  def add_friend
    self.update_attributes(:added_as_friend => true)
    f = Friendship.find_between(self.user, self.recommended_user)
    Friendship.create({:sender_user_id => self.user_id, :receiver_user_id => self.recommended_user_id}) if f.nil?
    check_remaining_recommendations
  end

  def not_friend
    self.update_attributes(:added_as_friend => false)
    check_remaining_recommendations
  end

  def check_remaining_recommendations
    if FriendsRecommendation.count(:conditions => ['user_id = ? AND added_as_friend IS NULL', self.user_id]) < MIN_REMAINING_FRIENDSHIPS
      FriendsRecommendation.gen_more_recommendations(self.user)
    end
  end

  def self.users_are_now_not_friends(sender, receiver)
    # si uno dice que no conoce al otro asumimos que el otro no conoce al uno y marcamos
    return if receiver.nil? || sender.nil?
    FriendsRecommendation.find(:all,
                               :conditions => ['added_as_friend IS NULL
                                            AND (user_id = ? AND recommended_user_id = ?)
                                             OR (user_id = ? AND recommended_user_id = ?)', sender.id, receiver.id, receiver.id, sender.id]).each {|fr| fr.not_friend }
  end

  def self.users_are_now_friends(sender, receiver)
    # si uno dice que es amigo del otro asumimos que el otro no es amigo del uno
    FriendsRecommendation.find(:all,
                               :conditions => ['added_as_friend IS NULL
                                            AND (user_id = ? AND recommended_user_id = ?)
                                             OR (user_id = ? AND recommended_user_id = ?)', sender.id, receiver.id, receiver.id, sender.id]).each {|fr| fr.not_friend }
  end

  FRIENDS_TO_GEN_PER_ITERATION = 6
  MIN_REMAINING_FRIENDSHIPS = 6

  def self.gen_more_recommendations(user)
    generated = 0
    # TODO same clan members
    friends_ids_sql = user.friends_ids_sql
    # TODO PERF hay que hacer una tabla y meter las recomendaciones ahí, rejected_friends no es escalable
    rejected_friends = User.db_query("SELECT recommended_user_id FROM friends_recommendations WHERE user_id = #{user.id}").collect { |dbr| dbr['recommended_user_id'].to_i }

    rejected_friends << 0
    user.clans.each do |clan|
      User.find(:all, :conditions => "id <> #{user.id} AND id NOT IN (#{friends_ids_sql}) AND id NOT IN (#{rejected_friends.join(',')})
                                  AND id IN (#{clan.all_users_of_this_clan_sql})").each do |u|
        break if generated >= FRIENDS_TO_GEN_PER_ITERATION
        user.friends_recommendations.create(:recommended_user_id => u.id, :reason => "Es tu compañero de clan en #{clan.tag}")
        generated += 1
      end
      break if generated >= FRIENDS_TO_GEN_PER_ITERATION
    end
    return if generated >= FRIENDS_TO_GEN_PER_ITERATION

    # friends of your friends
    # TODO miembros de misma faccion
    User.find(:all, :conditions => "random() > random_id AND id <> #{user.id} AND
                                           id in ((select sender_user_id
                          from friendships
                           where receiver_user_id in (#{friends_ids_sql}) AND accepted_on IS NOT NULL)
                            UNION (select receiver_user_id
                          from friendships
                           where sender_user_id in (#{friends_ids_sql}) AND accepted_on IS NOT NULL)
                           )
                     and id not in (#{friends_ids_sql})
                     AND id NOT IN (#{rejected_friends.join(',')})
                     and state NOT IN (#{User::STATES_CANNOT_LOGIN.join(',')})",
    :order => 'random_id', :limit => (FRIENDS_TO_GEN_PER_ITERATION - generated)).each do |u|
      break if generated >= FRIENDS_TO_GEN_PER_ITERATION
      user.friends_recommendations.create(:recommended_user_id => u.id, :reason => "Es amigo de un amigo")
      generated += 1
    end
  end
end

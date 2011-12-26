class UsersNewsfeed < ActiveRecord::Base
  MAX_NEW_ITEMS_PER_7DAYS = 50
  MAX_PER_BUCKET_ITEMS = 5

  belongs_to :users_action

  scope :old, :conditions => "created_on < now() - '1 month'::interval"

  def self.process
    # Actualiza el apartado "En tu Red" para todos los usuarios activos
    User.recently_active.find(:all).each do |u|
      process_single_user(u)
    end
    nil
  end

  def self.process_single_user(user)
    # cogemos todos los eventos que no han visto desde la ultima vez que
    # procesamos la newsfeed para ellos
    feed = user.users_newsfeeds.find(:first,
                                     :order => 'users_newsfeeds.created_on' +
                                               ' DESC',
                                     :include => :users_action)
    if feed && feed.users_action.nil?
      logger.warn "No users_action found for UsersNewsfeed.id = #{feed.id}."
      feed.destroy
      feed = nil
    end

    starting_on = feed.nil? ? user.created_on : feed.users_action.created_on
    buckets = {}

    # metemos todos los eventos en cestas
    UsersAction.find(:all,
                     :conditions => ["created_on > ? AND
                                      user_id IN (#{user.friends_ids_sql})",
                                     starting_on]).each do |ua|
      buckets[ua.type_id] ||= {}
      buckets[ua.type_id][ua.user_id] ||= []
      buckets[ua.type_id][ua.user_id] << ua
      # para evitar storm por si alguien sube 100 imgs
      next if buckets[ua.type_id][ua.user_id].size > MAX_PER_BUCKET_ITEMS
      user.users_newsfeeds.create(:created_on => ua.created_on,
                                  :summary => ua.data,
                                  :users_action_id => ua.id)
    end
  end
end

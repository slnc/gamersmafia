class UsersNewsfeed < ActiveRecord::Base
  MAX_NEW_ITEMS_PER_7DAYS = 50
  belongs_to :users_action
  
  def self.process
    # buscamos todos los users activos durante la última semana
    User.find(:all, :conditions => 'lastseen_on >= now() - \'1 week\'::interval').each do |u|
      process_single_user(u)
    end
    nil 
    # TODO generar tb mensajes para usuarios activos durante el ultimo mes
  end
  
  def self.process_single_user(u)
    # cogemos todos los eventos que no han visto desde la ultima vez que procesamos la newsfeed para ellos
    un = u.users_newsfeeds.find(:first, :order => 'users_newsfeeds.created_on DESC', :include => :users_action)
    starting_on = un.nil? ? u.created_on : un.users_action.created_on
    
    buckets = {}
    
    # metemos todos los eventos en cestas
    UsersAction.find(:all, :conditions => ["created_on > ? AND user_id IN (#{u.friends_ids_sql})", starting_on]).each do |ua|
      buckets[ua.type_id] ||= {}
      buckets[ua.type_id][ua.user_id] ||= []
      buckets[ua.type_id][ua.user_id] << ua
      next if buckets[ua.type_id][ua.user_id].size > 5 # para evitar storm por si alguien sube 100 imgs 
      u.users_newsfeeds.create(:created_on => ua.created_on, :summary => ua.data, :users_action_id => ua.id)
    end
   
   return 
    # TODO temp a ver como funciona asi
    
    # ahora vamos recorriendo las cestas de la siguiente forma: vamos a intentar que haya el maximo de variedad de acciones y de usuarios
    counter_actions_types = {}
    counter_by_user = {}
    bucket_is_empty = false
    
    while !bucket_is_empty && added_items < MAX_NEW_ITEMS_PER_HOUR
      
      # check if bucket is empty
    end    
  end
end

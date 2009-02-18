require 'app/controllers/application.rb'

module Cache
  module Common
    def expire_fragment(fragment)
      CacheObserver.expire_fragment(fragment)
    end  
  end
  
  module Personalization
    extend Cache::Common
    def self.expire_quicklinks(u)
      CacheObserver.expire_fragment "/_users/#{u.id % 1000}/#{u.id}/layouts/quicklinks2"
    end
  end
  
  module Competition
    extend Cache::Common
    def self.expire_competitions_lists(u)
      CacheObserver.expire_fragment "/_users/#{u.id % 1000}/#{u.id}/layouts/competitions"
    end
  end
  
  module Friendship
    extend Cache::Common
    def self.common(o)
      return unless o.receiver_user_id 
      [o.sender, o.receiver].each do |u|
        expire_fragment("/common/miembros/#{u.id % 1000}/#{u.id}/friends_#{Time.now.to_i/(86400*30)}")
        CacheObserver.expire_fragment "/facciones/#{Time.now.strftime('%Y%m%d')}/stats/#{u.faction_id}" if u.faction_id
        CacheObserver.expire_fragment "/facciones/index_*" if u.faction_id # TODO algo heavy
      end
    end
  end
  
  module Comments
    extend Cache::Common
    def self.after_create(comment_id)
      object = Comment.find(comment_id, :include => [:content])
      
      expire_fragment('/gm/site/last_commented_objects')
      expire_fragment('/gm/site/last_commented_objects_ids')
      
      object.content.real_content.get_related_portals.each do |p|
        expire_fragment("/#{p.code}/miembros/#{object.user_id % 1000}/#{object.user_id}/last_comments")
        if object.content.real_content.class.name == 'Topic'
          expire_fragment("/#{p.code}/foros/index/index") 
          expire_fragment("/bazar/home/categories/#{object.content.real_content.topics_category.root.code}")
        end
        expire_fragment("/#{p.code}/site/last_commented_objects")
        expire_fragment("/#{p.code}/site/last_commented_objects_ids")
      end
      
      # TODO hack, los observers no funcionan bien así que lo ponemos aquí
      content = object.content
      ctype = Object.const_get(content.content_type.name)
      obj = ctype.find(content.external_id)
      content.save
      obj.save
      
      User.increment_counter('comments_count', object.user_id)
      Content.increment_counter('comments_count', object.content_id)
      object.content.real_content.class.increment_counter('cache_comments_count', object.content.real_content.id)
      # TODO hacky
      if ctype.name == 'Topic'
       (object.content.real_content.main_category.get_ancestors + [object.content.real_content.main_category]).each do |anc|
          anc.class.increment_counter("comments_count", anc.id)
        end
      end
    end
    
    def self.after_destroy(content_id, comment_user_id)
      object = Content.find(content_id)
      object.real_content.get_related_portals.each do |p|
        expire_fragment("/#{p.code}/miembros/#{comment_user_id % 1000}/#{comment_user_id}/last_comments")
      end
    end
  end
end
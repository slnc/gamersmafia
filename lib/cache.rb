# -*- encoding : utf-8 -*-
module Cache
  FRAG_HOME_INDEX_QUESTIONS = '/home/index/preguntas'

  def self.clear_file_caches
    #`find #{FRAGMENT_CACHE_PATH}/home -name daily_\\\* -type f -mmin +1440 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH} -maxdepth 3 -mindepth 1 -name \\\*online_state\\\* -type f -mmin +60 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/*/*/*/most_popular* -type f -mmin +1450 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/common/foros/_most_active_users/ -type f -mmin +1450 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/*/home/index -name apuestas* -type f -mmin +120 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/common/miembros/_top_bloggers/ -type f -mmin +1450 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/common/miembros/index/ -type f -mmin +1450 -exec rm {} \\\;`
    `find #{FRAGMENT_CACHE_PATH}/common/miembros/_rightside/birthdays_20* -type f -mmin +1450 -exec rm {} \\\;`
    `find /tmp -maxdepth 1 -name RackMultipart\\\* -mmin +60 -exec rm {} \\\;`
    `find /tmp -maxdepth 1 -name CGI\\\* -mmin +60 -exec rm {} \\\;`
  end

  def self.hourly_clear_file_caches
    GmSys.command("find #{FRAGMENT_CACHE_PATH}/site/_online_state -type f -mmin +2 -exec rm {} \\\\\;")
    `find /tmp -maxdepth 1 -mmin +1440  -type d -name "0.*" -exec rm -r {} \\\;`
    `find /tmp -maxdepth 1 -mmin +60  -type f -name "RackMultipart*" -exec rm -r {} \\\;`
  end

  def self.after_daily_key
    6.hours.ago.strftime("%Y%m%d")
  end

  def self.user_base(uid)
    "/_users/#{uid % 1000}/#{uid}"
  end

  def self.user_base_with_login(uid, login)
    "/_users/#{uid % 1000}/#{uid}/#{login}"
  end

  module Common
    def expire_fragment(fragment)
      CacheObserver.expire_fragment(fragment)
    end
  end

  module Personalization
    extend Cache::Common
  end

  module Competition
    extend Cache::Common
    def self.expire_competitions_lists(u)
      CacheObserver.expire_fragment "/_users/#{u.id % 1000}/#{u.id}/layouts/competitions"
    end
  end

  module Faction
    extend Cache::Common
    def self.common(o)
      expire_fragment("/common/facciones/#{o.id}/staff")
      expire_fragment('/home/index/factions')
      expire_fragment('/common/facciones/list*')
      expire_fragment("/common/facciones/index/newest_#{Time.now.strftime('%Y%m%d')}")
      expire_fragment("/common/shared/_cash_transfer_factions")
      expire_fragment("/common/gnav/factions_list")
      expire_fragment "/common/facciones/#{Time.now.strftime('%Y%m%d')}/stats/2_#{o.id}"
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

      object.content.get_related_portals.each do |p|
        expire_fragment("/#{p.code}/miembros/#{object.user_id % 1000}/#{object.user_id}/last_comments")
        if object.content.class.name == 'Topic'
          expire_fragment("/#{p.code}/foros/index/index")
          expire_fragment("/bazar/home/categories/#{object.content.main_category.root.code}") if object.content.main_category
        end
        expire_fragment("/#{p.code}/site/last_commented_objects")
        expire_fragment("/#{p.code}/site/last_commented_objects_ids")
      end

      # TODO hack, los observers no funcionan bien así que lo ponemos aquí
      content = object.content
      ctype = Object.const_get(content.content_type.name)
      content.save

      User.increment_counter('comments_count', object.user_id)
      Content.increment_counter('comments_count', object.content_id)
      object.content.class.increment_counter('cache_comments_count', object.content.id)
      # TODO hacky
      if ctype.name == 'Topic'
       (object.content.main_category.get_ancestors + [object.content.main_category]).each do |anc|
          anc.class.increment_counter("comments_count", anc.id)
        end
      end
    end

    def self.after_destroy(content_id, comment_user_id)
      object = Content.find(content_id)
      object.get_related_portals.each do |p|
        expire_fragment("/#{p.code}/miembros/#{comment_user_id % 1000}/#{comment_user_id}/last_comments")
      end
    end
  end

  module Skins
    extend Cache::Common
    def self.common(object)
      expire_fragment "/common/layout/skins"
    end
  end

  module Contents
    extend Cache::Common
    def self.after_save(object)

    end

    def self.common_question(object)
      codes = object.get_related_portals.collect do |portal| portal.code end
      for p in object.get_related_portals
        expire_fragment("/#{p.code}#{FRAG_HOME_INDEX_QUESTIONS}")
        expire_fragment("/#{p.code}/respuestas/show/latest_by_author_#{object.user_id}")
        expire_fragment("/#{p.code}/respuestas/top_sabios/")
      end

      if object
        object.terms.find(:all).each do |t|
          expire_fragment("/common/respuestas/top_sabios/#{t.root_id}")
        end
      end
      # end
    end
  end

  module Terms
    extend Cache::Common
    def self.before_destroy(object)
      case object.taxonomy
        when 'ImagesCategory'
        object.get_related_portals.each { |p| expire_fragment("/#{p.respond_to?(:code) ? p.code : p.slug}/imagenes/index/galleries") }

        when 'TopicsCategory'
        object.get_related_portals.each { |p| expire_fragment("/#{p.respond_to?(:code) ? p.code : p.slug}/foros/index/index") } # tenemos que borrarla entera porque se guardan totales
        expire_fragment("/common/foros/subforos/#{object.parent_id}")
        expire_fragment '/common/home/foros/topics_list'
        p = object
        while p
          expire_fragment("/common/foros/_forums_list/#{p.id}")
          expire_fragment("/common/home/foros/topics_#{p.id}")
          p = p.parent
        end

        when 'DownloadsCategory'
        Cache::Terms.after_save(object)

        when 'TutorialsCategory'
        object.get_related_portals.each { |p| expire_fragment("/#{p.code}/tutoriales/index/folders") }
        p = object
        while p
          expire_fragment("/common/tutoriales/index/folders_#{p.id}")
          expire_fragment("/common/tutoriales/index/tutorials_#{p.id}/page_*")
          p = p.parent
        end

        prev_cat = object
        expire_fragment("/tutoriales/most_downloaded_#{prev_cat.root_id}")

        while prev_cat do
          expire_fragment("/common/tutoriales/_latest_by_cat/#{prev_cat.id}")
          expire_fragment("/common/tutoriales/_most_productive_author_by_cat/#{prev_cat.id}")
          expire_fragment("/common/tutoriales/index/folders_#{prev_cat.id}")
          expire_fragment("/common/tutoriales/index/tutorials_#{prev_cat.id}/page_*")
          prev_cat = prev_cat.parent
        end
      end
    end

    def self.after_save(object)
      case object.taxonomy
        when 'ImagesCategory' then
        object.get_related_portals.each do |p|
          expire_fragment("/#{p.code}/imagenes/index/galleries")
        end
        expire_fragment("/common/imagenes/toplevel/#{object.root_id}/page_*")
        if object.parent_id_changed?
          # no buscamos el root pq con la config de la sección actualmente no
          # hay más de 2 niveles en la jerarquía
          expire_fragment("/common/imagenes/toplevel/#{object.parent_id_was}/page_*")
        end

        when 'TopicsCategory' then
        object.get_related_portals.each { |p|
          if p.respond_to?(:code)
            expire_fragment("/#{p.code}/foros/index/index")
          else
            expire_fragment("/#{p.slug}/foros/index/index")
          end
        }
        expire_fragment '/common/home/foros/topics_list'
        expire_fragment("/common/foros/subforos/#{object.parent_id}")
        p = object
        while p
          expire_fragment("/common/foros/_forums_list/#{p.id}")
          expire_fragment("/common/home/foros/topics_#{p.id}")
          p = p.parent
        end

        when 'DownloadsCategory' then
        expire_fragment("/common/descargas/index/most_downloaded_#{object.root_id}")
        expire_fragment("/common/descargas/index/essential_#{object.root_id}")
        expire_fragment("/common/descargas/index/essential2_#{object.root_id}")
        expire_fragment("/common/descargas/index/essential3_#{object.root_id}")

        object.get_related_portals.each { |p| expire_fragment("/#{p.code}/descargas/index/folders") }
        p = object

        while p
          expire_fragment("/common/descargas/index/most_productive_author_by_cat_#{p.id}")
          expire_fragment("/common/descargas/index/folders_#{p.id}")
          expire_fragment("/common/descargas/index/downloads_#{p.id}/page_*")
          p = p.parent
        end

        when 'TutorialsCategory' then
        object.get_related_portals.each { |p|
          expire_fragment("/#{p.code}/tutoriales/index/folders")
        }
        p = object
        while p
          expire_fragment("/common/tutoriales/index/folders_#{p.id}")
          p = p.parent
        end
      end
    end
  end
end

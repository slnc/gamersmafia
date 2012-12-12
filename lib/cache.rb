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

  module Comments
    extend Cache::Common
    def self.after_create(comment_id)
      object = Comment.find(comment_id, :include => [:content])

      # TODO hack, los observers no funcionan bien así que lo ponemos aquí
      content = object.content
      ctype = Object.const_get(content.type)
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
  end
end

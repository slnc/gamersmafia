# -*- encoding : utf-8 -*-
class CacheObserver < ActiveRecord::Observer
  observe Clan,
          Content,
          GmtvChannel

  def after_create(object)
    case object.class.name
    when 'GmtvChannel'
      GlobalVars.update_var("gmtv_channels_updated_on", "now()")

    when 'Comment'
      Cache::Comments.delay.after_create(object.id)
    end
  end

  def after_destroy(object)
    case object.class.name
    when 'GmtvChannel'
      GlobalVars.update_var("gmtv_channels_updated_on", "now()")
    end
  end

  def after_save(object)
    return if !object.record_timestamps

    case object.class.name
      when 'Clan'
      GlobalVars.update_clans_updated_on

      when 'Content'
      if ((object.state_changed? && object.state == Cms::DELETED) ||
          object.comments_count_changed?)
        object.terms.each do |t|
          t.delay.recalculate_counters
        end
      end

      when 'GmtvChannel'
      GlobalVars.update_var("gmtv_channels_updated_on", "now()")
    end
  end

  def self.expire_fragment(file)
    # como no podemos traernos un controller aquí nos hacemos una minifunción superhacked
    # TODO cambiar esto eeek usar url_for
    file = file.gsub('../', '') if file.class.name == 'String'

    fpath = "#{FRAGMENT_CACHE_PATH}/#{file}.cache"
    fmask = "#{FRAGMENT_CACHE_PATH}/#{file}"

    if File.file?(fpath) then
      begin; File.delete(fpath); rescue; end
    elsif File.directory?(File.dirname(fpath)) then
      for i in Dir.glob(fmask)
        if File.file?(i) then
          begin; File.delete(i); rescue; end
        end
      end
    end
  end

  def expire_fragment(file)
    self.class.expire_fragment(file)
  end
end

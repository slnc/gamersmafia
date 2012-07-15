# -*- encoding : utf-8 -*-
class ActionController::Caching::Fragments::UnthreadedFileStore
  def write(name, value, options = nil) #:nodoc:
    ensure_cache_path(File.dirname(real_file_path(name)))
    f = File.open(real_file_path(name), "wb+")
    f.write(value)
    f.close
  rescue => e
    raise "Couldn't create cache directory: #{name} (#{e.message})"
  end
end

module ActionController::Caching::Fragments
  # Quitamos views/ de las keys
  def fragment_cache_key(key)
    ActiveSupport::Cache.expand_cache_key(
        key.is_a?(Hash) ? url_for(key).split("://").last : key, '')
  end
end

class String
  def slnc_tokenize
    Achmed.clean_comment(self).split(' ')
  end
end

Infinity = 1.0/0

module ActionController::Caching::Fragments
  def fragment_cache_key(key)
    # quitar views/ de las keys
    ActiveSupport::Cache.expand_cache_key(key.is_a?(Hash) ? url_for(key).split("://").last : key, '')
  end
end

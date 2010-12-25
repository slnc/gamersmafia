%w(
    acts_as_categorizable
    acts_as_content
    acts_as_content_browser
    overload_remote_ip
    all
    cms
    bank
    gmstats
    skins
    bandit
    ads
    stats
  ).each do |f|
  require "#{RAILS_ROOT}/lib/#{f}.rb"
end

Cms.uncompress_ckeditor_if_necessary
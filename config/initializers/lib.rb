%w(
   ruby_mixings
   acts_as_categorizable
   acts_as_content
   acts_as_content_browser
   acts_as_tree
   all
   cms
   bank
   gmstats
   skins
   ads
   stats
   acts_as_rootable
  ).each do |f|
  require "#{Rails.root}/lib/#{f}.rb"
end

Cms.uncompress_ckeditor_if_necessary

# -*- encoding : utf-8 -*-
namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    Skin.update_default_skin_zip
    Rake::Task["gm:update_default_skin_styles"].invoke
    Cms.uncompress_ckeditor_if_necessary
    CacheObserver.expire_fragment("/common/gmversion")
    n = News.create(
        :title => "Gamersmafia actualizada a la versión #{AppR.ondisk_git_version}",
        :description => open("#{Rails.root}/public/storage/gitlog").read,
        :user_id => 1,
        :state => Cms::DRAFT)
    Term.single_toplevel(:slug => 'gmversion').link(n.unique_content)
  end
end

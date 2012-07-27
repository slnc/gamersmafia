# -*- encoding : utf-8 -*-
namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    Skin.update_default_skin_zip
    Rake::Task["gm:update_default_skin_styles"].invoke
    Cms.uncompress_ckeditor_if_necessary
  end
end

namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    include ApplicationHelper
    system("cd #{RAILS_ROOT}/public/skins/default && zip -q -r ../default.zip . && cd #{RAILS_ROOT}")
    Rake::Task["gm:update_default_skin_styles"].invoke
    mralariko_id = User.find_by_login!('MrAlariko').id
    Chatline.create({:line => "slnc ha actualizado el motor de la web a la versión #{AppR.ondisk_git_version}", :user_id => mralariko_id})
    Cms.uncompress_ckeditor_if_necessary
    n = News.create(:title => "Gamersmafia actualizada a la versión #{AppR.ondisk_git_version}",
                :description => Comments::formatize(open("#{RAILS_ROOT}/public/storage/gitlog").read),
                :user_id => 1, 
                :state => Cms::DRAFT)
    Term.single_toplevel(:slug => 'gmversion').link(n.unique_content)                
  end
end

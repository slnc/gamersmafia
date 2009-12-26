namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    include ApplicationHelper
    system("cd #{RAILS_ROOT}/public/skins/default && zip -q -r ../default.zip . && cd #{RAILS_ROOT}")
    Rake::Task["gm:update_default_skin_styles"].invoke
    mralariko_id = User.find_by_login!('MrAlariko').id
    Chatline.create({:line => "slnc ha actualizado el motor de la web a la versión #{AppR.ondisk_git_version}", :user_id => mralariko_id})
    #system("unzip -o -q \"#{RAILS_ROOT}/public/FCKeditor_2.6.3.zip\" -d \"#{RAILS_ROOT}/public\"") if !File.exists?("#{RAILS_ROOT}/public/fckeditor")
    if !File.exists?("#{RAILS_ROOT}/public/ckeditor")
    system("tar xfz \"#{RAILS_ROOT}/public/ckeditor_3.0.1.tar.gz\" -C public") 
    system("cat \"#{RAILS_ROOT}/public/ckeditor/lang/es.js\" >> \"#{RAILS_ROOT}/public/ckeditor/ckeditor.js\"")
    system("cat \"#{RAILS_ROOT}/public/ckeditor_custom.js\" >> \"#{RAILS_ROOT}/public/ckeditor/ckeditor.js\"")
    end
    n = News.create(:title => "Gamersmafia actualizada a la versión #{AppR.ondisk_git_version}",
                :description => Comments::formatize(open("#{RAILS_ROOT}/public/storage/gitlog").read),
                :user_id => 1, 
                :state => Cms::DRAFT)
    Term.single_toplevel(:slug => 'gmversion').link(n.unique_content)                
  end
end

namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    Rake::Task["gm:update_default_skin_styles"].invoke
    Chatline.create({:line => "slnc ha actualizado el motor de la web a la versión #{AppR.ondisk_git_version}", :user_id => User.find_by_login!('MrAlariko').id})
    system("unzip -o -q \"#{RAILS_ROOT}/public/FCKeditor_2.6.3.zip\" -d \"#{RAILS_ROOT}/public\"") if !File.exists?("#{RAILS_ROOT}/public/fckeditor")
  end
end

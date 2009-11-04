namespace :gm do
  namespace :train do
      desc "Train MrAchmed on comment moderation"
      task :comments => :environment do
        Achmed.test
      end
  end
end

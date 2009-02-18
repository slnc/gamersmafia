[BetsCategory, ClansDownloadsCategory, ClansEventsCategory, ClansImagesCategory, ClansNewsCategory, ClansTopicsCategory, ColumnsCategory, DownloadsCategory, EventsCategory, ImagesCategory, InterviewsCategory, NewsCategory, PollsCategory, ReviewsCategory, TopicsCategory, TutorialsCategory].each do |cls|
  cls.find(:all).each do |cat|
    should_be_root_id = cat.parent_id.nil? ? cat.id : cls.find(cat.parent_id).root_id
    if cat.root_id != should_be_root_id
      puts "fixing #{cat.class.name}: #{cat.name} with #{should_be_root_id} and it had #{cat.root_id}"
      cat.root_id = should_be_root_id
      cat.save
    end
  end
end
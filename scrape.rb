require 'nokogiri'

def cached_read(url, force=false)
  filename = url.downcase.gsub(/[^a-z0-9_.-]+/, '-')
  scraped_copy = "#{Rails.root}/tmp/scraping/#{filename}"
  if force && File.exists?(scraped_copy)
    File.unlink(scraped_copy)
  end

  if !File.exists?(scraped_copy)
    puts "reading actual url: #{url}"
    url_data = open(url).read
    raise "No data could be read for #{url}" if url_data.empty?
    open(scraped_copy, "w").write(url_data)
  end
  open(scraped_copy)
end

i = 0

while i <= 72600
url = "http://www.ign.com/games?sortBy=title&sortOrder=asc&startIndex=#{i}"

doc = Nokogiri::HTML(cached_read(url))
# doc = Nokogiri::HTML(open("ign.html"))

concerts = doc.css('.gameList.allGames .gameList-gameShort')

concerts.each do |concert|
  # name of the show
  game_title = concert.at_css('.game-title a').text.strip
  game_platform = concert.at_css('.game-title .game-platform').text.strip
  game_publisher = concert.at_css('.publisher').text.strip
  release_date = concert.at_css('.releaseDate').text.strip

  platform = GamingPlatform.find_by_name(game_platform)
  platform = GamingPlatform.create(:name => game_platform) if platform.nil?
  if platform.new_record?
    puts "error creating platform: #{platform.errors.full_messages_html}"
  end

  if Game.find(
      :first,
      :conditions => ["name = ? AND gaming_platform_id = ?",
                      game_title, platform.id])
    puts "game #{game_title} exists, skipping.."
    next
  end

  publisher = Term.with_taxonomy("GamePublisher").find_by_name(game_publisher)
  publisher = Term.create({
    :taxonomy => "GamePublisher",
    :name => game_publisher,
  })

  if publisher.nil?
    Rails.logger.warn(
        "Unable to create publisher (#{game_publisher}): #{publisher.errors.full_messages_html}, skipping game...")
  end

  game = Game.create({
    :name => game_title,
    :gaming_platform_id => platform.id,
    :release_date => release_date,
    :publisher_id => publisher,
    :user_id => Ias.jabba,
  })
  if game.new_record?
    puts "#{game_platform}\t#{release_date}\t#{game_publisher}\t#{game_title}"
    puts "Error creating game: #{game.errors.full_messages_html}"
  end
end
  i += 50
  sleep 2
end

class CreateTermForAllGamesAndGamingPlatforms < ActiveRecord::Migration
  def up
    puts "Creating terms for games"
    created_count = 0
    Game.find_each do |g|
      next if Term.with_taxonomy("Game").find_by_name(g.name)
      Term.create({
        :name => g.name,
        :slug => g.slug,
        :taxonomy => "Game",
      })
      created_count += 1
    end
    puts "created #{created_count} games terms\n"

    puts "Creating terms for gaming platforms"
    created_count = 0
    GamingPlatform.find_each do |g|
      next if Term.with_taxonomy("GamingPlatform").find_by_name(g.name)
      Term.create({
        :name => g.name,
        :slug => g.slug,
        :taxonomy => "GamingPlatform",
      })
      created_count += 1
    end
    puts "created #{created_count} games terms\n"
  end

  def down
  end
end

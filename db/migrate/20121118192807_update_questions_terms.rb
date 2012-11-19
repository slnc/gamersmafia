class UpdateQuestionsTerms < ActiveRecord::Migration
  def up
    Question.find_each do |q|
      content = q.unique_content
      next if content.id < 271892

      if content.game_id
        t = Term.with_taxonomy("Game").find_by_slug!(content.game.slug).link(content)
      elsif content.gaming_platform_id
        t = Term.with_taxonomy("GamingPlatform").find_by_name!(content.gaming_platform.name).link(content)
      elsif content.bazar_district_id
        puts "bazar district: #{content.bazar_district_id} #{content}"
        t = Term.with_taxonomy("BazarDistrict").find_by_slug!(content.bazar_district.slug).link(content)
      else
        t = Term.with_taxonomy("Homepage").find_by_slug!("gm").link(content)
      end
      Kernel.sleep 1
    end
  end

  def down
  end
end

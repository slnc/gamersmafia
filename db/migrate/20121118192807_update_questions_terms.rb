class UpdateQuestionsTerms < ActiveRecord::Migration
  def up
    Question.find_each do |q|
      content = q.unique_content
      if content.game_id
        t = Term.with_taxonomy("Game").find(content.game_id).link(content)
      elsif content.gaming_platform_id
        t = Term.with_taxonomy("GamingPlatform").find(content.gaming_platform_id).link(content)
      elsif content.bazar_district_id
        t = Term.with_taxonomy("BazarDistrict").find(content.bazar_district_id).link(content)
      else
        raise "I don't know how to link question: #{q}"
      end
    end
  end

  def down
  end
end

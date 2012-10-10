class IsBotToSkill < ActiveRecord::Migration
  def up
    Ias::VALID_IAS.each do |login|
      User.find_by_login(login).users_skills.create(:role => "Bot")
    end
  end

  def down
  end
end

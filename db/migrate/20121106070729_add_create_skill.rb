class AddCreateSkill < ActiveRecord::Migration
  def up
    User.find_each(
        :conditions => ["cache_karma_points >= #{UsersSkills::KARMA_SKILLS['CreateTag']}"]) do |u|
      u.users_skills.create(:role => "CreateTag")
    end
  end

  def down
  end
end

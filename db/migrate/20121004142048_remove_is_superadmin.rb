class RemoveIsSuperadmin < ActiveRecord::Migration
  def up
    execute "alter table users drop column is_superadmin;"
    User.find(1).users_skills.create(:role => "Webmaster")
  end

  def down
  end
end
